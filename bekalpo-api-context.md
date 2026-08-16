# Bekalpo API — Route Context (routes/api.php)

Reference context for implementing/modifying endpoints in this file. Read this before touching any route below — it captures conventions, quirks, and gotchas that aren't obvious from the code alone.

## Stack & conventions
- Laravel API, auth guard is `auth:api` — **Laravel Passport**, Bearer token.
- Protected routes are wrapped in `Route::middleware('auth:api')->group(...)`. Some public routes sit inside otherwise-protected prefixes (e.g. `profile/username/{username}` and `phones` block is fully protected but note the commented-out legacy `phones` group above it used different method names).
- Base prefix is `/api` (this file is `routes/api.php`, prefix applied by Laravel's RouteServiceProvider).
- Realtime: Laravel Reverb (Pusher-protocol WebSockets). `/broadcasting/auth` bridges the Passport bearer token into Laravel's default session-based broadcasting auth via `auth()->setUser(auth('api')->user())` before calling `Broadcast::auth()`. Any change to auth here has to preserve that bridge or private/presence channels break.
- Presence/status: Redis TTL-based hybrid heartbeat, `MessageSent` / `UserStatusUpdated` events. `GET /users/status` is a bulk, unauthenticated status check — don't add auth to it without checking frontend usage first.

## Known quirks / tech debt (don't "fix" silently — ask first)
- `PostController::ststusSold` / `ststusTrash` — typo in method names (`ststus` instead of `status`), routes are `posts/status/sold/{post}` and `posts/status/trash/{post}`. Renaming the methods is a breaking change unless done as a proper refactor with the route still working.
- `Route::name(name: 'postFields')` uses named-argument syntax inconsistently vs. every other `->name('x')` call in the file — harmless but flag if doing a style pass.
- Legacy `phones` prefix group is commented out entirely (old REST verbs/paths). The **active** implementation below it uses different controller method names (`index`, `store`, `destroy`, `setPrimary`, `cancelPending`, `checkPhone`, `otpPhone`, `verifyPhone`) — do not resurrect the commented block.
- `phones/otp` route comment says `// POST /phones/check` (copy-paste leftover) — actual path is `/phones/otp`, calls `ContactController::otpPhone`.
- `GET /send/message` has **no auth middleware** and takes `message`/`to` via query string on a GET request — looks like a leftover debug/test route for the broadcast event. Confirm with the user before removing or exposing this in any public docs; likely should not ship to production untouched.
- Several controllers (`CategoryController`, `BrandController`, `ModelController`) expose `/upload` endpoints with no visible auth middleware in this file — verify whether auth is enforced inside the controller/policy before assuming these are open write endpoints.

## Auth flows (two parallel identity paths)
**Email flow:** `POST /auth/email` (existence check) → `POST /auth/signup/email` → `POST /auth/verify/email` (OTP) → `POST /auth/signin/email` → `POST /auth/set/password/email`.

**Phone flow:** `POST /auth/phone` (Step 1: check) → `POST /auth/signup/phone` (Step 2) → `POST /auth/verify/phone` (Step 3: OTP) → `POST /auth/signin/phone` (Step 4) → `POST /auth/set/password/phone`. Comments in the source explicitly number these steps — preserve that numbering/order if refactoring.

**Social:** `POST /auth/signin/google` (expects an id_token, not yet inspected here — check `AuthController::signinWithGoogle` for the exact payload shape).

**OTP (shared by both flows):** `POST /auth/send/otp`, `POST /auth/resend/otp`.

## Route groups (for orientation)

| Group | Auth | Controller(s) |
|---|---|---|
| Metadata/lookups (locations, categories, brands, models, divisions, districts, thanas) | No | `LocationController`, `CategoryController`, `BrandController`, `ModelController`, `DivisionController`, `DistrictController`, `ThanaController` |
| Bulk image uploads (`category/upload`, `brand/upload`, `model/upload`) | Unclear — check controller | same as above |
| Contact form | No | `ContactController::contactForm` |
| Posts — public (list/search/rate/click/view/sold/trash) | No | `PostController`, `PostClickController`, `PostViewController`, `RatingController` |
| Posts — authenticated (fields/init/store/edit/update/image upload+reorder) | Yes | `PostController`, `PostFieldController` |
| Wishlists | No | `WishListController` |
| Auth (email/phone/google/otp) | No | `AuthController` |
| Profile | Yes (except `profile/username/{username}` check) | `ProfileController` |
| Phones (secondary numbers) | Yes | `ContactController` |
| Broadcasting auth | Yes | inline closure |
| Status & messaging (presence, chat, unread counts) | Yes (except `users/status`) | `StatusController`, `MessageController` |
| Model cache clear | No | `CacheController::clear` |

## Models implied by routes (not exhaustive — verify against actual schema)
Post, Category, Brand, Model (vehicle/product model, separate from Eloquent "Model"), Division, District, Thana, Location, User, Contact/Phone, WishList, Conversation, Message, Rating.

## What this file does NOT tell you
- Request validation rules (FormRequest classes, if any) — not visible here, check each controller method.
- Response shapes / Resource classes — not visible here.
- Whether `category/upload`, `brand/upload`, `model/upload` are single-image or bulk CSV imports — name suggests image upload but verify.
- Rate limiting / throttle middleware — none is visible in this file; if it exists it's applied elsewhere (e.g. `RouteServiceProvider` or Sanctum/Passport config).

## Companion artifact
A Postman collection (`bekalpo-api.postman_collection.json`) was generated alongside this doc, mirroring these same groups 1:1, with `{{base_url}}` and `{{auth_token}}` collection variables. Use it for manual endpoint verification; use this doc for implementation/refactor context.
