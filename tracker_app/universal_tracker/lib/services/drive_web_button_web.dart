import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

// Web: Google Identity Services rendered sign-in button. Clicking it performs
// authentication; DriveSyncService listens for the resulting user change.
Widget? buildButton() => web.renderButton();
