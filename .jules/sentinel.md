## 2024-05-18 - [Fix Plaintext Password Storage]
**Vulnerability:** User credentials (email and password) were being stored as plaintext JSON in `SharedPreferences` within `local_auth_service.dart`.
**Learning:** `SharedPreferences` stores data persistently in an unencrypted format on the device, meaning any attacker with device access or other apps with read permissions could potentially access user passwords. Even though passwords were "hashed" before storing, saving them in insecure storage is a major vulnerability pattern to avoid.
**Prevention:** Always use `flutter_secure_storage` for sensitive data like tokens, credentials, and passwords to ensure platform-specific encryption (e.g., Keystore on Android, Keychain on iOS) is used.
