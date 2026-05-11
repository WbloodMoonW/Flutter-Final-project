# Angezny - Service Marketplace App

Angezny is a comprehensive service marketplace application built with Flutter, designed to connect clients with skilled service providers (workers). The platform facilitates seamless booking, real-time communication, and efficient service management.

## 🚀 Key Features

### For Clients
- **Explore Services**: Browse through various categories of professional services.
- **Worker Profiles**: View detailed worker profiles, ratings, and portfolios.
- **Booking System**: Schedule services with ease and manage bookings.
- **Real-time Chat**: Communicate directly with service providers.
- **Map Integration**: Pinpoint locations for service delivery.
- **Order Management**: Track the status of your service requests.
- **Promotions**: Apply coupons and discounts to bookings.

### For Workers
- **Worker Dashboard**: Track earnings, pending requests, and overall performance.
- **Service Management**: Create and manage the services you offer.
- **Wallet & Earnings**: Monitor your balance and transaction history.
- **Order Handling**: Accept, manage, and complete service requests.
- **Profile Customization**: Showcase your skills, licenses, and portfolio.
- **ID Verification**: Secure identity verification for professional trust.

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Provider
- **Networking**: Http
- **Storage**: Shared Preferences
- **Maps**: Flutter Map & LatLong2
- **Backend**: Node.js / MongoDB (REST API)
- **Localization**: Custom implementation for multi-language support.

## 📦 Project Structure

```text
lib/
├── core/           # Localization and core utilities
├── models/         # Data models (User, Worker, Service, etc.)
├── services/       # API, Storage, and Verification services
├── viewmodels/     # Business logic (Auth, Client, Worker)
└── views/          # UI Components and Pages
    ├── auth/       # Authentication screens
    ├── client/     # Client-specific pages
    └── worker/     # Worker-specific pages
```

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- An Android/iOS emulator or physical device

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/WbloodMoonW/Flutter-Final-project.git
   ```
2. **Navigate to the project directory**:
   ```bash
   cd Flutter-Final-project
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the app**:
   ```bash
   flutter run
   ```

## 🌍 Localization
The app supports multiple languages. Localization files are managed in `lib/core/localization.dart`.

## 🤝 Contributers
- Nour-Eldin Mahmoud Elbandy
- Fedaa Addean Fathi
  
## 📄 License
This project is licensed under the MIT License.
