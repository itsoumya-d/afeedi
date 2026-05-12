## 2024-05-12 - Fix Unsalted Password Hashing
**Vulnerability:** The `LocalAuthService` uses unsalted SHA-256 for hashing user passwords before storing them.
**Learning:** Using unsalted hashes makes passwords vulnerable to rainbow table attacks and dictionary attacks.
**Prevention:** Always use a secure salt along with the password before hashing it.
