## 2025-02-28 - Secure Storage for OAuth Tokens
**Vulnerability:** OAuth access and ID tokens were being stored in plaintext using SharedPreferences in `AuthService`.
**Learning:** Flutter's SharedPreferences provides no encryption by default, making sensitive tokens vulnerable to extraction on rooted/jailbroken devices or physical access.
**Prevention:** Use `flutter_secure_storage` for storing all sensitive authentication tokens, keys, and credentials, instead of SharedPreferences.
