## 2024-07-05 - [Secure OAuth Tokens Storage]
**Vulnerability:** OAuth access and ID tokens were being stored using insecure `SharedPreferences`.
**Learning:** Sensitive access tokens should not be stored in plaintext. While `SharedPreferences` is sufficient for non-sensitive data, it doesn't provide encryption for secrets like OAuth tokens.
**Prevention:** Use a secure storage mechanism, such as `flutter_secure_storage`, for storing any sensitive tokens or credentials in Flutter applications.
