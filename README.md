# Student Hub (UEMF) v2

A Flutter app that puts announcements, events, clubs and campus services in one
place, now with **role-based staff tools**, an **access-request workflow**,
**emergency banners**, **faculty filters**, an **audit log** and **QR check-in**.

## Roles and what each can do

| Role (`role` in the user document) | Scope (`assignedEntity`) | Can |
| --- | --- | --- |
| `student` (default) | none | Browse news, see facility status, follow clubs, RSVP, check in by QR, pick a faculty filter, apply for a staff role |
| `facility_manager` | a facility id, e.g. `library`, `gym` | Set **only that area** to Open / Closed / Maintenance, edit its hours and message, post an **urgent banner** for it, create sessions with QR check-in |
| `professor` | none | Post **high-priority academic announcements** (optionally for one faculty), create faculty-wide events |
| `club_leader` | a club id, e.g. `devhub` | Edit **only their club's** page, post club updates and announcements, create club events with QR check-in |
| `super_admin` | none | Approve/reject requests and assign scope, change anyone's role, create campus areas, post campus-wide banners, read the audit log, delete any content |

Staff controls appear automatically: the app listens to the user's document, so
the moment an admin approves a request the new buttons unlock (no restart).

## The "Demande" workflow

1. Student: **Profile → Apply for Staff / Organizer Role**, picks the role
   (Facility staff / Professor / Club leader), the area or club, and writes a
   justification.
2. Super Admin: **Admin dashboard → Requests** shows each pending request with
   name, `@ueuromed.org` email and justification.
3. **Approve** opens a sheet to confirm the role and assign the scope
   (for example "Library" for a library worker). **Reject** takes a reason.
4. The app writes `role` + `assignedEntity` to the user's document. The
   applicant sees the decision in "My requests" and their tools unlock.

## The extra features

- **Emergency banners.** A facility manager (own area) or admin (campus-wide)
  posts an urgent red banner; it is pinned at the top of every student's Home
  until someone taps **Resolve**.
- **Faculty / major filter.** Students pick a faculty in Profile. News and
  events targeted at other faculties are hidden (general items always show). A
  "Show all / Only mine" switch sits above the News and Events lists.
- **Audit log.** Every staff action writes an entry (who, role, what, when),
  for example "Ahmed set Library to Maintenance". Admin dashboard → Audit log.
- **QR check-in.** An organiser opens the event → **QR check-in** → a live QR
  code plus an attendance list. Students tap **Scan to check in** on the event
  page. "New code" rotates the secret; "Stop" closes the session. A student can
  check in once per event.

## 1. Run it (Demo mode, no backend)

Everything works on one phone. Accounts, content and the approval workflow are
stored locally, so you can test every role by signing out and in as different
accounts.

```bash
flutter create . --platforms=android --org ma.ueuromed --project-name student_hub
flutter pub get
flutter run
```

Demo walkthrough:
1. Sign up as `admin@ueuromed.org` (auto Super Admin in Demo mode). Verify with
   the on-screen code. Open Profile → Admin dashboard.
2. Sign out, sign up as `ahmed@ueuromed.org`, Profile → **Apply for Staff /
   Organizer Role** → Facility staff → Library.
3. Sign out, sign in as admin → Requests → **Approve** → assign Library.
4. Sign in as Ahmed: the Library card now has a controls icon, and Home shows
   a **Staff tools** card.

In Demo mode the verification "email" is a 6-digit code shown on screen. No
real email is sent.

## 2. Real accounts, real emails, shared data (Firebase)

1. Create a project at https://console.firebase.google.com
2. **Authentication → Email/Password → Enable.**
3. **Firestore Database → Create database** (production mode).
4. In this folder:
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure          # overwrites lib/firebase_options.dart
   firebase deploy --only firestore:rules   # uploads firestore.rules
   ```
5. Android: set `minSdk` to **23** or higher in `android/app/build.gradle(.kts)`.
   Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   ```
6. Run: `flutter run --dart-define=USE_FIREBASE=true`

### Create the first Super Admin (one time)

A client app must never be able to promote itself, so the first admin is set
by hand:

1. Run the app with Firebase, sign up with your UEMF email, verify it.
2. Firebase console → Firestore → collection `users` → your document →
   change `role` from `student` to `super_admin`.
3. Reopen the app. The Admin dashboard is now available.
4. Admin dashboard → **Areas → Load sample content** fills the database with
   the sample announcements, events, clubs and campus areas.

## Security: what is enforced where

The app hides buttons by role, but **only `firestore.rules` actually stops
someone calling Firestore directly.** The rules enforce the same matrix as
`lib/services/permissions.dart`:

- Only **verified** `@ueuromed.org` accounts can read anything.
- Users can create only their own profile, always as `student`, and can edit
  only their faculty and name. Only a super admin can change a role.
- A facility manager can change only `status`, `note` and hours of **their**
  area. A club leader can change only **their** club's text fields.
- Check-in: the secret lives in `eventSecrets` (organiser/admin only). A
  student's check-in document must carry the live token, use the id
  `<eventId>_<uid>` (one per student), and is rejected if the session is closed.
- The audit log is append-only and readable by admins only.

Known limits you should mention in a report:
- The rules have not been run in the Firebase emulator here. Test them with
  `firebase emulators:start` before real use. Listing check-ins for one event
  may need the organiser to be an admin or a rule tweak if Firestore reports a
  "query not provably allowed" error.
- Audit entries are written by the client, so they are trustworthy for honest
  staff accountability, not tamper-proof against a malicious admin. For that,
  write logs from a Cloud Function.
- Faculty filtering hides content in the app; it is not a privacy boundary (all
  verified students can technically read all announcements).
- Push notifications are not included (they need Firebase Cloud Messaging and a
  backend trigger). Faculty targeting is ready for it: each post has a
  `department` field.

## 3. Build the APK

```bash
flutter build apk --release --dart-define=USE_FIREBASE=true
# build/app/outputs/flutter-apk/app-release.apk
```

## Notes

- **Sample content.** News, events, clubs, hours and contact emails in
  `lib/data/seed_data.dart` are placeholders. Replace with real data.
- **Not compiled here.** This code was written without a Flutter toolchain, so
  it has been statically checked (brackets, imports, packages, cross-file
  member usage) but never compiled or run. Run `flutter analyze` and
  `flutter test` first and fix any small errors.
- **Camera.** QR scanning needs a real device (emulators have no camera). The
  scan screen also has a paste-the-code fallback.

## Project layout

```
firestore.rules               server-side security rules
lib/
  main.dart                   entry, picks Demo/Firebase stores
  app_config.dart             domains, faculties, demo admin
  models/models.dart          Role, UserProfile, RoleRequest, Facility, CampusAlert, LogEntry...
  services/
    permissions.dart          the role matrix (single source of truth in the UI)
    data_store.dart           DataStore interface: LocalStore (demo) + FirestoreStore
    auth_service.dart         Firebase + Demo auth
    email_rules.dart          UEMF-only validation
  state/app_state.dart        live streams, role workflow, alerts, audit log, check-in
  widgets/                    shared UI, alert banner, staff tools, form widgets
  screens/                    home, news, events, clubs, campus, profile,
                              request_screen, admin_screen, checkin_screen,
                              scan_screen, sheets (all staff forms)
test/                         email rules, permissions, facility status, documents
```
