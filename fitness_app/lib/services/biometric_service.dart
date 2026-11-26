import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Servicio de autenticacion biometrica con manejo defensivo de errores.
class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<({bool available, String statusText, List<BiometricType> types})>
      checkAvailability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final types = await _auth.getAvailableBiometrics();

      if (!supported) {
        return (
          available: false,
          statusText: 'Hardware biométrico no soportado en este dispositivo.',
          types: <BiometricType>[],
        );
      }
      if (!canCheck || types.isEmpty) {
        return (
          available: false,
          statusText:
              'No hay huellas registradas. Configura una huella en Ajustes del teléfono.',
          types: types,
        );
      }
      return (
        available: true,
        statusText: 'Huella dactilar lista y verificada.',
        types: types,
      );
    } on PlatformException catch (e) {
      return (
        available: false,
        statusText: 'Error al consultar biometría: ${e.message ?? e.code}',
        types: <BiometricType>[],
      );
    } catch (_) {
      return (
        available: false,
        statusText: 'No fue posible verificar la biometría del dispositivo.',
        types: <BiometricType>[],
      );
    }
  }

  Future<({bool success, String message})> authenticate({
    String reason = 'Valida tu huella dactilar para ingresar a FITPRO',
  }) async {
    try {
      final availability = await checkAvailability();
      if (!availability.available) {
        return (success: false, message: availability.statusText);
      }

      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (ok) {
        return (
          success: true,
          message: 'Huella validada correctamente. Acceso concedido.',
        );
      }
      return (
        success: false,
        message: 'Autenticación cancelada o huella no reconocida.',
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('notenrolled')) {
        return (
          success: false,
          message: 'No tienes huellas registradas en el teléfono.',
        );
      }
      if (code.contains('lockedout')) {
        return (
          success: false,
          message:
              'Sensor biométrico bloqueado temporalmente por intentos fallidos.',
        );
      }
      if (code.contains('notavailable')) {
        return (
          success: false,
          message: 'El lector de huella no está disponible en este momento.',
        );
      }
      return (
        success: false,
        message: 'Fallo biométrico (${e.code}): ${e.message ?? 'intenta de nuevo'}',
      );
    } catch (_) {
      return (
        success: false,
        message: 'Error inesperado al validar tu huella dactilar.',
      );
    }
  }
}
