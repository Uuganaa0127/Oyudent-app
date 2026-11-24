"""Oyudent local development API. Bind only to loopback; do not deploy as-is."""
import os,json,sqlite3,secrets,hashlib,hmac,time,re
from pathlib import Path
from http.server import ThreadingHTTPServer,BaseHTTPRequestHandler
from urllib.parse import urlparse,unquote
DB=Path(os.environ.get('OYUDENT_DB',str(Path(__file__).resolve().parents[3]/'work'/'oyudent-demo.sqlite3')))
DB.parent.mkdir(parents=True,exist_ok=True)
def db():
 c=sqlite3.connect(DB);c.row_factory=sqlite3.Row;return c
def init_db():
 with db() as c:
  c.executescript('CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY,name TEXT,email TEXT UNIQUE,salt TEXT,password TEXT); CREATE TABLE IF NOT EXISTS sessions(hash TEXT PRIMARY KEY,user_id TEXT,expires INTEGER);')
  columns={row['name'] for row in c.execute('PRAGMA table_info(users)')}
  for column in ['phone','registerNumber','lastName','position']:
   if column not in columns:c.execute(f'ALTER TABLE users ADD COLUMN {column} TEXT NOT NULL DEFAULT ""')
init_db()
POSITIONS=['Шүдний эмч','Сувилагч','Шүдний техникч','Эмнэлгийн удирдлага','Оюутан','Бусад']
def public_user(u):return {key:u[key] for key in ['id','name','email','phone','registerNumber','lastName','position']}
VIDEO='https://flutter.github.io/assets-for-api-docs/assets/videos/'
QUIZ=[{'id':'q1','prompt':'Суралцах төлөвлөгөөг юунаас эхлэх вэ?','options':['Тодорхой зорилго','Санамсаргүй сонголт','Зөвхөн хугацаа']},{'id':'q2','prompt':'Багаар суралцахад юу тустай вэ?','options':['Хэлэлцүүлэг ба санал солилцоо','Мэдээллээ нуух','Асуулт асуухгүй байх']}]
CLINICS=[('central','Төв шүдний эмнэлэг','Сүхбаатар дүүрэг • Туршилтын хаяг','Шүдний эмч'),('city','Хотын дентал клиник','Баянзүрх дүүрэг • Туршилтын хаяг','Зөвлөх эмч')]
def clinic_rows(uid):
 with db() as c:
  c.execute('CREATE TABLE IF NOT EXISTS clinic_memberships(user_id TEXT,clinic_id TEXT,status TEXT,PRIMARY KEY(user_id,clinic_id))')
  for cid,name,address,role in CLINICS:c.execute('INSERT OR IGNORE INTO clinic_memberships VALUES(?,?,?)',(uid,cid,'pending'))
  return [{'id':cid,'name':name,'address':address,'role':role,'status':c.execute('SELECT status FROM clinic_memberships WHERE user_id=? AND clinic_id=?',(uid,cid)).fetchone()['status']} for cid,name,address,role in CLINICS]
def course(cid):
 return {'id':cid,'modules':[{'id':'m1','title':'1. Танилцуулга','lessons':[{'id':'intro','title':'Тавтай морил','type':'video','videoUrl':VIDEO+'butterfly.mp4','description':'Flutter-ийн нийтийн жишээ бичлэг. Шүдний эмчилгээний хичээл биш.'},{'id':'reading','title':'Суралцах төлөвлөгөө','type':'reading','description':'Нэг зорилго сонгож, хэрэгжүүлэх хамгийн жижиг алхмаа бичнэ үү.'}]},{'id':'m2','title':'2. Дадлага ба шалгалт','lessons':[{'id':'practice','title':'Дадлагын танилцуулга','type':'video','videoUrl':VIDEO+'bee.mp4','description':'Видео тоглуулагчийн хоёр дахь жишээ бичлэг.'},{'id':'quiz','title':'Мэдлэгээ шалгах','type':'quiz','description':'Серверээс авсан асуултуудад хариулна уу.'}]}],'related':[{'id':'digital-dentistry','title':'Дижитал шүдний эмчилгээ'},{'id':'practice-management','title':'Шүдний эмнэлгийн менежмент'}]}
class API(BaseHTTPRequestHandler):
 def log_message(self,*args): pass
 def send(self,status,data):
  body=json.dumps(data,ensure_ascii=False).encode();self.send_response(status)
  origin=self.headers.get('Origin','')
  if re.fullmatch(r'https?://(localhost|127\.0\.0\.1)(:\d+)?',origin):self.send_header('Access-Control-Allow-Origin',origin)
  self.send_header('Vary','Origin');self.send_header('Content-Type','application/json; charset=utf-8');self.send_header('Cache-Control','no-store');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body)
 def do_OPTIONS(self):
  self.send_response(204);origin=self.headers.get('Origin','')
  if re.fullmatch(r'https?://(localhost|127\.0\.0\.1)(:\d+)?',origin):self.send_header('Access-Control-Allow-Origin',origin)
  self.send_header('Access-Control-Allow-Methods','GET, POST, OPTIONS');self.send_header('Access-Control-Allow-Headers','Content-Type, Authorization');self.end_headers()
 def user(self):
  token=self.headers.get('Authorization','').removeprefix('Bearer ')
  with db() as c:return c.execute('SELECT users.id,name,email,phone,registerNumber,lastName,position FROM sessions JOIN users ON users.id=sessions.user_id WHERE sessions.hash=? AND expires>?',(hashlib.sha256(token.encode()).hexdigest(),int(time.time()))).fetchone()
 def do_GET(self):
  path=unquote(urlparse(self.path).path)
  if path=='/clinics':
   u=self.user()
   return self.send(200,{'clinics':clinic_rows(u['id'])}) if u else self.send(401,{'error':'Эмнэлгийн урилгаа харахын тулд нэвтэрнэ үү.'})
  if path=='/health':return self.send(200,{'ok':True,'mode':'local-demo'})
  if path=='/auth/me':
   u=self.user();return self.send(200,{'user':dict(u)}) if u else self.send(401,{'error':'Нэвтрэх хугацаа дууссан. Дахин нэвтэрнэ үү.'})
  if re.fullmatch('/courses/[^/]+/quiz',path):return self.send(200,{'id':'quiz','questions':QUIZ})
  if re.fullmatch('/courses/[^/]+',path):return self.send(200,course(path.split('/')[2]))
  self.send(404,{'error':'Олдсонгүй.'})
 def do_POST(self):
  try:
   size=int(self.headers.get('Content-Length','0'))
   if size>16384:return self.send(413,{'error':'Хүсэлт хэт том.'})
   data=json.loads(self.rfile.read(size) or b'{}')
   if not isinstance(data,dict):raise ValueError()
  except (ValueError,TypeError):return self.send(400,{'error':'Хүсэлт буруу.'})
  path=unquote(urlparse(self.path).path)
  if path in ['/auth/register','/auth/login']:
   email=str(data.get('email','')).strip().lower();password=str(data.get('password',''));name=str(data.get('name','')).strip()
   if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+',email) or not 8<=len(password)<=128:return self.send(400,{'error':'Имэйл болон 8–128 тэмдэгттэй нууц үг оруулна уу.'})
   with db() as c:
    if path.endswith('register'):
     if not 1<=len(name)<=80:return self.send(400,{'error':'Нэрээ оруулна уу.'})
     phone=str(data.get('phone','')).strip();register_number=str(data.get('registerNumber','')).strip().upper();last_name=str(data.get('lastName','')).strip();position=data.get('position')
     if not re.fullmatch(r'(\+976)?[0-9]{8}',phone):return self.send(400,{'error':'8 оронтой утасны дугаар оруулна уу.'})
     if not re.fullmatch(r'[А-ЯӨҮ]{2}[0-9]{8}',register_number):return self.send(400,{'error':'Регистрийн дугаар: 2 кирилл үсэг, 8 цифр оруулна уу.'})
     if not 1<=len(last_name)<=80:return self.send(400,{'error':'Овгоо оруулна уу.'})
     if position not in POSITIONS:return self.send(400,{'error':'Албан тушаалаа сонгоно уу.'})
     if data.get('confirmPassword')!=password:return self.send(400,{'error':'Нууц үг таарахгүй байна.'})
     salt=secrets.token_hex(16);digest=hashlib.pbkdf2_hmac('sha256',password.encode(),bytes.fromhex(salt),200000).hex()
     try:c.execute('INSERT INTO users(id,name,email,salt,password,phone,registerNumber,lastName,position) VALUES(?,?,?,?,?,?,?,?,?)',(secrets.token_hex(12),name,email,salt,digest,phone,register_number,last_name,position))
     except sqlite3.IntegrityError:return self.send(409,{'error':'Энэ имэйл бүртгэлтэй байна.'})
    u=c.execute('SELECT * FROM users WHERE email=?',(email,)).fetchone()
    valid=u and hmac.compare_digest(u['password'],hashlib.pbkdf2_hmac('sha256',password.encode(),bytes.fromhex(u['salt']),200000).hex())
    if not valid:return self.send(401,{'error':'Имэйл эсвэл нууц үг буруу.'})
    token=secrets.token_urlsafe(32);expires=int(time.time())+86400
    c.execute('INSERT INTO sessions VALUES(?,?,?)',(hashlib.sha256(token.encode()).hexdigest(),u['id'],expires))
   return self.send(200,{'accessToken':token,'expiresAt':expires,'user':public_user(u)})
  if re.fullmatch('/clinics/[^/]+/respond',path):
   u=self.user()
   if not u:return self.send(401,{'error':'Нэвтэрнэ үү.'})
   cid=path.split('/')[2];decision=data.get('decision')
   if cid not in [c[0] for c in CLINICS] or decision not in ['accepted','declined']:return self.send(400,{'error':'Хүсэлт буруу.'})
   clinic_rows(u['id'])
   with db() as c:
    changed=c.execute('UPDATE clinic_memberships SET status=? WHERE user_id=? AND clinic_id=? AND status=?',(decision,u['id'],cid,'pending')).rowcount
   if not changed:return self.send(409,{'error':'Энэ урилгад аль хэдийн хариулсан байна.'})
   return self.send(200,{'clinics':clinic_rows(u['id'])})
  if path=='/auth/logout':
   token=self.headers.get('Authorization','').removeprefix('Bearer ')
   with db() as c:c.execute('DELETE FROM sessions WHERE hash=?',(hashlib.sha256(token.encode()).hexdigest(),))
   return self.send(200,{'ok':True})
  if re.fullmatch('/courses/[^/]+/quiz/submit',path):
   if not self.user():return self.send(401,{'error':'Шалгалт өгөхийн өмнө нэвтэрнэ үү.'})
   answers=data.get('answers',{})
   if not isinstance(answers,dict) or any(type(answers.get(q['id'])) is not int or not 0<=answers[q['id']]<len(q['options']) for q in QUIZ):return self.send(400,{'error':'Бүх асуултад хариулна уу.'})
   score=sum(answers[q['id']]==0 for q in QUIZ)
   return self.send(200,{'score':score,'total':len(QUIZ),'passed':score==len(QUIZ),'feedback':'Бүх хариулт зөв.' if score==len(QUIZ) else 'Зорилго болон хамтын суралцахын тухай дахин уншаарай.'})
  return self.send(404,{'error':'Олдсонгүй.'})
if __name__=='__main__':ThreadingHTTPServer(('127.0.0.1',int(os.environ.get('OYUDENT_PORT','8087'))),API).serve_forever()
