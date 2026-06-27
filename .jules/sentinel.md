## 2024-06-27 - [Migrate Sensitive Data to Secure Storage]
**Vulnerability:** User credentials (email/hashed password) and OAuth tokens were being stored in plaintext using SharedPreferences.
**Learning:** Storing sensitive data like hashed passwords and authentication tokens in SharedPreferences exposes them to potential local extraction.
**Prevention:** Always use secure storage mechanisms (e.g., flutter_secure_storage) for sensitive authentication credentials and tokens, with a backward-compatible migration path if necessary.
