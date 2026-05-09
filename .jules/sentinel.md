## 2024-05-15 - Implement Password Salting
**Vulnerability:** Passwords were hashed using SHA-256 without a salt, making them vulnerable to rainbow table attacks and dictionary attacks.
**Learning:** `LocalAuthService` implemented authentication by hashing passwords with SHA-256 but omitted adding a unique salt for each user, which is a critical security vulnerability for stored credentials.
**Prevention:** Always use a cryptographically secure random salt (e.g., via `dart:math` `Random.secure()`) when hashing passwords, and store the salt alongside the hashed password for verification.
