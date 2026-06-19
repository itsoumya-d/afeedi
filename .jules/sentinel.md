## 2024-05-18 - [Insecure OAuth Token Storage]
**Vulnerability:** OAuth access and ID tokens were stored in plaintext using SharedPreferences, which is not secure for sensitive credentials.
**Learning:** Always use a secure storage mechanism (like flutter_secure_storage) for sensitive information like OAuth tokens to prevent unauthorized access if the device is compromised.
**Prevention:** Ensure that any future implementations involving authentication tokens or sensitive user data utilize secure storage solutions by default.
