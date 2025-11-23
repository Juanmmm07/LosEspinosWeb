import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // Configuración para Web (YA CONFIGURADO)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyB_sIZpjfFVOiZbtmD2sFH2o-NV8J3aQ7E",
    appId: "1:572940136466:web:7e0c84520b45f5b095a8cb",
    messagingSenderId: "572940136466",
    projectId: "losespinosweb",
    authDomain: "losespinosweb.firebaseapp.com",
    storageBucket: "losespinosweb.firebasestorage.app",
  );

  // ⚠️ IMPORTANTE: Para Android, ve a Firebase Console y obtén estos valores
  // Firebase Console > Proyecto > Configuración > Apps > Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyB_sIZpjfFVOiZbtmD2sFH2o-NV8J3aQ7E",
    appId: "1:572940136466:web:7e0c84520b45f5b095a8cb",
    messagingSenderId: "572940136466",
    projectId: "losespinosweb",
    storageBucket: "losespinosweb.firebasestorage.app",
  );

  // ⚠️ IMPORTANTE: Para iOS, ve a Firebase Console y obtén estos valores
  // Firebase Console > Proyecto > Configuración > Apps > iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyB_sIZpjfFVOiZbtmD2sFH2o-NV8J3aQ7E",
    appId: "1:572940136466:web:7e0c84520b45f5b095a8cb",
    messagingSenderId: "572940136466",
    projectId: "losespinosweb",
    storageBucket: "losespinosweb.firebasestorage.app",
    iosBundleId: "com.losespinos.glamping", // Tu bundle ID real
  );
}