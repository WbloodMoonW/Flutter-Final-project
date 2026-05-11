# Angezny API Documentation

This document outlines how the Flutter application interacts with the backend server via the `ApiService`.

## Base Configuration

- **Base URL**: `https://angezny.onrender.com/api`
- **Service Class**: `lib/services/api_service.dart`
- **Timeout**: Most requests have a standard timeout of 15-30 seconds, with some heavy requests (like auth and fetching all categories/workers) extended to 100 seconds.

## Authentication Flow

The application uses JSON Web Tokens (JWT) for authentication.

1. **Login/Signup**: The user authenticates via `ApiService.signin`, `ApiService.signup`, `ApiService.googleSignin`, or `ApiService.facebookSignin`.
2. **Token Storage**: On success, the JWT is returned in the `token` field and saved locally using `StorageService.saveToken()`. Multi-account support is also managed here.
3. **Authorized Requests**: Subsequent requests that require authentication retrieve the token via `StorageService.getToken()` and include it in the `Authorization` header as `Bearer $token`.
4. **Roles**: The backend returns a `role` ('customer' or 'worker') which determines the UI routing upon successful login.

## Error Handling

`ApiService` includes a central `_handleError` method. It maps common network errors (like `SocketException` or `Connection failed`) to a localized "server_offline" message, providing a more user-friendly error experience.

## Key Endpoint Groups

Below are the primary groups of endpoints managed by the `ApiService`.

### Authentication (`/auth`)
- `POST /auth/signin`: Standard email/password login.
- `POST /auth/signup`: Create a new user account (customer or worker).
- `POST /auth/google`, `POST /auth/facebook`: Social login integration.
- `GET /auth/me`: Fetch the current user's profile based on the token.
- `POST /auth/verify-email`: Validate email verification code.
- `PATCH /auth/switch-role`: Allows a user to switch their role within the platform.

### Worker Endpoints (`/worker`)
- `GET /worker/dashboard`: Retrieve stats and overview for the worker's home screen.
- `GET /worker/orders`: Fetch service requests (bookings) assigned to the worker.
- `PUT /worker/orders/:id/status`: Accept, decline, or complete an order.
- `GET /worker/services`: Fetch services created by the worker.
- `POST /worker/services`: Create a new service offering.
- `GET /worker/wallet`: Retrieve earnings and transaction history.
- `PUT /worker/profile`: Update worker profile information.

### Client/Customer Endpoints (`/customer`)
- `GET /customer/profile`: Fetch the client's profile details.
- `GET /customer/orders`: Retrieve the client's booking history.
- `POST /customer/orders`: Create a new booking request for a worker/service.
- `POST /customer/addresses`: Add a new location/address for the client.

### Public/Marketplace Endpoints
- `GET /categories`: Fetch all available service categories.
- `GET /workers`: Fetch a paginated list of workers, optionally filtered by category or search query.
- `GET /workers/:id`: Fetch detailed profile for a specific worker.
- `GET /search/suggest`: Get search suggestions based on user input.

### Chat System (`/chat`)
- `GET /chat/conversations`: Retrieve the user's active chat sessions.
- `GET /chat/conversations/:id/messages`: Fetch the message history for a specific conversation.
- `POST /chat/conversations`: Find an existing or create a new conversation with a specific user ID.
- `POST /chat/conversations/:id/messages`: Send a text message to a conversation.
