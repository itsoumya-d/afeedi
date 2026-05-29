import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  // Google Sign-In (for authentication)
  static Future<Map<String, dynamic>?> connectGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return {
          'platform': 'google',
          'accessToken': auth.accessToken,
          'idToken': auth.idToken,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'id': account.id,
          'connected_at': DateTime.now().toIso8601String(),
        };
      }
    } catch (error) {
      debugPrint('Google OAuth Error: $error');
    }
    return null;
  }

  // YouTube OAuth (uses Google Sign-In)
  static Future<Map<String, dynamic>?> connectYouTube() async {
    try {
      final result = await connectGoogle();
      if (result != null) {
        return {
          ...result,
          'platform': 'youtube',
        };
      }
    } catch (error) {
      debugPrint('YouTube OAuth Error: $error');
    }
    return null;
  }

  // Instagram OAuth (using Facebook Auth)
  static Future<Map<String, dynamic>?> connectInstagram() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['instagram_basic', 'instagram_content_publish'],
      );
      
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture",
        );
        return {
          'platform': 'instagram',
          'accessToken': result.accessToken?.token,
          'userId': result.accessToken?.userId,
          'userData': userData,
        };
      }
    } catch (error) {
      debugPrint('Instagram OAuth Error: $error');
    }
    return null;
  }

  // TikTok OAuth (using Web Auth)
  static Future<Map<String, dynamic>?> connectTikTok() async {
    try {
      // Simulate OAuth flow with mock data for development
      await Future.delayed(const Duration(seconds: 2));
      
      // Return mock successful connection
      return {
        'platform': 'tiktok',
        'authCode': 'mock_tiktok_code_${DateTime.now().millisecondsSinceEpoch}',
        'accessToken': 'mock_tiktok_token_${DateTime.now().millisecondsSinceEpoch}',
        'userId': 'mock_tiktok_user_${DateTime.now().millisecondsSinceEpoch}',
        'displayName': 'TikTok User',
        'connected_at': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      debugPrint('TikTok OAuth Error: $error');
      return null;
    }
  }

  // Facebook OAuth
  static Future<Map<String, dynamic>?> connectFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile', 'pages_read_engagement'],
      );
      
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture",
        );
        return {
          'platform': 'facebook',
          'accessToken': result.accessToken?.token,
          'userId': result.accessToken?.userId,
          'userData': userData,
        };
      }
    } catch (error) {
      debugPrint('Facebook OAuth Error: $error');
    }
    return null;
  }

  // Apple Sign In (for iOS)
  static Future<Map<String, dynamic>?> connectApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      return {
        'platform': 'apple',
        'userIdentifier': credential.userIdentifier,
        'email': credential.email,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
      };
    } catch (error) {
      debugPrint('Apple OAuth Error: $error');
    }
    return null;
  }

  // Disconnect from platform
  static Future<bool> disconnectPlatform(String platform) async {
    try {
      switch (platform.toLowerCase()) {
        case 'youtube':
        case 'google':
          await _googleSignIn.signOut();
          break;
        case 'tiktok':
          debugPrint('TikTok disconnected (mock implementation)');
          break;
        case 'facebook':
        case 'instagram':
          await FacebookAuth.instance.logOut();
          break;
        case 'apple':
          debugPrint('Apple disconnected (no persistent session)');
          break;
        default:
          break;
      }
      return true;
    } catch (error) {
      debugPrint('Disconnect Error: $error');
      return false;
    }
  }

  // Check if platform is connected
  static Future<bool> isPlatformConnected(String platform) async {
    try {
      switch (platform.toLowerCase()) {
        case 'youtube':
        case 'google':
          return _googleSignIn.currentUser != null;
        case 'tiktok':
          // For development, return false to allow connection attempts
          return false;
        case 'facebook':
        case 'instagram':
          final accessToken = await FacebookAuth.instance.accessToken;
          return accessToken != null;
        case 'apple':
          // Apple doesn't provide a persistent check method
          return false;
        default:
          return false;
      }
    } catch (error) {
      debugPrint('Platform check error: $error');
      return false;
    }
  }
}