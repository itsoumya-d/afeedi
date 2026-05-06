## 2026-05-06 - [Fix Unsalted Password Hashes]
**Vulnerability:** Passwords hashed in LocalAuthService using SHA-256 without a salt.
**Learning:** Legacy implementations often use bare hash functions which are susceptible to rainbow table and dictionary attacks.
**Prevention:** Always use a unique, random salt (e.g., using `math.Random.secure()`) for each hashed password.
