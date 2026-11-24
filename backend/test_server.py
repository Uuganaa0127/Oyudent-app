import unittest,tempfile,threading,json,urllib.request,urllib.error,os
from pathlib import Path
import server
class TestAPI(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.temp=tempfile.TemporaryDirectory();server.DB=Path(cls.temp.name)/'test.sqlite3'
  server.init_db()
  cls.http=server.ThreadingHTTPServer(('127.0.0.1',0),server.API);cls.base='http://127.0.0.1:'+str(cls.http.server_port);threading.Thread(target=cls.http.serve_forever,daemon=True).start()
 @classmethod
 def tearDownClass(cls):cls.http.shutdown();cls.http.server_close();cls.temp.cleanup()
 def request(self,path,data=None,token=None):
  request=urllib.request.Request(self.base+path,data=None if data is None else json.dumps(data).encode(),headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
  try:
   with urllib.request.urlopen(request) as r:return r.status,json.load(r)
  except urllib.error.HTTPError as e:return e.code,json.load(e)
 def test_registration_validation(self):
  valid={'name':'Тест','lastName':'Туршилт','phone':'99000001','registerNumber':'АА00000001','position':'Шүдний эмч','email':'validation@example.test','password':'test-password-123','confirmPassword':'test-password-123'}
  for key,bad in [('phone','123'),('registerNumber','invalid'),('lastName',''),('position','admin'),('confirmPassword','different')]:
   with self.subTest(key=key):self.assertEqual(self.request('/auth/register',{**valid,key:bad})[0],400)
 def test_session_and_quiz(self):
  code,registered=self.request('/auth/register',{'name':'Test Learner','email':'learner@example.test','password':'test-password-123','confirmPassword':'test-password-123','phone':'99000000','registerNumber':'АА00000000','lastName':'Туршилт','position':'Шүдний эмч'})
  self.assertEqual(code,200);token=registered['accessToken']
  self.assertEqual(self.request('/auth/me',token=token)[1]['user']['phone'],'99000000')
  self.assertEqual(registered['user']['lastName'],'Туршилт')
  self.assertEqual(self.request('/auth/login',{'email':'learner@example.test','password':'bad-password'})[0],401)
  self.assertEqual(self.request('/auth/login',{'email':'learner@example.test','password':'test-password-123'})[0],200)
  _,course=self.request('/courses/clinical-photography');self.assertEqual(len(course['modules']),2)
  _,quiz=self.request('/courses/clinical-photography/quiz');self.assertEqual(len(quiz['questions']),2)
  self.assertNotIn('correctAnswer',quiz['questions'][0])
  self.assertEqual(self.request('/courses/x/quiz/submit',{'answers':{'q1':0,'q2':0}})[0],401)
  self.assertEqual(self.request('/courses/x/quiz/submit',{'answers':{'q1':0}},token)[0],400)
  _,result=self.request('/courses/x/quiz/submit',{'answers':{'q1':1,'q2':0}},token);self.assertFalse(result['passed'])
  _,result=self.request('/courses/x/quiz/submit',{'answers':{'q1':0,'q2':0}},token);self.assertTrue(result['passed'])
  _,clinics=self.request('/clinics',token=token);self.assertEqual(len(clinics['clinics']),2)
  self.assertEqual(self.request('/clinics/central/respond',{'decision':'accepted'})[0],401)
  _,joined=self.request('/clinics/central/respond',{'decision':'accepted'},token);self.assertEqual(joined['clinics'][0]['status'],'accepted')
  self.assertEqual(self.request('/clinics/central/respond',{'decision':'declined'},token)[0],409)
  _,declined=self.request('/clinics/city/respond',{'decision':'declined'},token);self.assertEqual(declined['clinics'][1]['status'],'declined')
  _,saved=self.request('/clinics',token=token);self.assertEqual(saved['clinics'][0]['status'],'accepted')
  self.request('/auth/logout',{},token);self.assertEqual(self.request('/auth/me',token=token)[0],401)
  with server.db() as c:
   row=c.execute('SELECT * FROM users').fetchone();self.assertNotEqual(row['password'],'test-password-123')
if __name__=='__main__':unittest.main()
