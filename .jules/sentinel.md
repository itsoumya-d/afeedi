## 2025-02-23 - [Migrate OAuth Tokens to Secure Storage]
**Vulnerability:** OAuth tokens were being stored in plaintext using SharedPreferences, which could allow unauthorized access if the device is compromised.
**Learning:** Storing sensitive data like access tokens and ID tokens should always be done in an encrypted format using secure storage mechanisms.
**Prevention:** Always use secure storage libraries (like `flutter_secure_storage`) instead of `SharedPreferences` when storing authentication tokens, passwords, or PII.