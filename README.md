# MbareToYou

> Production-ready Flutter marketplace connecting Mbare Musika vendors with customers in Harare, Zimbabwe.

A multi-app Flutter project for local vegetable/fruit delivery, similar to Uber Eats but tailored for Zimbabwe's largest fresh produce market.

## Project Structure

```
mbare_to_you/
├── apps/
│   ├── customer_app/      # Customer mobile app (Android/iOS)
│   ├── driver_app/        # Driver mobile app
│   ├── vendor_app/        # Vendor mobile app
│   └── admin_web/         # Admin web dashboard
├── packages/
│   ├── mbare_core/        # Shared models, errors, utils
│   ├── mbare_ui/          # Design system & common widgets
│   ├── mbare_services/    # Firebase, API clients
│   └── mbare_data/        # Repositories & data sources
├── infra/
│   ├── firebase/          # Firestore rules, indexes
│   ├── cloud_functions/   # Backend logic (Node.js/TypeScript)
│   └── scripts/           # Deployment & utility scripts
└── docs/                  # Documentation
```

## Tech Stack

- **Framework:** Flutter 3.27+ (Dart 3.7+)
- **State Management:** Riverpod 2.x with code generation
- **Backend:** Firebase (Auth, Firestore, Functions, Storage, FCM)
- **Payments:** Ecocash (Econet) + Stripe (card payments)
- **Maps:** Google Maps SDK
- **CI/CD:** GitHub Actions
- **Mono-repo:** Melos

## Quick Start

### Prerequisites

- Flutter SDK 3.27.0 or higher
- Dart SDK 3.7.0 or higher
- Node.js 18+ (for Cloud Functions)
- Melos CLI: `dart pub global activate melos`
- Firebase CLI: `npm install -g firebase-tools`

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mbare_to_you
   ```

2. **Bootstrap all packages**
   ```bash
   melos bootstrap
   ```

3. **Configure Firebase**
   - Create a Firebase project at https://console.firebase.google.com
   - Enable Authentication, Firestore, Storage, Functions, FCM
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place config files in respective app folders (see [Setup Guide](docs/setup.md))

4. **Generate code**
   ```bash
   melos run codegen
   ```

5. **Run customer app**
   ```bash
   cd apps/customer_app
   flutter run
   ```

## Development

### Available Melos Scripts

```bash
melos run analyze      # Static analysis
melos run format       # Format code
melos run test         # Run all tests
melos run codegen      # Generate code (Riverpod, Freezed, etc.)
melos run clean        # Clean all packages
melos run build:apk    # Build Android APK
```

### Project Conventions

- **Imports:** Always use `package:` imports (never relative)
- **Code Style:** Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Linting:** Strict mode enabled (see `analysis_options.yaml`)
- **Commits:** Conventional Commits format
- **Testing:** Unit tests for domain logic, widget tests for UI

## Architecture

This project follows **Clean Architecture** principles:

```
Presentation Layer (UI)
    ↓
Providers Layer (Riverpod)
    ↓
Domain Layer (Use Cases, Models)
    ↓
Data Layer (Repositories, Data Sources)
```

See [Architecture Documentation](docs/architecture.md) for details.

## Features

### MVP (Phase 1)
- [x] Customer authentication (email/password)
- [x] Browse vendors by table number
- [x] View products with images
- [x] Shopping cart
- [x] Checkout with mock payment
- [x] Order tracking
- [x] Vendor product management
- [x] Driver order management

### Post-MVP (Phase 2)
- [ ] Real Ecocash/Stripe integration
- [ ] Real-time driver tracking with maps
- [ ] Push notifications
- [ ] Ratings & reviews
- [ ] Search & filters
- [ ] Offline support (Hive)
- [ ] Shona localization

## Documentation

- [Setup Guide](docs/setup.md) - Environment setup
- [Architecture](docs/architecture.md) - System design
- [Firestore Schema](docs/firestore_schema.md) - Database structure
- [Ecocash Integration](docs/payments/ecocash_integration.md) - Payment setup
- [Deployment](docs/deployment.md) - Production deployment

## Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes and commit: `git commit -m "feat: add my feature"`
3. Run tests: `melos run test`
4. Push and create PR

## License

Private project - All rights reserved

## Support

For issues or questions, contact: [Your Contact Info]
