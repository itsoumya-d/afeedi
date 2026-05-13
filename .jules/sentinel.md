## 2024-05-13 - Implement Backward-Compatible Password Salting
**Vulnerability:** Passwords were conventionally hashed using SHA-256 without a salt, leaving them vulnerable to rainbow table attacks.
**Learning:** Legacy systems often pose challenges when upgrading security mechanisms because old credentials will fail validation. The system can handle this by using a default fallback (like an empty string) when a salt is missing.
**Prevention:** Always salt hashes securely and proactively design migration paths for legacy credentials.
