# TAJAMAR TV+ - Manual Técnico

## Arquitectura del Proyecto

El proyecto está construido usando **Flutter** para el frontend (multiplataforma) y **Firebase** como backend.

Se ha implementado **Clean Architecture** dividida en 3 capas principales:

1. **Presentation (UI)**: Widgets de Flutter, Riverpod Providers, Views.
2. **Domain**: Entidades de negocio puro, interfaces de repositorios, casos de uso.
3. **Data**: Modelos de Firebase, Local Storage (Hive), implementación concreta de repositorios.

## Dependencias Clave

- `flutter_riverpod`: Manejo de estado y dependencias.
- `go_router`: Enrutamiento declarativo con guards de autenticación y roles.
- `firebase_auth`: Autenticación JWT.
- `cloud_firestore`: Base de datos NoSQL en tiempo real.
- `better_player`: Reproductor avanzado para HLS/DASH/M3U8.
- `hive`: Base de datos local ultra rápida para caché.

## Roles del Sistema

- `super_admin`: Acceso total.
- `admin`: Acceso restringido a su `companyId`.
- `operator`: Acceso restringido a ciertas funciones del panel.
- `client`: Usuario final de la plataforma OTT.

## CI/CD (GitHub Actions)

Los workflows están ubicados en `.github/workflows/`:
- `dev.yml`: Se ejecuta en push a la rama `develop`. Realiza tests y lint.
- `qa.yml`: Build de Android APK para testing.
- `production.yml`: Despliegue de Firebase Hosting y build para release (AppBundle / Web).

## Consideraciones de Rendimiento

- Se utiliza **Lazy Loading** en Firestore limitando consultas a 50 documentos.
- El historial y favoritos se mantienen cacheados en **Hive** localmente.
- Smart TV (Android TV/Google TV) utiliza `FocusNode` explícitos para navegación por D-Pad.
