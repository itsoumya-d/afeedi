## 2024-05-24 - [Insecure Storage of OAuth Tokens]
**Vulnerability:** OAuth access and ID tokens are stored in plain text using `SharedPreferences`, which is insecure and vulnerable to extraction on rooted or jailbroken devices.
**Learning:** The application uses `SharedPreferences` instead of `flutter_secure_storage` for sensitive token persistence. When clearing secure storage, `deleteAll()` must be avoided as it clears all global secure data.
**Prevention:** Always use `flutter_secure_storage` for sensitive data like OAuth tokens. Clear specific keys by filtering `readAll()` instead of `deleteAll()`.
