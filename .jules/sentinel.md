## 2024-06-20 - [Insecure Local Storage of Credentials]
**Vulnerability:** Sensitive data including hashed passwords and OAuth tokens were being stored in `SharedPreferences`, which is insecure and stores data in plain text.
**Learning:** The legacy fallback method provides backward compatibility when migrating data to `flutter_secure_storage`, ensuring users don't face sudden lockouts.
**Prevention:** Always use `flutter_secure_storage` or equivalent secure enclaves for caching credentials, access tokens, and sensitive authentication state.
