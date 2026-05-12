# Angezny Mobile (Flutter) — Reference Doc

Use this doc to bring a new chat up to speed on the mobile app. Backend lives at `c:\Angezny\Angezny\back-end` (Node/Express + MongoDB + Socket.IO). Production API: `https://angezny.onrender.com/api`.

---

## Project layout

```
Mobile/Flutter-Final-project/
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── core/localization.dart
    ├── models/                     # Plain Dart data classes
    │   ├── chat_models.dart        # Conversation, ChatMessage
    │   ├── service_model.dart      # WorkerService (id is String?)
    │   ├── worker_model.dart, user_model.dart, order_model.dart …
    ├── services/
    │   ├── api_service.dart        # ALL HTTP calls (static methods)
    │   ├── socket_service.dart     # Socket.IO singleton (auth via JWT)
    │   └── storage_service.dart    # SharedPreferences token storage
    ├── viewmodels/                 # ChangeNotifier state
    │   ├── auth_viewmodel.dart
    │   ├── client_viewmodel.dart
    │   └── worker_viewmodel.dart
    └── views/
        ├── auth/, client/, worker/
```

## Tech / Dependencies

- `http` — REST calls
- `socket_io_client: ^2.0.3` — Real-time chat
- `provider` — State management
- `shared_preferences` — Token persistence (key: `auth_token`; multi-account list: `accounts_list`)
- `image_picker`, `flutter_map`, `latlong2`, `google_fonts`, `font_awesome_flutter`

## Auth

- JWT in `Authorization: Bearer <token>` header for protected routes.
- Token saved to `SharedPreferences` via `StorageService` after `signin`/`signup`.
- Multi-account: `AuthViewModel.switchAccount(index)` swaps the active token.
- Role is set at signup (`customer`/`worker`) and **cannot be changed afterwards** — backend has no role-switch endpoint.

## Real-time chat (Socket.IO)

- Server URL (no `/api` suffix): `https://angezny.onrender.com`
- Auth: JWT passed in handshake `auth: {token}`.
- Events:
  - **emit** `chat:join` `{conversationId}` — join room
  - **emit** `chat:send` `{conversationId, message, messageType:'text'}` — send msg
  - **emit** `chat:read` `{conversationId}` — mark as read (called on dispose)
  - **on** `chat:message` — incoming message (filter out own senderId to avoid dupes)
  - **on** `ai:stream` — AI token stream (append to last AI message)
- There is **no HTTP POST** for sending messages — only `GET /chat/conversations/:id/messages` for history.

## API endpoint cheat sheet (verified against backend)

| Mobile call | Method + path | Notes |
|---|---|---|
| `ApiService.signup` | `POST /auth/signup` | Body **must** have `firstName` + `lastName` (separate), not `name` |
| `ApiService.signin` | `POST /auth/signin` | `{email \| phone, password}` |
| `ApiService.googleSignin` | `POST /auth/google` | `{idToken}` (also accepts `accessToken`) |
| `ApiService.facebookSignin` | `POST /auth/facebook` | `{accessToken}` |
| `ApiService.getMe` | `GET /auth/me` | |
| `ApiService.verifyEmail` | `POST /auth/verify-email` | `{email, code}` |
| `ApiService.resendVerificationCode` | `POST /auth/resend-verification-code` | Empty body; email derived from token |
| `ApiService.forgotPassword` | `POST /auth/forgot-password` | `{email}` |
| `ApiService.resetPassword` | `POST /auth/reset-password` | `{token, newPassword}` |
| `ApiService.getCategories` | `GET /categories` | Public |
| `ApiService.searchWorkers` | `GET /workers` | Query: `category, search, lat, lng, postcode, limit` |
| `ApiService.getWorkerById` | `GET /workers/:id` | |
| `ApiService.getServiceById` | `GET /workers/service/:serviceId` | |
| `ApiService.getCustomerProfile` | `GET /customer/profile` | |
| `ApiService.updateCustomerProfile` | `PUT /customer/profile` | |
| `ApiService.getMyOrders` | `GET /customer/orders` | |
| `ApiService.createBooking` | `POST /customer/orders` | **Required** `serviceId`, `scheduledDate`, `address`. No `workerId` |
| `ApiService.addAddress` | `POST /customer/addresses` | |
| `ApiService.getWorkerDashboard` | `GET /worker/dashboard` | Returns `{profile, stats}` — licenses live in `profile.licenses` |
| `ApiService.getWorkerOrders` | `GET /worker/orders` | |
| `ApiService.getWorkerWallet` | `GET /worker/wallet` | |
| `ApiService.getWorkerLicenses` | (delegates to dashboard) | **No** `GET /worker/licenses` exists |
| `ApiService.addLicense` | `POST /worker/licenses` | |
| `ApiService.getWorkerServices` | `GET /worker/services` | |
| `ApiService.createWorkerService` | `POST /worker/services` | |
| `ApiService.updateWorkerService` | `PUT /worker/services/:id` | |
| `ApiService.deleteWorkerService` | `DELETE /worker/services/:id` | |
| `ApiService.updateOrderStatus` (worker) | `PUT /worker/orders/:id/status` | |
| `ApiService.updateWorkerLocation` | `PUT /workers/me/location` | Note: plural `workers` |
| `ApiService.findOrCreateConversation` | `POST /chat/conversations` | `{otherUserId}` → server returns `{conversation:{_id, otherUser, lastMessage(string), lastMessageAt, unreadCount, serviceContextId}}` |
| `ApiService.getMessages` | `GET /chat/conversations/:id/messages` | |
| `ApiService.sendMessage` | Socket.IO `chat:send` | NOT HTTP. Optimistic local update + server echo |
| `ApiService.getConversations` | `GET /chat/conversations` | |
| `ApiService.validateCoupon` | `POST /coupons/validate` | `{code}` |
| `ApiService.switchRole` | (throws) | No backend endpoint exists |

## Response-shape gotchas

- `lastMessage` in `Conversation` JSON arrives as a **String** (just the message text) — `Conversation.fromJson` handles both String and Map.
- Conversation response has `otherUser` instead of full `participants` array — model falls back to that.
- `ChatMessage` text comes from `message` field (backend), not `text`.
- Worker dashboard sometimes wraps payload in `data` — viewmodel does `dashboardData['data'] ?? dashboardData`.
- ID fields: backend returns `_id`, sometimes `id`, sometimes `{ '$oid': '...' }`. `ChatMessage.fromJson` and `Conversation.fromJson` handle this.

## Recently fixed bugs (May 2026)

1. **Signup** — was sending `name`; backend requires `firstName` + `lastName` separately. ([api_service.dart](lib/services/api_service.dart) — `signup`)
2. **Chat send** — was POSTing to a nonexistent `/chat/conversations/:id/messages`; now uses Socket.IO `chat:send`. ([socket_service.dart](lib/services/socket_service.dart), [chat_page.dart](lib/views/client/chat_page.dart))
3. **`ChatMessage` text** — was reading `json['text']`; backend uses `message`.
4. **`Conversation.fromJson`** — was crashing because `lastMessage` is a String, not a Map; now handles both shapes and falls back from `participants` to `otherUser`.
5. **Worker licenses** — `GET /worker/licenses` doesn't exist. Licenses are extracted from `dashboard.profile.licenses` in `WorkerViewModel.loadWorkerData()`.
6. **switchRole** — endpoint doesn't exist; function now throws a localized "not supported" error instantly.
7. **createBooking** — `serviceId` is now a required named param (was optional); `workerId` removed from body (backend derives worker from service).
8. **Stats row overflow** in `worker_profile_page.dart:385` — wrapped each stat in `Expanded` + ellipsis on long location strings.

## Known remaining issues / things to watch

- **Hardcoded base URL** in [api_service.dart](lib/services/api_service.dart) — no env config. Change `_baseUrl` for staging/local.
- **Hardcoded server URL** in [socket_service.dart](lib/services/socket_service.dart) — same URL minus `/api`.
- **ID verification** in `id_verification_service.dart` is a stub that always succeeds after 800ms.
- **Order completion images** — currently a hardcoded Cloudinary sample URL; should capture real photos.
- **Token storage is plain text** in `SharedPreferences` (no encryption, no refresh, no expiry check).
- **No retry logic** on any HTTP call. Most failures silently return empty lists/null.
- **Worker profile update** sends duplicate keys (`typeOfWorker` + `typeofWorker`, `title` + `profession`, `location` + `address`) — defensive but harmless; backend uses one canonical field.
- **Flutter SDK installation** at `C:\flutter_windows_3.38.2-stable\flutter` had a corrupt git index — fix with `git reset --hard HEAD` inside that directory if `flutter pub get` ever fails again.

## How to run

```powershell
cd c:\Angezny\Angezny\Mobile\Flutter-Final-project
flutter pub get
flutter run            # then choose Windows / Chrome / Edge
```

Press `r` for hot-reload, `R` for hot-restart, `q` to quit.

## Backend reference (for context)

- Stack: Node + Express v5, MongoDB (Mongoose), Socket.IO, Paymob (payments), Groq (AI chat).
- JWT secret in `back-end/.env` (`JWT_SECRET`), 7-day expiry.
- CORS: `*` (permissive).
- Rate limits: auth 10/15min, email 5/15min, support tickets 15/hr per IP.
- Models: `User`, `WorkerProfile`, `CustomerProfile`, `WorkerServices`, `ServiceRequest`, `Payment`, `WalletTransaction`, `Conversation`, `LiveChat`, `Review`, `Coupon`, `Notification`, `Ticket`, `Report`, `ProviderApplication`, `Category`.

Source of truth for endpoints: `back-end/routes/*.js` + `back-end/controllers/*.js`. When in doubt, read those before assuming a contract.
