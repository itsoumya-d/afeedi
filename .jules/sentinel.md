## 2024-06-13 - [OAuth Token Insecure Storage]
**Vulnerability:** OAuth access and ID tokens were stored in plain text using SharedPreferences in `auth_service.dart`.
**Learning:** Using SharedPreferences exposes sensitive tokens directly.
**Prevention:** Always use `flutter_secure_storage` for credentials and authentication tokens.
