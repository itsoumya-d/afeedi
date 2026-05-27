## 2024-05-27 - Insecure Storage of User Credentials
**Vulnerability:** User credentials (email and hashed passwords) were stored in `SharedPreferences`, which is insecure and not encrypted on disk. This poses a risk if a device is compromised, as plain text JSON data in SharedPreferences can be easily extracted.
**Learning:** Even if a password is hashed, it shouldn't be stored in insecure storage mechanisms like `SharedPreferences`. The app must use native secure storage mechanisms (Keychain on iOS, Keystore on Android).
**Prevention:** Always use `flutter_secure_storage` or equivalent secure APIs for storing sensitive information like authentication tokens, credentials, or personal user data.
