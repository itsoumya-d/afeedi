## 2024-07-01 - [Plaintext Token Storage]
**Vulnerability:** OAuth access and ID tokens were stored in plaintext using SharedPreferences.
**Learning:** The application was improperly migrating token storage and failing to use platform-native encrypted storage for highly sensitive API keys/tokens.
**Prevention:** Always use secure enclaves/keystores (e.g., flutter_secure_storage) for authentication tokens, passwords, and sensitive API keys.