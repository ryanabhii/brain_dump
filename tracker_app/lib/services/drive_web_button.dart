import 'package:flutter/widgets.dart';

// On web (js_interop available) we render Google's official GIS button; on
// every other platform there's no button (sign-in uses the native flow).
import 'drive_web_button_stub.dart'
    if (dart.library.js_interop) 'drive_web_button_web.dart'
    as impl;

/// Google's rendered sign-in button on web; `null` on other platforms.
Widget? driveWebButton() => impl.buildButton();
