## 2024-05-24 - Migrate Credentials to Secure Storage
**Vulnerability:** Hashed credentials were saved in `SharedPreferences`, which stores data in plaintext XML/plists, making them vulnerable to extraction on rooted/compromised devices.
**Learning:** Even hashed authentication data should be stored securely using platform keychains or secure storage solutions like `flutter_secure_storage`.
**Prevention:** Always use `flutter_secure_storage` or similar secure methods to store authentication tokens, hashed passwords, or sensitive credentials, avoiding `SharedPreferences` for sensitive data.