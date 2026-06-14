## 2024-06-14 - [Migrate Sensitive Tokens to Secure Storage]
**Vulnerability:** OAuth access and ID tokens are stored in plain text using SharedPreferences in AuthService.
**Learning:** Storing sensitive access tokens in SharedPreferences allows other apps (on rooted/jailbroken devices) or attackers with physical access to potentially extract them.
**Prevention:** Always use a secure storage mechanism like flutter_secure_storage for sensitive data like tokens, passwords, and PII.
