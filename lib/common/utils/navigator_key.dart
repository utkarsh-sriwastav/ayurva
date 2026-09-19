import 'package:flutter/material.dart';

/// Global navigator key.
///
/// Firebase Phone Auth can auto-verify a user (SMS auto-retrieval on
/// Android) via a callback that fires independently of whichever
/// screen happens to be mounted at that moment. This key lets that
/// callback navigate to the correct home screen even if the user is
/// still sitting on the OTP screen waiting to type a code manually.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
