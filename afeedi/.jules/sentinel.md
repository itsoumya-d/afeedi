## 2024-05-24 - Unsalted Password Hashing
**Vulnerability:** Passwords hashed using plain SHA-256 without a salt.
**Learning:** Using unsalted hashes leaves credentials vulnerable to rainbow table attacks.
**Prevention:** Always use a strong, unique, and randomly generated salt using `Random.secure()` alongside cryptographic hashing for storing passwords, and ensure backward compatibility for migrating legacy passwords securely.
