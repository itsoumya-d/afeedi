## 2025-05-24 - Secure Storage for Tokens and Credentials
**Vulnerability:** OAuth tokens and user credentials are currently being stored in plaintext using SharedPreferences.
**Learning:** This exposes sensitive user authentication data if the device is compromised or during local file inspection.
**Prevention:** Always use `flutter_secure_storage` or encrypted storage alternatives for sensitive user credentials and OAuth tokens.
