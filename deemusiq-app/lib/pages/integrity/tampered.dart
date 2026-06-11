import 'package:flutter/material.dart';

/// Shown instead of the app when the signing certificate does not match the
/// pinned release certificate — i.e. this is a repackaged/modified build. Kept
/// deliberately dependency-light (plain Material) so it renders even when the
/// rest of the app is never initialised.
class TamperBlockedApp extends StatelessWidget {
  const TamperBlockedApp({super.key});

  static const _orange = Color(0xFFFF5722);
  static const _ink = Color(0xFF0C0A09);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _ink,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.gpp_bad_outlined, color: _orange, size: 72),
                  SizedBox(height: 20),
                  Text(
                    "This copy of DeeMusiq has been modified",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "For your safety it won't run. This build wasn't signed by "
                    "DeeMusiq, so it may be tampered with or fake.\n\n"
                    "Install the official app only from deemusiq.github.io/deemusiq "
                    "or the DeeMusiq GitHub releases.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
