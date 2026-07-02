## 2024-07-02 - Secure Token Storage for Streaming
**Vulnerability:** Access tokens for social media streams were not stored securely (TODO comment indicating manual setup).
**Learning:** Hardcoded or missing token storage patterns require explicit integration with a secure local storage solution like `flutter_secure_storage`.
**Prevention:** Always integrate secure storage modules when handling OAuth or third-party API tokens to prevent leakage and ensure persistent secure access.
