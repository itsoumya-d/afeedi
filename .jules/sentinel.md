## 2026-06-02 - Secure Credential Storage
**Vulnerability:** Insecure storage of user credentials and OAuth tokens in SharedPreferences.
**Learning:** SharedPreferences stores data in plaintext, exposing sensitive auth tokens and password hashes on rooted/jailbroken devices or via backups.
**Prevention:** Use flutter_secure_storage for all sensitive authentication data, which uses KeyStore (Android) and Keychain (iOS).
