## 2025-05-16 - Prevent credential extraction in OAuth Flow
**Vulnerability:** OAuth access tokens are written to SharedPreferences in plaintext (`auth_service.dart`).
**Learning:** Tokens must be stored securely using `flutter_secure_storage` rather than SharedPreferences.
**Prevention:** Always use `flutter_secure_storage` or an equivalent secure storage mechanism when saving access tokens, keys, and passwords.
