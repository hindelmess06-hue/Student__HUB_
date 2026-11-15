# Student Hub (UEMF)

A Flutter mobile app that brings together announcements, events, clubs and practical information for the campus of Euromed University of Fez (UEMF).

> **Project by:** Hind El Messaouri, Marwa Reffouh, Firdawss El Hayouni, Hamza Smlali, Mohammed Wassim Boukhari
> **Program / Level:** Android Development
> **Supervisor:** Clement Regis Tuyishime
> **Academic year:** 2026-2027
> **Source code:** https://github.com/hindelmess06-hue/StudentHub

---

## 1. Overview

Students currently receive campus information through many scattered channels. Student Hub offers a single entry point reserved for university members: only `@ueuromed.org` addresses are accepted, and access is granted only after the e-mail address has been verified.

The app distinguishes several **roles** (student, club leader, professor, facility manager, Super Admin). The Super Admin oversees the whole app (see section 3).

## 2. Features

| Module | Description |
| --- | --- |
| **Sign-up / Sign-in** | `@ueuromed.org` domain (and subdomains) only. Live validation, typo correction suggestions, password strength indicator, forgot password. |
| **E-mail verification** | No access to the app until the address is verified. Automatic check every 4 seconds, resend limited to once every 30 seconds. |
| **Home** | Pinned announcement, statistics, latest news, upcoming events, clubs to discover, global search. |
| **News** | Categories, search, unread indicator, bookmarks, detail page, department filter (urgent announcements always get through). Publishers can post. |
| **Events** | 14-day date strip, category filter, "I'm going" agenda, detail page. |
| **Clubs** | Category filter, follow / unfollow, club page with updates timeline and contact, membership application with a message. |
| **Campus** | Services with live Open / Closed status, opening hours, locations, useful contacts. A manager can override the status and show an emergency banner. |
| **Profile** | "Verified" badge, counters, department, accent colour choice, role request, sign out. Administrators also get a dashboard and an audit log. |

## 3. Roles and permissions

### Roles

| Role | Description |
| --- | --- |
| **Student** | Default role: reads news, follows clubs, RSVPs to events, checks services. |
| **Club leader** | Can publish announcements. |
| **Professor** | Can publish announcements. |
| **Facility manager** | Can change the status of the service assigned to them (for example the library). |
| **Super Admin** | Full access, see below. |

A student can request a role from their profile by giving the role wanted, the entity concerned and a justification. The Super Admin processes these requests.

### The Super Admin

The Super Admin can manage the whole app:

| Capability | Status |
| --- | --- |
| Publish announcements, including urgent ones, targeted by department | Available |
| Receive role requests (name, e-mail, entity, justification) and **approve or reject** them | Available |
| Grant permissions to an account: approving a request assigns the role and entity to the user | Available |
| Change the Open / Closed status of **any** campus service and show an **emergency banner** | Available |
| View the **audit log** (who did what, and when) | Available |
| Add, edit or delete events | Planned |
| Edit club pages (description, president, updates) | Planned |
| Edit the opening and closing hours of services | Planned |
| Accept or refuse a student's entry into a club, based on their application message | Planned |
| Edit any content of the app in an emergency | Planned |

> **How to become Super Admin:** the addresses listed in `AppConfig.publisherEmails` (`lib/app_config.dart`) are Super Admins, for example `admin@ueuromed.org`. This is a prototype shortcut (see section 8).

### Request handling flow

1. The student sends a role request from their profile.
2. The Super Admin opens the dashboard (profile) and sees the list of pending requests.
3. They read the name, e-mail, entity and justification, then choose **Approve** or **Reject**.
4. The action is recorded in the audit log.

## 4. Technologies

- **Flutter / Dart**: mobile app (Android)
- **Provider**: state management (a single `AppState`)
- **Firebase Authentication**: accounts and e-mail verification
- **shared_preferences**: local storage (bookmarks, follows, posts, requests, log)
- **google_fonts**: Space Grotesk and Inter fonts
- Two run modes: **Demo** (no server) and **Firebase** (real)

## 5. Requirements

- Flutter SDK (stable): https://docs.flutter.dev/get-started/install
- Android Studio with an emulator (e.g. Pixel 7) or an Android phone with USB debugging
- For Firebase mode: a Google account and a Firebase project

> **Windows:** the project, the Flutter SDK (`C:\src\flutter`) and the package cache (`PUB_CACHE=C:\pub_cache`) must be in paths **without spaces**, and Windows **Developer Mode** must be enabled.

## 6. Installation and run

### Demo mode (no server needed)

Accounts are stored on the device and the 6-digit verification code is shown on screen. **No real e-mail is sent in this mode.**

```bash
flutter pub get
flutter run
```

Tip: signing up with `admin@ueuromed.org` gives Super Admin rights ("+" button in the News tab, dashboard in the profile, service management in the Campus tab).

### Firebase mode (real e-mail verification)

1. Create a project at https://console.firebase.google.com
2. **Authentication → Sign-in method → Email/Password → Enable**
3. Configure the project:
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure
   ```
   This command replaces `lib/firebase_options.dart` and creates `android/app/google-services.json`. That file is intentionally not in the repository (`.gitignore`): each developer must generate it.
4. Make sure `minSdk` is at least **23** in `android/app/build.gradle(.kts)`.
5. Run:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```

### Build the APK

Make sure `android/app/src/main/AndroidManifest.xml` contains the `android.permission.INTERNET` permission, then:

```bash
flutter build apk --release --dart-define=USE_FIREBASE=true
```

The file is at `build/app/outputs/flutter-apk/app-release.apk`.

### Run the tests

```bash
flutter test
```

## 7. Architecture

```
lib/
├── main.dart                 Entry point, routing based on sign-in state
├── app_config.dart           Allowed domains, Super Admins, Demo / Firebase mode
├── firebase_options.dart     Firebase configuration (generated by flutterfire)
├── theme/app_theme.dart      Colours, fonts, accent palettes
├── models/models.dart        Announcement, Event, Club, Campus service, Audit log
├── data/seed_data.dart       Sample content
├── services/
│   ├── email_rules.dart      UEMF validation and correction suggestions
│   └── auth_service.dart     Firebase and Demo implementations
├── state/app_state.dart      Session, roles, requests, follows, agenda, bookmarks,
│                             publishing, service status, audit log
├── utils/format.dart         Date and name formatting
├── widgets/                  Shared UI components
└── screens/                  Screens (auth, verification, home, news, events,
                              clubs, campus, profile, search)
test/widget_test.dart         Unit tests for the e-mail rules
```

**Principle:** the screen shown depends on a single state, `AuthStatus` (`loading`, `signedOut`, `needsVerification`, `signedIn`). When it changes, the app switches screen automatically.

## 8. Security

The domain check inside the app gives instant feedback, but **it can be bypassed** by someone talking to Firebase directly. The real guarantees are:

- **Verified e-mail required:** the app blocks unverified accounts.
- **Server-side rules:** for any stored data (Firestore, Storage), require
  `request.auth.token.email_verified == true && request.auth.token.email.matches('.*@ueuromed[.]org')`.
- **Blocking at creation:** Firebase Auth *blocking functions* (`beforeCreate`, Identity Platform) can reject any non-UEMF e-mail.
- **Super Admin and publishing rights:** `AppConfig.publisherEmails` is a prototype shortcut. In production, use Firebase *custom claims* assigned by an administrator, and check permissions on the server.
- **Passwords:** in Firebase mode they are handled by Firebase. In Demo mode they are only lightly hashed: that mode is for testing, not real use.
- **No information leak:** password reset never reveals whether an address exists.

## 9. Known limitations

- **Roles in Firebase mode:** the role read from Firebase is always "student" (loading roles from Firestore or custom claims is still to do). Only e-mails in `publisherEmails` are Super Admins.
- **Request approval:** approving a request changes the role of the signed-in user on the device. It is not yet saved on a server, so it is not shared between devices.
- **Club membership application:** the message is entered and a confirmation is shown, but the application is not yet sent or stored for a leader to process.
- **Sample content:** announcements, events, clubs, hours and contacts in `lib/data/seed_data.dart` are fictional and must be replaced with the university's real data.
- **Local data:** follows, "I'm going", bookmarks, posts, requests and the log are stored on the device. Sharing content between students requires a shared backend (Cloud Firestore is the natural next step; only `AppState` would need to change).
- **Tests:** only the e-mail rules have automated tests. The rest was tested manually.
- **Fonts:** loaded through `google_fonts` on first use; bundle them as assets for fully offline use.
- **Wide screens:** club and campus cards stretch on a very wide screen (Chrome).

## 10. Planned improvements

- Creating and editing events by the Super Admin and club leaders.
- Editing club pages and service opening hours.
- A club application queue: student message, accepted or refused by the leader or Super Admin.
- Cloud Firestore backend and custom claims for shared, secure roles.
- Push notifications (urgent announcements, event reminders, replies to requests).
- Add to calendar, interactive campus map, Arabic / French / English localisation.
- QR code check-in.
- Unit, widget and integration tests with continuous integration.

## 11. License and contact

Academic project, UEMF. Supervisor: Clement Regis Tuyishime.
