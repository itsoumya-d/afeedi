## 2024-05-05 - Fix unsalted password hashing
**Vulnerability:** Passwords were saved using SHA-256 without a salt. This is a critical vulnerability that allows dictionary and rainbow table attacks.
**Learning:** `LocalAuthService` handled basic hashing securely using SHA-256, but missed the addition of salts before hashing, resulting in identical hashes for identical passwords.
**Prevention:** Implement a standard salting mechanism, typically utilizing cryptographically secure pseudorandom number generators (`Random.secure()`) to append a unique salt per user password during signup, and save this alongside the hash for future verifications.
