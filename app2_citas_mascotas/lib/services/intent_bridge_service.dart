import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IntentBridgeService {
  IntentBridgeService._();

  static final IntentBridgeService instance = IntentBridgeService._();

  static const MethodChannel _channel =
  MethodChannel('com.example.app_veterinaria_agenda/intent_bridge');

  Future<Map<String, dynamic>> readInitialIntentData() async {
    try {
      final dynamic result = await _channel.invokeMethod('getIntentData');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      debugPrint("PlatformException en IntentBridgeService: ${e.message}");
    } catch (e) {
      debugPrint("Error general al leer Intent: $e");
    }

    return <String, dynamic>{};
  }
}