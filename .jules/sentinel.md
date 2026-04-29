## 2024-04-29 - Unsalted Password Hashing Vulnerability
**Vulnerability:** The application was hashing passwords using SHA-256 without a salt in `LocalAuthService`.
**Learning:** This architectural flaw existed because basic hashing was implemented without prioritizing defense against rainbow table attacks or identical password recognition. Unsalted hashes mean identical passwords result in the same hash, increasing the risk of bulk decryption.
**Prevention:** Always append a cryptographically secure, randomly generated salt to passwords before hashing them. The salt should be unique to each user and stored alongside the hashed password. Fallbacks must be maintained for existing legacy accounts that were hashed without a salt.
