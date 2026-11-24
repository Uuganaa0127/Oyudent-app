# Oyudent

Mongolian Flutter dental learning, shopping, appointments, attendance, and clinic-membership prototype. Includes a local development API for accounts, courses, quizzes, and clinic invitations.

## Run locally

In one terminal:

```sh
python3 backend/server.py
```

In another:

```sh
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8087
```

The current browser preview is served at http://localhost:8085. The local API listens only on 127.0.0.1:8087. Set OYUDENT_PORT to change its port and API_BASE_URL to match. The default SQLite database is under the workspace work/ directory; use OYUDENT_DB to change it. Never commit this database.

## Accounts and tokens

Profile → Нэвтрэх / Бүртгүүлэх opens login and registration. Test accounts persist in SQLite. Passwords are salted and derived with PBKDF2-SHA256 (200,000 iterations); the database stores session-token hashes. Tokens expire after 24 hours. The client saves tokens through flutter_secure_storage, validates them on startup, attaches them to API requests, and deletes them at logout or after a 401 response. Passwords are not saved in the app.

Web storage uses the plugin's browser storage implementation and requires HTTPS or localhost; it does not protect against compromised same-origin JavaScript. Mobile uses platform secure storage. Android internet permission and iOS Keychain entitlements are included. Native builds remain unverified. Use a hosted HTTPS API for real devices; localhost on a phone is the phone itself.

This is a local test backend, not a production identity service. Before public deployment add HTTPS, rate limiting, verification/reset flows, production session management, proper authorization, audit logs, and CORS for the deployed site. Use test credentials only.

## Classroom

Open an enrolled online course and continue into the classroom. It fetches modules and sub-lessons from the API. The module list is beside the lesson on desktop and collapsible on phones. Video loads on demand and supports play/pause, seeking, volume, and playback speed. Related courses open their details page. Completing every lesson and passing the quiz unlocks the demo certificate and a one-time in-session reward.

Sample videos are Flutter's public butterfly.mp4 and bee.mp4 assets, as used in https://docs.flutter.dev/cookbook/plugins/play-video. They are player demonstrations, not dental lessons. Quiz questions come from the local backend, which also grades answers; passing answers are not supplied in the question response. Quiz submission requires login. Learning progress, coins, shopping orders, and course enrollments are still prototype state in memory.

## My Clinics

My Appointments → Миний эмнэлгүүд shows invitations to join clinics. Login is required. Two fictional clinic invitations are seeded per new test account. Accepting moves a clinic into Нэгдсэн эмнэлгүүд; declining leaves a visible declined invitation. Decisions persist per account on the local backend. This is distinct from patient appointment requests. No real hospital sends invitations yet, and no clinic administrator sender interface is included.

## API contract

All responses are JSON. Protected calls require `Authorization: Bearer <accessToken>`.

- POST /auth/register — `{name,email,password}` → `{accessToken,expiresAt,user}`
- POST /auth/login — `{email,password}` → same session shape
- GET /auth/me — `{user}`; POST /auth/logout — revoke token
- GET /courses/:id — `{id,modules:[{id,title,lessons:[{id,title,type,videoUrl?,description}]}],related:[{id,title}]}`
- GET /courses/:id/quiz — `{id,questions:[{id,prompt,options}]}`
- POST /courses/:id/quiz/submit — `{answers:{questionId:optionIndex}}` → `{score,total,passed,feedback}`
- GET /clinics — `{clinics:[{id,name,address,role,status}]}`
- POST /clinics/:id/respond — `{decision:"accepted"|"declined"}` → updated clinics; only pending invitations can be answered

## Existing app features

Stories, finger-swipe course/product cards, separate product/course searches, course details, enrollment status badges, enrolled/completed course views, certificates, demo purchases and coins, a top profile, weekly/monthly appointments, fictional hospital patient requests, and HR check-in/out. Catalog illustrations are AI-generated. There are no real payments, medical records, or accredited certificates.

## Verification

```sh
flutter analyze
flutter test
python3 -m unittest discover -s backend -p 'test_*.py'
flutter build web --pwa-strategy=none
```

Registration requires phone (8 digits, optional +976), Mongolian register number (2 Cyrillic letters + 8 digits), last name, first name, email, position selection, password, and matching confirmation. The API validates and stores profile fields; password confirmation is never stored. Existing accounts remain compatible after the automatic database migration.

Point shop: open from the home reward card, top point balance, or profile. Redeem demo points for dental products or an online course, filter rewards, and view redeemed items. Redemptions require confirmation, prevent duplicate claims, and disable unaffordable rewards. Points, daily check-in date, and redemption history are saved on this device; the cart lasts for the app session. The shared visual theme uses lavender surfaces, white rounded cards, blue/cyan gradient controls, and a floating navigation bar inspired by the supplied reference.

The dedicated Оноо navigation tab contains the point shop and its cart. Each reward can be added once, removed, and redeemed together after reviewing the total; checkout is disabled if points are insufficient. Daily check-in awards 25 points once per device-local calendar day, independent of hospital HR attendance. This is a device-local demo wallet, not a server-authoritative or account-synced reward system.

Daily check-in now opens a reward popup with a claim action, updated balance, and success state. The Android demo APK is signed with the development key for direct installation, not store release. Its API defaults to localhost:8087, so login, clinic invitations, and backend classroom content require rebuilding with API_BASE_URL set to a phone-reachable HTTPS server. Device-local point shop and daily rewards work independently.

# Oyudent-app
