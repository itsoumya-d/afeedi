## 2025-06-05 - Insecure Storage of OAuth Tokens
**Vulnerability:** OAuth access and ID tokens were stored in plain text in SharedPreferences.
**Learning:** Plain text storage of sensitive tokens can be accessed if a device is compromised.
**Prevention:** Always use a secure storage solution like flutter_secure_storage to securely manage access tokens and sensitive credentials.
