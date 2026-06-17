## 2024-06-17 - [Migrate OAuth Tokens to Secure Storage]
**Vulnerability:** The `AuthService` stores sensitive OAuth access and ID tokens using `SharedPreferences`, which stores data in plaintext on Android and in standard `NSUserDefaults` on iOS, making it vulnerable to extraction.
**Learning:** `SharedPreferences` is explicitly not designed for secure storage and must never be used for tokens, passwords, or PII.
**Prevention:** Always use `flutter_secure_storage` or a platform-equivalent secure enclave for sensitive tokens and credentials from the beginning.
