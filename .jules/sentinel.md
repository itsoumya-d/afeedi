## 2024-05-20 - [Insecure Storage of OAuth Tokens]
**Vulnerability:** OAuth access and ID tokens were stored in plain text using SharedPreferences in AuthService.
**Learning:** SharedPreferences writes data in plain text. Sensitive data such as tokens and credentials must be stored securely to prevent extraction.
**Prevention:** Always use flutter_secure_storage to securely store sensitive information like OAuth tokens on the device.
