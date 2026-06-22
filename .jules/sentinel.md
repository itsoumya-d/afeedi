## 2025-06-22 - [Secure Storage for Credentials and Tokens]
**Vulnerability:** The application was storing highly sensitive user credentials (hashed passwords) and OAuth access/id tokens in plaintext using `SharedPreferences`, which is insecure and vulnerable to data extraction on rooted/jailbroken devices.
**Learning:** `SharedPreferences` is not encrypted. Sensitive data like authentication credentials, OAuth tokens, or API keys must be securely encrypted at rest.
**Prevention:** Always use `flutter_secure_storage` instead of `SharedPreferences` when storing passwords, authentication tokens, API keys, and other sensitive materials. Implemented a migration fallback for existing data to prevent authentication lockouts for current users.
