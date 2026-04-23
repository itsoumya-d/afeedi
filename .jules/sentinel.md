## 2024-05-24 - Secure Credential Storage in LocalAuthService
**Vulnerability:** User credentials (email and SHA-256 hashed password) were being saved in plaintext to SharedPreferences in LocalAuthService.
**Learning:** Even if passwords are hashed before storing, saving them directly in SharedPreferences makes them vulnerable to unauthorized reading by rooted devices, malicious applications with specific permissions, or during device backups.
**Prevention:** Always use secure storage mechanisms like flutter_secure_storage for sensitive data like credentials or API keys. Do not rely on SharedPreferences for storing secrets.
