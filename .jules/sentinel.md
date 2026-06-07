## 2024-05-24 - Secure Storage Migration
**Vulnerability:** User credentials (password hashes) and OAuth tokens were being stored in SharedPreferences, which writes to unencrypted XML files on Android and standard UserDefaults on iOS, exposing sensitive authentication data.
**Learning:** When migrating from SharedPreferences to flutter_secure_storage for existing apps, a backward compatibility fallback must be implemented during reads to seamlessly migrate existing user sessions without logging them out.
**Prevention:** Always use flutter_secure_storage or encrypted equivalents for credentials, API keys, and OAuth tokens by default. Set up linters or commit hooks to flag SharedPreferences usage when the keys contain "token", "password", or "credential".
