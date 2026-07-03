## 2024-05-02 - High Severity: Insecure Storage of OAuth Tokens

**Vulnerability:** OAuth access and ID tokens were being stored in plaintext using SharedPreferences, which provides no encryption.
**Learning:** Using SharedPreferences for sensitive data exposes credentials on rooted or compromised devices, violating secure storage principles.
**Prevention:** Always use secure storage libraries, like flutter_secure_storage, to encrypt and store sensitive tokens, keys, and passwords.
