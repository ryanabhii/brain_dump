# Privacy Policy — Tracker

_Last updated: 2026-07-07_

**Tracker** ("the app") is a local-first personal organiser developed by
**Xenon54**. This document explains exactly what data the app collects, where
it goes, and what control you have over it.

> **TL;DR** — Your data lives on your device. The only network sync is your own
> Google Drive, only when you sign in, and we never see or store any of it.

---

## 1. Data we collect

We do not operate any backend server. The app does not transmit any data to
servers controlled by Xenon54. Specifically, we do not collect:

- Account identifiers, email addresses, names, or contact information.
- Device identifiers (IMEI, advertising ID, etc.).
- Crash reports, analytics, or usage telemetry.
- Location data.

## 2. Data you create

Everything you enter — killzones, trades, subscriptions, brain-dump notes,
grocery items, body / nutrition logs, and reminder settings — is stored
**locally on your device** using Android's `SharedPreferences`. It never
leaves the device unless you opt in to Google Drive sync (see §3).

### Microphone and voice notes

If you grant microphone access and record a voice brain dump, two things are
created:

- **A transcript**, produced by your device's on-device speech recognizer.
  Stored locally as part of the note.
- **An audio recording** (`.m4a`), saved in the app's private documents
  folder **on your device only**, so you can replay the note later.

Recordings are never uploaded anywhere — they are excluded from Drive sync
and backups. Deleting a voice note (or uninstalling the app) deletes its
recording. Microphone access is optional; typing works without it.

## 3. Optional Google Drive sync

If you sign in to Google from the Profile screen, the app uses **Google
Sign-In** to authenticate with your account and the **Google Drive API** to
read and write a small number of JSON files, all inside the hidden
`appDataFolder` of **your own Drive** — a private area only this app can
see, invisible to other apps and to your normal Drive file list:

- **Backup file** — a serialised copy of your app data, written when you tap
  "Back up" and read when you tap "Restore".
- **Per-tab sync files** — one JSON file per section you enable for sync
  (killzones, spend, capture, household, body, trading). Signing in with the
  same Google account on another device syncs these sections there too.

These files are owned by **your Google account**. Xenon54 has no access to
them, no copy of them, and no way to read them.

The only OAuth scope requested is:

- `https://www.googleapis.com/auth/drive.appdata` — read/write access to the
  app's own hidden data folder, and nothing else in your Drive. The app
  cannot see, modify, or share any of your other Drive files.

## 4. Sharing with other people

The app has no sharing features. Your data is never made visible to any
other person or account — sync is strictly between your own devices, signed
in to your own Google account.

## 5. Notifications

Reminders (killzone start alerts, brain-dump reminders, daily review) are
scheduled by the OS using `flutter_local_notifications`. Notification
contents are constructed entirely on-device from your own data. No
notification content is transmitted anywhere.

## 6. Children's privacy

The app is not directed at children under 13. We do not knowingly collect any
information from children.

## 7. Your controls

- **Reset** the app from the Profile screen to wipe all local data.
- **Sign out** from Google to stop all Drive sync. Signing out also revokes
  the OAuth grant, so the next sign-in re-prompts for account selection and
  scope consent.
- **Delete the app's hidden Drive data** from Google Drive → Settings →
  Manage apps → Tracker → "Delete hidden app data".
- **Uninstall** the app to remove all local data from your device.

## 8. Changes to this policy

Material changes will be reflected by updating the date at the top of this
document. The current version is always the one shipped in the published app
binary.

## 9. Contact

Questions or concerns: open an issue at
<https://github.com/ryanabhii/brain_dump/issues>.
