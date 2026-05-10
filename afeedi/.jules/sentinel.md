## 2024-05-14 - Fix unsalted password hashes
**Vulnerability:** Passwords in `LocalAuthService` were hashed using SHA-256 without a cryptographic salt, leaving them vulnerable to rainbow table attacks and dictionary attacks if the local storage (`SharedPreferences`) was compromised.
**Learning:** Legacy authentication systems in flutter apps might use simple hashes. When managing local credentials, relying solely on SHA-256 without a salt is insecure as it produces deterministic output.
**Prevention:** Always generate a unique cryptographic salt (e.g., using `dart:math`'s `Random.secure()`) for each user during sign up, append/prepend the salt to the password before hashing, and store the salt alongside the hashed password for verification.
