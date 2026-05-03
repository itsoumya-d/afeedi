## 2025-02-27 - [Fix Unsalted Password Hashing]
**Vulnerability:** Passwords were being stored as plain SHA-256 hashes without any salt in LocalAuthService, making them vulnerable to rainbow table attacks.
**Learning:** The initial local storage implementation for authentication (LocalAuthService) prioritized functionality but missed the critical security best practice of salting hashes.
**Prevention:** Always combine passwords with a cryptographically secure random salt before hashing. Include the salt alongside the stored hash for future verification.
