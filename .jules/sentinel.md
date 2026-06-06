## 2024-06-06 - Insecure Storage of User Credentials
**Vulnerability:** LocalAuthService stored hashed passwords and user credentials insecurely using SharedPreferences.
**Learning:** SharedPreferences should not be used to store sensitive data like user credentials, even if passwords are hashed.
**Prevention:** Always use flutter_secure_storage for saving authentication credentials, access tokens, and passwords in Flutter applications.
