# Ezz NFe

A Flutter mobile app for managing clients, services, products, and appointments in a small business context, with support for Brazilian electronic invoices (NFe) and Google Calendar integration.

## Features

- **Clients** — CRUD for customer records
- **Products** — Product catalog with types and brands
- **Services** — Service catalog with pricing and linked products
- **Appointments** — Schedule service appointments with optional Google Calendar sync (creates events when appointments are added, removes them when deleted)
- **Invoices** — NFe invoice management (integration in progress)
- **Authentication** — Sign in with Google or email/password; biometric lock
- **Settings** — Profile editing and app preferences

## Tech Stack

- Flutter
- Firebase (Auth, Firestore)
- Riverpod (state management)
- Go Router (navigation)

## Setup

1. Clone the repository
2. Copy `auth_config_dev.dart.example` and `auth_config_prod.dart.example` to `auth_config_dev.dart` and `auth_config_prod.dart`, then add your Firebase/Google OAuth Web Client IDs
3. Enable Google Calendar API in Google Cloud Console (for appointment sync)
4. Run `flutter pub get` in the `app` directory
5. Run with `flutter run --flavor dev --dart-define=FLAVOR=dev`
