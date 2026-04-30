## 2024-05-24 - Unsalted Password Hashing
**Vulnerability:** Passwords were being hashed using SHA-256 without a salt, leaving them vulnerable to rainbow table attacks.
**Learning:** The legacy implementation relied solely on simple hashing. Integrating a randomly generated salt per user ensures identical passwords yield unique hashes, with a fallback to empty salts for legacy users.
**Prevention:** Always use a randomly generated salt (e.g., via `dart:math` `Random.secure()`) when hashing passwords and store the salt alongside the hash.
