import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options_dev.dart' as dev;
import '../../firebase_options_prod.dart' as prod;

const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

FirebaseOptions get firebaseOptions {
  switch (_flavor) {
    case 'prod':
      return prod.DefaultFirebaseOptions.currentPlatform;
    case 'dev':
    default:
      return dev.DefaultFirebaseOptions.currentPlatform;
  }
}
