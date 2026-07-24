import 'package:android_intent_plus/android_intent.dart';

class IntentDispatcherService {
  /// Envía un payload a la App 3 (confirmación de cita).
  static Future<void> emitToApp3(Map<String, dynamic> payload) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      package: 'com.example.app_confirmacion_cita',
      componentName: 'com.example.app_confirmacion_cita.MainActivity',
      arguments: payload,
    );

    await intent.launch();
  }

  /// Envía un payload a la App Farmacia (nueva funcionalidad).
  /// Cambia el package/component según la app de destino.
  static Future<void> emitToFarmacia(Map<String, dynamic> payload) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      package: 'com.example.app_farmacia',
      componentName: 'com.example.app_farmacia.MainActivity',
      arguments: payload,
    );

    await intent.launch();
  }
}
