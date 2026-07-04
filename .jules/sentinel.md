## 2025-03-01 - [Insecure Local Storage for Credentials]
**Vulnerability:** User credentials (email and hashed passwords) were stored in plaintext using SharedPreferences in `LocalAuthService`.
**Learning:** SharedPreferences in Flutter relies on plaintext XML/JSON files that are easily accessible on a compromised device. Sensitive data like passwords must never be stored using SharedPreferences.
**Prevention:** Use `flutter_secure_storage` which utilizes platform-native secure enclaves (iOS Keychain, Android Keystore) for any sensitive data, especially credentials or OAuth tokens.
