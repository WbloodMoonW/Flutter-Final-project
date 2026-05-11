# Developer Guide

Welcome to the Angezny developer guide! This document outlines the best practices, coding conventions, and workflow for contributing to the application.

## Coding Conventions

1. **Dart Standards**: Follow standard Dart conventions. Use `camelCase` for variables and methods, and `PascalCase` for classes.
2. **Widget Splitting**: If a View (Screen) becomes too large, split it into smaller, reusable widget classes within the same file or in a `components` sub-folder.
3. **State Management**: 
   - Use `Provider` and `ChangeNotifier` (`ViewModel`) for business logic and app state.
   - Avoid using `setState()` for complex logic. Use it only for ephemeral, UI-only state (e.g., toggling a local animation, expanding a local panel).
4. **Localization**: Never hardcode strings in the UI. Always use `AppLocalization.translate('your_key')`.

## Adding a New Feature

To add a new feature (e.g., a "Favorites" page), follow this MVVM workflow:

### Step 1: Model
If the feature introduces new data, create a new model class in `lib/models/`.
- Ensure it has `fromJson` and `toMap` methods for API serialization.

### Step 2: Service Layer
Add the necessary API calls to `lib/services/api_service.dart`.
- Handle errors gracefully and map them to localized strings if needed.

### Step 3: ViewModel
Update an existing ViewModel or create a new one in `lib/viewmodels/`.
- Create private variables for the state (e.g., `List<Worker> _favorites = [];`).
- Create getters to access the state.
- Create methods to interact with the `ApiService`, update the state, and call `notifyListeners()`.

### Step 4: View
Create the UI in `lib/views/`.
- Wrap the main part of your UI that needs data with a `Consumer<YourViewModel>`.
- Use the getters from the ViewModel to display data.
- Bind user actions (buttons, pulls) to the methods in your ViewModel.

## Localization Workflow

1. Open `lib/core/localization.dart`.
2. Locate the maps for supported languages (e.g., `_en` for English, `_ar` for Arabic).
3. Add your new key-value pair to **all** language maps.
   ```dart
   // In English map
   'my_new_feature': 'My New Feature',
   
   // In Arabic map
   'my_new_feature': 'ميزتي الجديدة',
   ```
4. Use it in the UI: `AppLocalization.translate('my_new_feature')`.

## Troubleshooting Common Issues

- **ProviderNotFoundException**: You tried to access a ViewModel using `context.read()` or `Consumer` in a widget tree where the `Provider` hasn't been instantiated above it. Ensure `MultiProvider` in `main.dart` includes your ViewModel.
- **UI not updating**: Ensure you are calling `notifyListeners()` in your ViewModel after the state changes.
- **API CORS/Connection Issues on Emulator**: If testing on an Android emulator against a local backend, `localhost` points to the emulator itself. Use `10.0.2.2` instead of `localhost` or `127.0.0.1` in the `ApiService` base URL.
