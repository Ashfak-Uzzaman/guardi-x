// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBICnmQGLQlShJAudVZtqRhWP0y4Eo_YNI',
    appId: '1:1008903002947:web:981e0cd39d26b4b1bcedf6',
    messagingSenderId: '1008903002947',
    projectId: 'guardix-ac-project-1',
    authDomain: 'guardix-ac-project-1.firebaseapp.com',
    storageBucket: 'guardix-ac-project-1.firebasestorage.app',
    measurementId: 'G-YB0D93R7CS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD06NbspWIpWcCX2_PF9BEyQoQez7xe4kI',
    appId: '1:1008903002947:android:e44b909f84f23c56bcedf6',
    messagingSenderId: '1008903002947',
    projectId: 'guardix-ac-project-1',
    storageBucket: 'guardix-ac-project-1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAm5w3ozP-GBwyT7V7M9VT_Ho9AG1JroqQ',
    appId: '1:1008903002947:ios:e064b04227cbfcddbcedf6',
    messagingSenderId: '1008903002947',
    projectId: 'guardix-ac-project-1',
    storageBucket: 'guardix-ac-project-1.firebasestorage.app',
    iosBundleId: 'com.guardix.guardix',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAm5w3ozP-GBwyT7V7M9VT_Ho9AG1JroqQ',
    appId: '1:1008903002947:ios:e064b04227cbfcddbcedf6',
    messagingSenderId: '1008903002947',
    projectId: 'guardix-ac-project-1',
    storageBucket: 'guardix-ac-project-1.firebasestorage.app',
    iosBundleId: 'com.guardix.guardix',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBICnmQGLQlShJAudVZtqRhWP0y4Eo_YNI',
    appId: '1:1008903002947:web:3964a7ed48d23726bcedf6',
    messagingSenderId: '1008903002947',
    projectId: 'guardix-ac-project-1',
    authDomain: 'guardix-ac-project-1.firebaseapp.com',
    storageBucket: 'guardix-ac-project-1.firebasestorage.app',
    measurementId: 'G-08JXXDLVPN',
  );
}
