# Privacy Policy — Tracker

_Last updated: 2026-06-12_

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

## 3. Optional Google Drive sync

If you sign in to Google from the Profile screen, the app uses **Google
Sign-In** to authenticate with your account and the **Google Drive API** to
read and write a small number of JSON files **in your own Drive**:

- **Backup file** — stored in the hidden `appDataFolder` of your Drive,
  invisible to other apps. Contains a serialised copy of your app data.
- **Per-tab sync files** — visible in your normal Drive (so they can be
  shared). One JSON file per syncable section (killzones, spend, capture,
  household, body, trading). Tagged with an `appProperties` marker so the
  app can find them.

These files are owned by **your Google account**. Xenon54 has no access to
them, no copy of them, and no way to read them. You may delete them at any
time from your Drive web interface.

The OAuth scopes requested are:

- `https://www.googleapis.com/auth/drive` — to read/write tab files in your
  Drive and grant share permissions to collaborators you nominate.
- `https://www.googleapis.com/auth/drive.appdata` — to read/write the hidden
  whole-app backup file.

## 4. Sharing with other people

When you share a tab with a collaborator from the Profile screen, the app
calls the Drive Permissions API to grant them reader or writer access to that
tab's JSON file. The collaborator's email address is sent to Google so the
share can be delivered. Xenon54 does not receive that email or store any
record of the collaboration.

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
- **Delete the Drive files** directly from drive.google.com.
- **Uninstall** the app to remove all local data from your device.

## 8. Changes to this policy

Material changes will be reflected by updating the date at the top of this
document. The current version is always the one shipped in the published app
binary.

## 9. Contact

Questions or concerns: open an issue at
<https://github.com/ryanabhii/brain_dump/issues>.
