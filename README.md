# Senior Dialer

A one-tap, picture-based phone app for someone who can't read or write.

No text to read, no menus to navigate, no way to accidentally type
something. Just a photo, a name, and a number — tap the photo and it
calls. Built for use with a kiosk / "kid mode" launcher so it's the
only thing on the phone.

## Features

- **Contacts, automatically** — pulls directly from the phone's normal
  contact list (with photos), so there's nothing to maintain separately.
- **Tap a photo to call** — places the call directly, no dialer screen.
- **Big everything** — large photos and text, about 4-5 contacts per
  screen, sized to fit any screen and both orientations.
- **Call history** — a simple, tappable list of recent calls.
- **Messages, view-only** — read received texts; there is no text
  field, reply button, or compose screen anywhere in the app, so
  there's nothing to accidentally type into.

## Screenshots

![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)

## Getting started

### 1. Clone and install dependencies

```bash
git clone <this-repo-url>
cd CONTACT_APP
flutter pub get
```

### 2. Android permissions

Add these to `android/app/src/main/AndroidManifest.xml`, as a sibling
of `<application>` (directly under `<manifest>`, not inside it):

```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.READ_CALL_LOG"/>
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS"/>
```

### 3. Core library desugaring

The call-history feature (`call_log` package) requires this. In
`android/app/build.gradle.kts`, inside `android { ... }`:

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}
```

And add a `dependencies` block:

```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### 4. Run it

```bash
flutter run
```

The app will ask for Contacts, Phone, and SMS permissions the first
time each relevant screen is opened — someone with reading difficulty
will need help tapping "Allow" once.

### 5. Custom app icon (optional)

You can change the app icon by replacing the image at assets/icon/icon.png, then running:

```bash
dart run flutter_launcher_icons
```

### 6. Lock it down

Use a kiosk-mode / single-app launcher (e.g. a "kid mode" feature, or
apps like Fully Kiosk) to pin this as the only app the phone can open.

## Notes for contributors

- Only Android is supported — direct calling and call-log/SMS reading
  are Android-only APIs; iOS does not permit either.
- Contact matching in the Call History and Messages screens compares
  the last 9 digits of a phone number, so formatting differences (like
  a leading `+213` or `0`) still match correctly. See `contact_utils.dart`.
- Tile sizing is calculated at runtime from the actual screen height,
  and text scales with it too, so it adapts to different screen sizes
  and to portrait/landscape without overflowing.

## License

MIT — see [LICENSE](LICENSE).
