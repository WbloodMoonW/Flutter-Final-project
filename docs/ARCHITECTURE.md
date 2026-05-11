# Angezny Architecture Overview

This document outlines the architectural pattern and project structure used in the Angezny Flutter application.

## Architectural Pattern: MVVM

Angezny follows the **Model-View-ViewModel (MVVM)** architectural pattern. This pattern separates the user interface (View) from the business logic and state (ViewModel) and the data representation (Model).

### Components of MVVM in Angezny:

1. **Model (`lib/models/`)**:
   - Represents the data and business objects of the application.
   - Examples: `UserModel`, `WorkerModel`, `ServiceModel`, `OrderModel`.
   - Models are responsible for parsing JSON data from the API into Dart objects (`fromJson`, `toMap` methods).

2. **ViewModel (`lib/viewmodels/`)**:
   - Acts as an intermediary between the View and the Model/Services.
   - Holds the state of the application for specific features.
   - Communicates with services to fetch or update data and then notifies the View of state changes.
   - Implemented using Flutter's `ChangeNotifier` and `Provider` package.
   - Key ViewModels:
     - `AuthViewModel`: Manages login, signup, and authentication state.
     - `ClientViewModel`: Manages data for the client-side app (categories, workers, orders).
     - `WorkerViewModel`: Manages data for the worker-side app (dashboard, wallet, service management).

3. **View (`lib/views/`)**:
   - The UI of the application, built using Flutter widgets.
   - Observes the ViewModel (using `Consumer` or `context.watch()`) and rebuilds when the state changes.
   - Views should contain minimal business logic, delegating user actions to the ViewModel.
   - Divided into `auth`, `client`, and `worker` subdirectories.

4. **Services (`lib/services/`)**:
   - Handles external communication, data persistence, and specialized tasks.
   - `ApiService`: Handles all HTTP REST calls to the backend Node.js server.
   - `StorageService`: Manages local storage using `shared_preferences` (e.g., storing auth tokens).
   - `IdVerificationService`: Handles specific tasks like ID verification uploads.

## State Management

The application uses the **Provider** package for state management and dependency injection.

- `MultiProvider` is initialized at the root of the app (`lib/main.dart`) to provide the ViewModels to the entire widget tree.
- Views use `Consumer<ViewModel>` to listen for changes and rebuild specific parts of the UI.
- ViewModels call `notifyListeners()` when their internal state changes, triggering updates in the UI.

## Directory Structure

```text
lib/
├── core/                   # Core utilities
│   └── localization.dart   # App Localization logic
├── models/                 # Data Models (Dart classes)
├── services/               # External services (API, Storage)
├── viewmodels/             # Business Logic & State Managers (ChangeNotifier)
└── views/                  # UI Layer (Screens & Widgets)
    ├── auth/               # Login, Signup, Verification views
    ├── client/             # Home, Profile, Services for Clients
    └── worker/             # Dashboard, Wallet, Profile for Workers
```

## Data Flow Example: Fetching Workers

1. **User Action**: The user navigates to a category page in the View (`lib/views/client/...`).
2. **View -> ViewModel**: The View calls a method on `ClientViewModel`, e.g., `fetchWorkersByCategory()`.
3. **ViewModel -> Service**: The `ClientViewModel` calls `ApiService.getWorkers(category: ...)`.
4. **Service**: `ApiService` makes an HTTP GET request to the backend.
5. **Model**: The JSON response is parsed into a list of `Worker` models.
6. **Service -> ViewModel**: `ApiService` returns the `List<Worker>` to the `ClientViewModel`.
7. **State Update**: The `ClientViewModel` updates its internal state (e.g., `_workersList = newWorkers`) and calls `notifyListeners()`.
8. **ViewModel -> View**: The View (which is wrapped in a `Consumer<ClientViewModel>`) detects the change and rebuilds to display the list of workers.
