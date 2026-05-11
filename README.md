# \# 🔨 ContractorConnect

# 

# A Flutter mobile application that bridges the gap between homeowners and verified contractors — making it simple to find, hire, and pay trusted professionals for any job.

# 

# \---

# 

# \## 📋 Table of Contents

# 

# \- \[About the Project](#about-the-project)

# \- \[Features](#features)

# \- \[Tech Stack](#tech-stack)

# \- \[Getting Started](#getting-started)

# &#x20; - \[Prerequisites](#prerequisites)

# &#x20; - \[Installation](#installation)

# &#x20; - \[Environment Variables](#environment-variables)

# \- \[Project Structure](#project-structure)

# \- \[Architecture](#architecture)

# \- \[User Roles](#user-roles)

# \- \[Screens \& Navigation](#screens--navigation)

# \- \[API Integration](#api-integration)

# \- \[Running Tests](#running-tests)

# \- \[Building for Production](#building-for-production)

# \- \[Contributing](#contributing)

# \- \[License](#license)

# 

# \---

# 

# \## About the Project

# 

# \*\*ContractorConnect\*\* solves the frustrating problem of finding reliable contractors for home repairs, renovations, and specialized work. Homeowners can post jobs, browse verified contractor profiles, receive quotes, and manage the entire engagement — from first contact to final payment — all within one app.

# 

# Contractors get a dedicated platform to showcase their work, build reputation through reviews, and grow their client base without relying on word-of-mouth alone.

# 

# \---

# 

# \## Features

# 

# \### For Homeowners

# \- Post jobs with photos, descriptions, and budgets

# \- Browse and search verified contractor profiles

# \- Request and compare multiple quotes

# \- Real-time in-app messaging with contractors

# \- Book appointments and track job progress

# \- Secure in-app payments and payment milestones

# \- Leave verified reviews after job completion

# 

# \### For Contractors

# \- Create a professional profile with portfolio photos

# \- Set service categories, coverage area, and availability

# \- Receive and respond to job requests

# \- Send itemized quotes directly in the app

# \- Manage bookings and schedule via built-in calendar

# \- Track earnings and payment history

# \- Build reputation through client reviews

# 

# \### General

# \- Push notifications for messages, quotes, and updates

# \- Photo uploads for job listings and portfolios

# \- GPS-based contractor search by location

# \- Identity and license verification for contractors

# \- In-app dispute resolution system

# 

# \---

# 

# \## Tech Stack

# 

# | Layer | Technology |

# |---|---|

# | Framework | Flutter 3.x (Dart) |

# | State Management | Riverpod / BLoC |

# | Backend | Firebase (Auth, Firestore, Storage, Functions) |

# | Payments | Stripe SDK |

# | Maps \& Location | Google Maps Flutter + Geolocator |

# | Push Notifications | Firebase Cloud Messaging (FCM) |

# | Real-time Messaging | Firestore streams |

# | Image Handling | image\_picker + cached\_network\_image |

# | Local Storage | Hive / shared\_preferences |

# | CI/CD | GitHub Actions + Fastlane |

# 

# \---

# 

# \## Getting Started

# 

# \### Prerequisites

# 

# Make sure you have the following installed:

# 

# \- \[Flutter SDK](https://flutter.dev/docs/get-started/install) `>= 3.10.0`

# \- Dart `>= 3.0.0`

# \- Android Studio or Xcode (for emulators)

# \- A Firebase project (\[create one here](https://console.firebase.google.com))

# \- A Stripe account (\[sign up here](https://stripe.com))

# 

# Verify your Flutter installation:

# 

# ```bash

# flutter doctor

# ```

# 

# \### Installation

# 

# 1\. \*\*Clone the repository\*\*

# 

# ```bash

# git clone https://github.com/your-org/contractor-connect.git

# cd contractor-connect

# ```

# 

# 2\. \*\*Install dependencies\*\*

# 

# ```bash

# flutter pub get

# ```

# 

# 3\. \*\*Configure Firebase\*\*

# 

# \- Download `google-services.json` (Android) from your Firebase console and place it in `android/app/`

# \- Download `GoogleService-Info.plist` (iOS) and place it in `ios/Runner/`

# 

# 4\. \*\*Set up environment variables\*\* (see below)

# 

# 5\. \*\*Run the app\*\*

# 

# ```bash

# \# Debug mode

# flutter run

# 

# \# Specific device

# flutter run -d <device\_id>

# ```

# 

# \### Environment Variables

# 

# Create a `.env` file in the project root (copy from `.env.example`):

# 

# ```env

# STRIPE\_PUBLISHABLE\_KEY=pk\_test\_your\_key\_here

# GOOGLE\_MAPS\_API\_KEY=your\_google\_maps\_key

# BASE\_URL=https://your-api-domain.com

# ENVIRONMENT=development

# ```

# 

# > ⚠️ Never commit `.env` to version control. It is already listed in `.gitignore`.

# 

# For iOS, also add `GOOGLE\_MAPS\_API\_KEY` to `ios/Runner/AppDelegate.swift`.  

# For Android, add it to `android/app/src/main/AndroidManifest.xml`.

# 

# \---

# 

# \## Project Structure

# 

# ```

# lib/

# ├── core/

# │   ├── constants/          # App-wide constants (colors, strings, routes)

# │   ├── errors/             # Custom exception and failure classes

# │   ├── extensions/         # Dart extension methods

# │   └── utils/              # Helpers (validators, formatters, date utils)

# │

# ├── data/

# │   ├── models/             # Data models and JSON serialization

# │   ├── repositories/       # Data access layer (Firebase, REST)

# │   └── services/           # External service wrappers (Stripe, FCM)

# │

# ├── domain/

# │   ├── entities/           # Core business objects

# │   └── usecases/           # Business logic (one class per use case)

# │

# ├── presentation/

# │   ├── providers/          # Riverpod providers / BLoC classes

# │   ├── screens/            # Full-page UI screens

# │   │   ├── auth/

# │   │   ├── homeowner/

# │   │   ├── contractor/

# │   │   └── shared/

# │   └── widgets/            # Reusable UI components

# │

# ├── app.dart                # Root MaterialApp configuration

# └── main.dart               # Entry point

# ```

# 

# \---

# 

# \## Architecture

# 

# The app follows \*\*Clean Architecture\*\* principles separated into three layers:

# 

# ```

# Presentation  →  Domain  →  Data

# (Flutter UI)     (Use Cases)   (Firebase / APIs)

# ```

# 

# \- \*\*Presentation\*\* renders UI and reacts to state changes via Riverpod/BLoC

# \- \*\*Domain\*\* contains pure Dart business logic with no Flutter or Firebase dependencies

# \- \*\*Data\*\* handles all external communication and maps raw data to domain entities

# 

# This separation makes the codebase testable, scalable, and easy to swap out individual pieces (e.g. replacing Firebase with a REST backend).

# 

# \---

# 

# \## User Roles

# 

# The app supports two primary user roles, selected at registration:

# 

# | Role | Description |

# |---|---|

# | \*\*Homeowner\*\* | Posts jobs, hires contractors, makes payments |

# | \*\*Contractor\*\* | Offers services, submits quotes, receives payment |

# 

# Role-specific navigation and features are gated at the router level. Contractors must complete identity verification before becoming visible to homeowners.

# 

# \---

# 

# \## Screens \& Navigation

# 

# \### Auth Flow

# \- Splash / Onboarding

# \- Sign Up (role selection)

# \- Login

# \- Forgot Password

# \- Contractor Verification (license upload, identity check)

# 

# \### Homeowner Flow

# \- Home Dashboard (nearby contractors, active jobs)

# \- Post a Job

# \- Browse Contractors (filter by category, rating, distance)

# \- Contractor Profile

# \- My Jobs (open, in progress, completed)

# \- Messages

# \- Payments \& History

# \- Profile \& Settings

# 

# \### Contractor Flow

# \- Home Dashboard (new requests, upcoming bookings)

# \- Job Requests Feed

# \- My Quotes

# \- Calendar / Schedule

# \- Client Messages

# \- Earnings \& Payouts

# \- Profile \& Portfolio Editor

# 

# \---

# 

# \## API Integration

# 

# \### Firebase Services

# 

# | Service | Usage |

# |---|---|

# | Firebase Auth | Email/password and Google Sign-In |

# | Cloud Firestore | Users, jobs, quotes, reviews, messages |

# | Firebase Storage | Profile photos, job images, portfolio |

# | Cloud Functions | Payment processing, notifications, verification |

# | FCM | Push notifications |

# 

# \### Stripe

# 

# Payments are processed via Stripe Connect, allowing the platform to route funds from homeowners to contractors with an optional platform fee. Payment intents are created server-side via Firebase Cloud Functions.

# 

# \---

# 

# \## Running Tests

# 

# ```bash

# \# Unit and widget tests

# flutter test

# 

# \# Integration tests (requires connected device or emulator)

# flutter test integration\_test/

# 

# \# Test coverage report

# flutter test --coverage

# genhtml coverage/lcov.info -o coverage/html

# ```

# 

# Tests are organized under `test/` mirroring the `lib/` structure:

# \- `test/unit/` — domain logic and repository tests

# \- `test/widget/` — widget rendering tests

# \- `integration\_test/` — end-to-end user flow tests

# 

# \---

# 

# \## Building for Production

# 

# \### Android

# 

# ```bash

# \# Build APK

# flutter build apk --release

# 

# \# Build App Bundle (recommended for Play Store)

# flutter build appbundle --release

# ```

# 

# Output: `build/app/outputs/bundle/release/app-release.aab`

# 

# \### iOS

# 

# ```bash

# flutter build ios --release

# ```

# 

# Then archive and upload via Xcode or Fastlane.

# 

# \### Environment Flavors

# 

# The project supports `development`, `staging`, and `production` flavors:

# 

# ```bash

# flutter run --dart-define=ENVIRONMENT=staging

# flutter build apk --dart-define=ENVIRONMENT=production

# ```

# 

# \---

# 

# \## Contributing

# 

# Contributions are welcome! Please follow these steps:

# 

# 1\. Fork the repository

# 2\. Create a feature branch: `git checkout -b feature/your-feature-name`

# 3\. Commit your changes: `git commit -m 'feat: add some feature'`

# 4\. Push to the branch: `git push origin feature/your-feature-name`

# 5\. Open a Pull Request

# 

# Please follow the \[Conventional Commits](https://www.conventionalcommits.org/) standard for commit messages and ensure all tests pass before submitting a PR.

# 

# \### Code Style

# 

# This project uses `flutter\_lints`. Run the linter before committing:

# 

# ```bash

# flutter analyze

# dart format .

# ```

# 

# \---

# 

# \## License

# 

# Distributed under the MIT License. See `LICENSE` for more information.

# 

# \---

# 

# > Built with ❤️ using Flutter

