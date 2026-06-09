## 2024-05-24 - Initial Sentinel Journal
**Vulnerability:** Initial creation
**Learning:** Setting up the journal
**Prevention:** Always check .jules/sentinel.md

## 2024-10-24 - Secure Storage for OAuth Tokens
**Vulnerability:** OAuth access and ID tokens were being stored in plaintext using SharedPreferences.
**Learning:** SharedPreferences data is not encrypted and can be accessed on rooted/jailbroken devices.
**Prevention:** Always use flutter_secure_storage or equivalent encrypted storage for sensitive data like tokens and credentials.
