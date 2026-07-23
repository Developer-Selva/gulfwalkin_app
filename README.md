# Gulfwalkin — Flutter Mobile App

Overseas job portal for Gulf-based employment. This document is the primary onboarding guide for any developer joining the project, including the **iOS developer** taking over `ios/` integration.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Project Structure](#3-project-structure)
4. [Getting Started](#4-getting-started)
5. [Environment & Configuration](#5-environment--configuration)
6. [Architecture](#6-architecture)
7. [API Reference](#7-api-reference)
8. [Features Implemented](#8-features-implemented)
9. [Push Notifications (FCM)](#9-push-notifications-fcm)
10. [iOS Setup Checklist](#10-ios-setup-checklist)
11. [State Management](#11-state-management)
12. [Navigation (GoRouter)](#12-navigation-gorouter)
13. [Known Gaps / TODO for iOS](#13-known-gaps--todo-for-ios)
14. [Branch & Contribution Guidelines](#14-branch--contribution-guidelines)

---

## 1. Project Overview

| Item | Detail |
|------|--------|
| App name | Gulfwalkin |
| Platform | Android (shipped) · iOS (in progress) |
| Version | 1.0.0+1 |
| Backend | Laravel 10 REST API at `https://gulfwalkin.com/api` |
| Framework | Flutter 3.44.6 (stable channel) |
| Bundle ID (Android) | `com.gulfwalkin.app` |
| Bundle ID (iOS) | `com.gulfwalkin.app` *(to be verified in Xcode)* |

The app is used by **job seekers (employees)** to browse overseas job listings, apply, receive push notifications for new jobs, and manage their profile.

---

## 2. Tech Stack

| Category | Package | Version |
|----------|---------|---------|
| State management | flutter_riverpod | ^2.5.1 |
| Code generation | riverpod_annotation + riverpod_generator | ^2.3.5 / ^2.4.0 |
| HTTP client | dio | ^5.4.3 |
| Navigation | go_router | ^13.2.0 |
| Google Sign-In | google_sign_in | ^6.2.1 |
| Firebase core | firebase_core | ^3.6.0 |
| Push notifications | firebase_messaging | ^15.1.4 |
| Local notifications | flutter_local_notifications | ^18.0.1 |
| Image picker | image_picker | ^1.1.1 |
| File picker | file_picker | ^8.0.3 |
| PDF viewer | syncfusion_flutter_pdfviewer | ^27.2.5 |
| Image cache | cached_network_image | ^3.3.1 |
| Local storage | hive_flutter | ^1.1.0 |
| Preferences | shared_preferences | ^2.3.2 |
| Sharing | share_plus | ^12.0.2 |
| URL launcher | url_launcher | ^6.3.0 |
| Web view | webview_flutter | ^4.7.0 |
| SVG | flutter_svg | ^2.0.10 |
| Shimmer loading | shimmer | ^3.0.0 |
| Progress indicator | percent_indicator | ^4.2.3 |
| Animations | lottie | ^3.1.1 |

---

## 3. Project Structure

```
lib/
├── main.dart                    # Entry point, Firebase init, FCM listeners
├── router.dart                  # GoRouter routes + auth redirect logic
│
├── core/
│   ├── api/
│   │   ├── api_client.dart      # Dio instance + base URL (https://gulfwalkin.com/api)
│   │   ├── auth_interceptor.dart# Attaches Bearer token from Hive on every request
│   │   └── error_handler.dart   # handleDioError() → human-readable error strings
│   ├── auth/
│   │   ├── auth_provider.dart   # AuthNotifier — holds token + role in state
│   │   ├── current_user_provider.dart # Fetches /auth/me, caches the Employee model
│   │   └── token_storage.dart   # Hive box wrapper for JWT token + role
│   ├── models/                  # Dart data models (fromJson / copyWith)
│   │   ├── job.dart
│   │   ├── employee.dart
│   │   ├── application.dart
│   │   ├── notification.dart
│   │   ├── job_alert.dart
│   │   ├── top_company.dart
│   │   ├── advertisement.dart
│   │   └── category.dart
│   └── services/
│       ├── fcm_service.dart     # Firebase Messaging wrapper (init, token reg, streams)
│       └── google_auth_service.dart # Google Sign-In helper
│
├── features/
│   ├── auth/                    # Login, Register, OTP, Forgot password, Splash, Onboarding
│   ├── home/                    # Home screen, recommended jobs, top companies
│   ├── jobs/                    # Browse jobs, job detail, filters, bookmarks, job alerts
│   ├── applications/            # My Applications list
│   ├── notifications/           # Notifications screen + provider
│   ├── profile/                 # Profile view/edit, photo upload, resume
│   ├── settings/                # Settings, change password, rate & feedback
│   ├── cms/                     # About Us, Terms, Privacy (fetched from backend)
│   └── employer/                # Employer-facing jobs screen (future use)
│
└── shared/
    ├── theme/
    │   ├── app_colors.dart      # All color constants
    │   └── app_theme.dart       # ThemeData
    └── widgets/                 # Reusable widgets: JobCard, LoadingSkeleton, ErrorState…
```

---

## 4. Getting Started

### Prerequisites

- Flutter **3.44.6** (stable) — `flutter --version` to verify
- Dart SDK `>=3.0.0 <4.0.0`
- For Android: Android Studio / SDK with API 36
- For iOS: macOS with Xcode 15+, CocoaPods installed (`sudo gem install cocoapods`)
- Firebase project access: `gulfwalkin-1c13f`

### Clone & Install

```bash
git clone https://github.com/Developer-Selva/gulfwalkin_app.git
cd gulfwalkin_app
flutter pub get
```

### Android — Run

```bash
flutter run
```

### iOS — Run (first time)

```bash
cd ios
pod install
cd ..
flutter run -d <your-ios-device-or-simulator>
```

---

## 5. Environment & Configuration

### Firebase

| File | Location | Purpose |
|------|----------|---------|
| `google-services.json` | `android/app/` | Android Firebase config |
| `GoogleService-Info.plist` | `ios/Runner/` | **iOS Firebase config — NOT yet added** |

`GoogleService-Info.plist` must be downloaded from the Firebase console (`gulfwalkin-1c13f`) and placed in `ios/Runner/` via Xcode (drag-and-drop into the Runner target, ensure "Copy items if needed" is checked).

### API Base URL

Defined in `lib/core/api/api_client.dart`:

```dart
const String kBaseUrl = 'https://gulfwalkin.com/api';
```

No `.env` file is needed — the base URL is hardcoded. If you need to point at a local/staging server, change `kBaseUrl` here.

### Auth Token Storage

JWT tokens are stored in a Hive box (`app_prefs`). The `AuthInterceptor` reads this on every request and attaches `Authorization: Bearer <token>` automatically. No manual token handling is needed in feature code.

---

## 6. Architecture

The app uses **Riverpod** for state management with the following pattern:

```
Screen (ConsumerWidget / ConsumerStatefulWidget)
  └── watches Provider / AsyncNotifierProvider / FutureProvider
         └── calls Dio (via dioProvider) for API data
               └── AuthInterceptor attaches Bearer token automatically
```

Key providers:

| Provider | File | What it holds |
|----------|------|---------------|
| `authProvider` | `core/auth/auth_provider.dart` | Auth state (token, role, isAuthenticated) |
| `currentUserProvider` | `core/auth/current_user_provider.dart` | Logged-in Employee model |
| `dioProvider` | `core/api/api_client.dart` | Shared Dio instance |
| `jobListProvider` | `features/jobs/job_list_provider.dart` | Browse jobs list + filter state |
| `jobFilterProvider` | `features/jobs/job_list_provider.dart` | Current filter (category, country, keyword) |
| `notificationsProvider` | `features/notifications/notifications_provider.dart` | Notification list + unread count |
| `unreadCountProvider` | `features/notifications/notifications_provider.dart` | Bell badge count (separate FutureProvider) |
| `bookmarksProvider` | `features/jobs/bookmarks_provider.dart` | Saved jobs |
| `homeProvider` | `features/home/home_provider.dart` | Home screen data |

---

## 7. API Reference

**Base URL:** `https://gulfwalkin.com/api`

All protected routes require the header:
```
Authorization: Bearer <token>
```

### Authentication (Public — no token needed)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/employee/register` | Register new employee |
| POST | `/auth/login` | Email + password login → returns `token` |
| POST | `/auth/employee/google` | Google OAuth login → returns `token` |
| POST | `/auth/otp/send` | Send OTP to email/phone |
| POST | `/auth/otp/verify` | Verify OTP → returns `token` |
| POST | `/auth/password/reset` | Reset password with verified OTP |

**Login response shape:**
```json
{
  "token": "string",
  "role": "employee",
  "user": { "id": 1, "first_name": "...", "email": "...", ... }
}
```

### Auth (Protected)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/auth/me` | Get current user profile |
| POST | `/auth/logout` | Invalidate token |

### Jobs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/jobs` | List jobs (supports `?category=`, `?country=`, `?search=`, `?page=`) |
| GET | `/jobs/{id}` | Job detail |
| POST | `/jobs/{id}/apply` | Apply to a job |
| POST | `/jobs/{id}/report` | Report a job (body: `reason`, optional `details`) |

**Report reasons:** `fake_spam`, `misleading`, `already_filled`, `inappropriate`, `other`

### Employee Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/employee/profile` | Get profile |
| PUT | `/employee/profile` | Update profile fields |
| POST | `/employee/photo` | Upload profile photo (multipart) |
| POST | `/employee/resume` | Upload resume PDF (multipart) |
| GET | `/employee/resume` | Get resume URL |

### Applications & Bookmarks

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/employee/applications` | My job applications list |
| GET | `/employee/bookmarks` | Saved jobs |
| POST | `/employee/bookmarks/{jobId}` | Save a job |
| DELETE | `/employee/bookmarks/{jobId}` | Remove saved job |

### Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | List in-app notifications (paginated) |
| PUT | `/notifications/read-all` | Mark all notifications as read |

### Job Alerts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/employee/job-alerts` | List saved job alert preferences |
| POST | `/employee/job-alerts` | Create alert (body: `keywords`, `location`, `category`) |
| PUT | `/employee/job-alerts/notify-all` | Toggle "notify me for all new jobs" (body: `enabled: bool`) |
| DELETE | `/employee/job-alerts/{id}` | Delete an alert |

### Device Registration (FCM)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/devices/register` | Register FCM token (body: `token`, `platform: "ios"` or `"android"`) |

**Important for iOS:** pass `"platform": "ios"` so the backend can handle APNS vs FCM differences if needed in future.

### Lookups

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/categories` | Job categories list |
| GET | `/states` | Countries/states list |
| GET | `/companies/top-hiring` | Top companies (home screen section) |
| GET | `/employee/recommendations` | Recommended jobs for current user |

### CMS Pages

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cms/about` | About Us content |
| GET | `/cms/terms` | Terms & Conditions |
| GET | `/cms/privacy` | Privacy Policy |

### Miscellaneous

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/advertisements/active` | Active banner advertisements |
| POST | `/contact` | Submit contact form (body: `name`, `email`, `message`) |
| POST | `/app-feedback` | Submit rating + feedback (body: `rating: 1–5`, `message`, `app_version`) |

---

## 8. Features Implemented

### Auth
- [x] Email + password login
- [x] Employee registration
- [x] OTP-based password reset (forgot password)
- [x] Google Sign-In
- [x] Persistent session (Hive-stored JWT, survives app restart)
- [x] Auto-redirect to login on 401

### Home Screen
- [x] Recommended jobs (personalized)
- [x] Top companies hiring now
- [x] Category chips → filtered job list
- [x] Active advertisements / banners

### Jobs
- [x] Browse all jobs with infinite scroll pagination
- [x] Search by keyword
- [x] Filter by category + country
- [x] Job detail — full description, positions, salary, deadline banner
- [x] Quick Apply from job card (one-tap)
- [x] Full apply from job detail screen
- [x] Share job (native share sheet)
- [x] Bookmark / save job
- [x] Report job (reason + optional details)
- [x] Recently viewed jobs (local, Hive)

### Notifications
- [x] In-app notification list
- [x] Unread count badge on tab bar
- [x] Mark all as read (optimistic UI update)
- [x] Foreground FCM → in-app SnackBar banner
- [x] Background/terminated FCM → system tray notification
- [x] Tap notification → navigate to job detail

### Profile
- [x] View profile with completion score
- [x] Edit personal info, skills, experience
- [x] Profile photo upload
- [x] Resume PDF upload + in-app PDF viewer

### Job Alerts
- [x] Create keyword/location/category alerts
- [x] "Notify me for all new jobs" toggle
- [x] Delete alerts

### Settings
- [x] Change password
- [x] Contact Us form
- [x] About Us / Terms / Privacy (CMS pages from backend)
- [x] Rate & Feedback (star rating + comment → stored in backend)
- [x] Sign Out
- [x] Delete Account (directs to support email — GDPR flow)

---

## 9. Push Notifications (FCM)

### How it works

1. On login → `FcmService.registerToken(dio)` calls `POST /devices/register` with the FCM token and `platform: "android"` (change to `"ios"` for iOS builds)
2. On server: admin approves a job → `JobListingObserver` dispatches `DispatchJobAlertNotifications`
3. Backend sends FCM v1 HTTP API push to registered device tokens
4. Device receives notification

### Flutter FCM Setup (`lib/core/services/fcm_service.dart`)

- `FcmService.registerBackgroundHandler()` — called in `main()` before `runApp()`
- `FcmService.init()` — called after first frame (deferred to avoid OEM crash on Android 13+)
  - Creates Android notification channel `gulfwalkin_alerts` (required for Android 8+)
  - Requests notification permission
  - Caches launch message (for terminated-state navigation)
- `FcmService.registerToken(dio)` — called on login + on every app restart if already logged in
- `FcmService.onForegroundMessage` — stream → shows SnackBar banner
- `FcmService.onNotificationTap` — stream → navigates to job detail

### iOS-specific steps needed

1. **Enable Push Notifications capability** in Xcode: `Runner → Signing & Capabilities → + Capability → Push Notifications`
2. **Enable Background Modes**: `Background fetch` + `Remote notifications`
3. Upload **APNs Auth Key** (or certificate) to Firebase console → Project Settings → Cloud Messaging → iOS app
4. Download `GoogleService-Info.plist` from Firebase and add to `ios/Runner/` in Xcode
5. In `FcmService.registerToken()`, the `platform` field should be `"ios"` — update accordingly or make it dynamic using `Platform.isIOS`

### Notification channel (Android only)

The Android notification channel `gulfwalkin_alerts` is declared in `AndroidManifest.xml` and created at runtime in `FcmService.init()` using `flutter_local_notifications`. iOS does not use notification channels — this code is guarded with `if (Platform.isAndroid)` and is a no-op on iOS.

---

## 10. iOS Setup Checklist

Work through this checklist when setting up the iOS target:

### Xcode Project
- [ ] Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
- [ ] Set Bundle Identifier to `com.gulfwalkin.app`
- [ ] Set Team / Signing to your Apple Developer account
- [ ] Verify Deployment Target: **iOS 13.0** (already set in project.pbxproj)
- [ ] Run `pod install` inside `ios/` before first build

### Firebase
- [ ] Download `GoogleService-Info.plist` from Firebase console (project `gulfwalkin-1c13f`)
- [ ] Drag into Xcode under `Runner/` → check "Copy items if needed" + "Add to target: Runner"
- [ ] Add Push Notifications capability
- [ ] Add Background Modes capability → enable "Remote notifications" + "Background fetch"
- [ ] Upload APNs key (`.p8`) to Firebase console → Project Settings → Cloud Messaging

### Google Sign-In
- [ ] Add the `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist` as a URL scheme in Xcode:
  - Target → Info → URL Types → add the `REVERSED_CLIENT_ID` as a URL scheme

### Platform field for device registration
- [ ] In `lib/core/services/fcm_service.dart`, update `registerToken()` to send `"ios"` on iOS:
```dart
import 'dart:io';

await dio.post('/devices/register', data: {
  'token': token,
  'platform': Platform.isIOS ? 'ios' : 'android',
});
```

### Permissions in `ios/Runner/Info.plist`
Add these keys if not already present:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to take a profile photo</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Used to select a profile photo</string>

<key>NSMicrophoneUsageDescription</key>
<string>Required by image picker</string>
```

### CocoaPods
```bash
cd ios
pod install
cd ..
flutter run -d <device>
```

If you get signing/pod issues:
```bash
cd ios
pod deintegrate
pod install
```

---

## 11. State Management

The app uses **Riverpod** (v2). Key patterns:

### Reading providers in widgets

```dart
// In a ConsumerWidget:
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobListProvider);
    return jobs.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (state) => ListView(...),
    );
  }
}
```

### Calling actions

```dart
// Trigger a state change
ref.read(jobListProvider.notifier).refresh();

// Invalidate a provider (forces re-fetch)
ref.invalidate(unreadCountProvider);
```

### Auth check

```dart
final auth = ref.watch(authProvider);
auth.when(
  data: (state) => state.isAuthenticated ? HomeScreen() : LoginScreen(),
  loading: () => SplashScreen(),
  error: (_, __) => LoginScreen(),
);
```

---

## 12. Navigation (GoRouter)

Routes are defined in `lib/router.dart`. The router uses `authProvider` as a `refreshListenable` — it automatically redirects to `/login` when logged out and to `/home` when logged in.

| Route | Screen |
|-------|--------|
| `/` | Splash (resolves auth, redirects) |
| `/onboarding` | Onboarding screen |
| `/login` | Login screen |
| `/register` | Register screen |
| `/forgot-password` | Forgot password |
| `/otp` | OTP verification |
| `/home` | Main shell (bottom nav tabs) |
| `/home/jobs` | Browse jobs tab |
| `/home/saved` | Saved jobs tab |
| `/home/notifications` | Notifications tab |
| `/home/settings` | Settings tab |
| `/jobs/:id` | Job detail |
| `/profile` | Profile screen |
| `/job-alerts` | Job alerts management |
| `/contact` | Contact Us |
| `/cms/:slug` | CMS page (about / terms / privacy) |

**Navigate to a job from a push notification:**
```dart
context.push('/jobs/${jobId}');
```

---

## 13. Known Gaps / TODO for iOS

These items work on Android but need iOS-specific testing or implementation:

| Area | Issue | Action needed |
|------|-------|--------------|
| FCM token platform | Always sends `"android"` | Change to `Platform.isIOS ? "ios" : "android"` |
| `GoogleService-Info.plist` | Missing from repo (gitignored — contains secrets) | Get from Firebase console |
| APNs setup | Not configured | Upload `.p8` key to Firebase console |
| `image_picker` permissions | `Info.plist` may need camera/photo keys | Add NSCameraUsageDescription etc. |
| `file_picker` | Works on Android, needs iOS entitlements check | Test with iCloud Drive / Files app |
| `share_plus` | Uses `ShareParams` API (v12) | Should work on iOS, verify sheet appears |
| PDF viewer (Syncfusion) | Android tested | Run on iOS simulator and check PDF opens |
| Notification channel | Android-only (guarded with `Platform.isAndroid`) | No action needed — iOS uses APNS natively |
| Background FCM handler | `Firebase.initializeApp()` without options | Works on Android via `google-services.json`; on iOS this needs `GoogleService-Info.plist` in place |
| `url_launcher` | Tested on Android | Test phone/email/web links on iOS |

---

## 14. Branch & Contribution Guidelines

### Branches

| Branch | Purpose |
|--------|---------|
| `main` | **Protected** — production-ready code only, no direct pushes |
| `ios-dev` | Active iOS development branch — base your work here |
| `feature/<name>` | Individual feature branches off `ios-dev` |

### Workflow

```bash
# Start from ios-dev
git checkout ios-dev
git pull origin ios-dev

# Create a feature branch
git checkout -b feature/apns-setup

# ... make changes ...

git add <files>
git commit -m "feat: configure APNs and GoogleService-Info.plist for iOS"

# Push and open a PR into ios-dev (not main)
git push origin feature/apns-setup
```

Open a **Pull Request** into `ios-dev`. Once iOS is stable and tested, `ios-dev` will be merged into `main` via PR review.

### Main branch protection rules

- Direct push to `main` is **blocked**
- All changes must go through a Pull Request
- At least **1 reviewer approval** required before merge

### Commit message convention

```
feat: add FCM setup for iOS
fix: correct bundle ID in Xcode project
chore: run pod install and update Podfile.lock
docs: update iOS setup checklist in README
```

---

## Backend Repository

The Laravel backend is in a separate repository:

**GitHub:** `Developer-Selva/Gulfwalkin` (private)

The backend exposes all endpoints listed in [Section 7](#7-api-reference). If you need to run the backend locally, contact Selva for the `.env` file and server credentials.
