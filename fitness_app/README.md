# FITPRO

Aplicación móvil de Fitness desarrollada en Flutter para **Android Studio**, diseñada con interfaz deportiva oscura y cumplimiento completo de la rúbrica de sensores, biometría, GPS y persistencia local.

## Funcionalidades principales

- **Login, Registro y Autenticación Biométrica (RF-01):** Inicio de sesión con correo/contraseña, registro de usuario con metas físicas y desbloqueo por huella dactilar (`local_auth`) con alertas claras de éxito y fallo.
- **Dashboard Deportivo (`Estado`) (RF-02, RF-03, RF-04):** Anillo de progreso de pasos con degradado eléctrico, tarjetas curvas de calorías y distancia, gráficas suaves en tiempo real de Acelerómetro y Giroscopio, y acceso directo a Nutrición.
- **Nutrición y Comidas por Foto (`Nutrición`):** Captura con cámara o galería (`image_picker`), estimación modular de platillo/calorías/macros editables e historial del día conectado al balance calórico diario en Hive.
- **Ubicación y Mapa Interactivo (`Deporte`) (RF-05, RF-06):** Mapa con OpenStreetMap en modo oscuro (`flutter_map`), localización GPS en vivo, trazado de ruta, velocidad/distancia e historial persistente en Hive.
- **Dispositivo y Sensores (`Dispositivo`):** Diagnóstico en vivo de hardware (podómetro, acelerómetro, giroscopio y GPS), unidades Km/Mi y recordatorios.
- **Perfil y Permisos (`Yo`):** Edición de objetivo diario, selector de tema oscuro/claro y colores de acento, centro de permisos en tiempo de ejecución (`permission_handler`) y cierre de sesión.

## Ejecutar en Android Studio

1. Abre esta carpeta en **Android Studio** como proyecto Flutter.
2. Verifica las dependencias con `flutter pub get`.
3. Ejecuta en un teléfono Android físico con huella configurada, GPS activo e Internet para cargar los mosaicos del mapa.
