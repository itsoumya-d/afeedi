## 2026-05-02 - Unsalted Password Hashes in LocalAuthService
**Vulnerability:** Passwords were hashed using SHA-256 without any salt in `LocalAuthService`, making them vulnerable to rainbow table attacks and dictionary attacks.
**Learning:** `LocalAuthService` fell back to a basic implementation lacking modern security standards (like salting) when bypassing Supabase for local authentication.
**Prevention:** Always use a randomly generated, unique salt for each user when hashing passwords, even in local or fallback authentication systems, and store the salt alongside the hashed credentials.
