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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDyCpXjxss5f9alG8EgPWwc63YixFaPH3I',
    appId: '1:743865889806:web:49e347246d761cc2e7785f',
    messagingSenderId: '743865889806',
    projectId: 'bananaapp-46723',
    authDomain: 'bananaapp-46723.firebaseapp.com',
    databaseURL: 'https://bananaapp-46723-default-rtdb.firebaseio.com',
    storageBucket: 'bananaapp-46723.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyCpXjxss5f9alG8EgPWwc63YixFaPH3I',
    appId: '1:743865889806:android:e8016a3a8eea0801e7785f',
    messagingSenderId: '743865889806',
    projectId: 'bananaapp-46723',
    databaseURL: 'https://bananaapp-46723-default-rtdb.firebaseio.com',
    storageBucket: 'bananaapp-46723.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDyCpXjxss5f9alG8EgPWwc63YixFaPH3I',
    appId: '1:743865889806:ios:49e347246d761cc2e7785f',
    messagingSenderId: '743865889806',
    projectId: 'bananaapp-46723',
    databaseURL: 'https://bananaapp-46723-default-rtdb.firebaseio.com',
    storageBucket: 'bananaapp-46723.firebasestorage.app',
  );
}
