import 'package:flutter/material.dart';
import '../services/oauth_service.dart';

class OAuthPlatformButton extends StatefulWidget {
  final String platform;
  final String displayName;
  final IconData icon;
  final Color primaryColor;
  final Color textColor;
  final Function(Map<String, dynamic>?) onConnected;
  final bool isConnected;

  const OAuthPlatformButton({
    Key? key,
    required this.platform,
    required this.displayName,
    required this.icon,
    required this.primaryColor,
    required this.textColor,
    required this.onConnected,
    this.isConnected = false,
  }) : super(key: key);

  @override
  State<OAuthPlatformButton> createState() => _OAuthPlatformButtonState();
}

class _OAuthPlatformButtonState extends State<OAuthPlatformButton> {
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _isConnected = widget.isConnected;
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    final isConnected = await OAuthService.isPlatformConnected(widget.platform);
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  Future<void> _handleConnection() async {
    if (_isConnected) {
      // Disconnect
      setState(() {
        _isLoading = true;
      });
      
      try {
        final success = await OAuthService.disconnectPlatform(widget.platform)
            .timeout(const Duration(seconds: 10));
        if (success) {
          setState(() {
            _isConnected = false;
          });
          widget.onConnected(null);
        }
      } catch (error) {
        debugPrint('Disconnect error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disconnect from ${widget.displayName}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic>? result;
    
    try {
      // Add timeout to prevent hanging
      switch (widget.platform.toLowerCase()) {
        case 'youtube':
          result = await OAuthService.connectYouTube()
              .timeout(const Duration(seconds: 30));
          break;
        case 'instagram':
          result = await OAuthService.connectInstagram()
              .timeout(const Duration(seconds: 30));
          break;
        case 'tiktok':
          result = await OAuthService.connectTikTok()
              .timeout(const Duration(seconds: 30));
          break;
        case 'facebook':
          result = await OAuthService.connectFacebook()
              .timeout(const Duration(seconds: 30));
          break;
        case 'apple':
          result = await OAuthService.connectApple()
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Unsupported platform: ${widget.platform}');
      }

      if (result != null) {
        setState(() {
          _isConnected = true;
        });
        widget.onConnected(result);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to ${widget.displayName}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect to ${widget.displayName}. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        debugPrint('OAuth connection timeout for ${widget.platform}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection to ${widget.displayName} timed out. Please try again.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('OAuth connection error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error connecting to ${widget.displayName}. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleConnection,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isConnected ? Colors.green : widget.primaryColor,
          foregroundColor: widget.textColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  _isConnected ? Icons.check_circle : widget.icon,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Text(
                _isConnected 
                    ? 'Connected to ${widget.displayName}'
                    : 'Connect ${widget.displayName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
             ],
           ),
        ),
      ),
    );
  }
}

class OAuthPlatformGrid extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onPlatformsConnected;
  final VoidCallback? onContinueWithoutConnecting;
  final VoidCallback? onConnectAndContinue;

  const OAuthPlatformGrid({
    Key? key,
    required this.onPlatformsConnected,
    this.onContinueWithoutConnecting,
    this.onConnectAndContinue,
  }) : super(key: key);

  @override
  State<OAuthPlatformGrid> createState() => _OAuthPlatformGridState();
}

class _OAuthPlatformGridState extends State<OAuthPlatformGrid> {
  final List<Map<String, dynamic>> _connectedPlatforms = [];

  void _handlePlatformConnection(String platform, Map<String, dynamic>? data) {
    setState(() {
      // Remove existing connection for this platform
      _connectedPlatforms.removeWhere((p) => p['platform'] == platform);
      
      // Add new connection if data is provided
      if (data != null) {
        _connectedPlatforms.add(data);
      }
    });
    
    widget.onPlatformsConnected(_connectedPlatforms);
  }

  Widget _buildPlatformLogo(String platform) {
    switch (platform) {
      case 'youtube':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 20,
          ),
        );
      case 'instagram':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE4405F), Color(0xFFFCAF45), Color(0xFF833AB4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 18,
          ),
        );
      case 'tiktok':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 18,
          ),
        );
      case 'facebook':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.facebook,
            color: Colors.white,
            size: 18,
          ),
        );
      default:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.link,
            color: Colors.white,
            size: 18,
          ),
        );
    }
  }

  Widget _buildPlatformCard(String platform, String displayName, Color primaryColor) {
    final isConnected = _connectedPlatforms.any((p) => p['platform'] == platform);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected ? [
            primaryColor.withOpacity(0.15),
            primaryColor.withOpacity(0.08),
          ] : [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? primaryColor.withOpacity(0.6) : Colors.white.withOpacity(0.2),
          width: isConnected ? 2 : 1.5,
        ),
        boxShadow: isConnected ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPlatformLogo(platform),
                  ),
                  if (isConnected)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConnected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.3),
                                  Colors.green.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.withOpacity(0.6)),
                            ),
                            child: const Text(
                              'CONNECTED',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isConnected 
                          ? 'Ready for personalized content recommendations' 
                          : 'Tap to connect and unlock personalized recommendations',
                      style: TextStyle(
                        fontSize: 13,
                        color: isConnected ? Colors.green.withOpacity(0.9) : Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(isConnected),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? Colors.green.withOpacity(0.5) : primaryColor.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    isConnected ? Icons.check_circle : Icons.add_circle_outline,
                    color: isConnected ? Colors.green : primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.1),
            const Color(0xFF0099CC).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Header with Progress Indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Connect Your Platforms',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00D4FF).withOpacity(0.5),
                            ),
                          ),
                          child: const Text(
                            '4/7',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF00D4FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose platforms to get personalized recommendations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Platform Cards
          GestureDetector(
            onTap: () => _handlePlatformConnection('youtube', {'platform': 'youtube', 'name': 'YouTube'}),
            child: _buildPlatformCard('youtube', 'YouTube', const Color(0xFFFF0000)),
          ),
          GestureDetector(
            onTap: () => _handlePlatformConnection('instagram', {'platform': 'instagram', 'name': 'Instagram'}),
            child: _buildPlatformCard('instagram', 'Instagram', const Color(0xFFE4405F)),
          ),
          GestureDetector(
            onTap: () => _handlePlatformConnection('tiktok', {'platform': 'tiktok', 'name': 'TikTok'}),
            child: _buildPlatformCard('tiktok', 'TikTok', const Color(0xFF000000)),
          ),
          GestureDetector(
            onTap: () => _handlePlatformConnection('facebook', {'platform': 'facebook', 'name': 'Facebook'}),
            child: _buildPlatformCard('facebook', 'Facebook', const Color(0xFF1877F2)),
          ),
          
          const SizedBox(height: 24),
          
          // Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _connectedPlatforms.isNotEmpty 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _connectedPlatforms.isNotEmpty 
                    ? Colors.green.withOpacity(0.5) 
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _connectedPlatforms.isNotEmpty ? Icons.check_circle : Icons.info_outline,
                  color: _connectedPlatforms.isNotEmpty ? Colors.green : Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _connectedPlatforms.isEmpty
                      ? 'No platforms connected yet'
                      : '${_connectedPlatforms.length} platform${_connectedPlatforms.length == 1 ? '' : 's'} connected',
                  style: TextStyle(
                    fontSize: 14,
                    color: _connectedPlatforms.isNotEmpty ? Colors.green : Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Progress indicator
                Row(
                  children: [
                    Icon(
                      _connectedPlatforms.isNotEmpty ? Icons.check_circle : Icons.info_outline,
                      color: _connectedPlatforms.isNotEmpty ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectedPlatforms.isEmpty
                            ? 'Connect at least one platform to continue'
                            : '${_connectedPlatforms.length} platform${_connectedPlatforms.length > 1 ? 's' : ''} connected - Ready to proceed!',
                        style: TextStyle(
                          color: _connectedPlatforms.isNotEmpty ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Continue Without Connecting
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ElevatedButton(
                          onPressed: widget.onContinueWithoutConnecting,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Skip for Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Connect and Continue
                    Expanded(
                      flex: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _connectedPlatforms.isNotEmpty
                              ? const LinearGradient(
                                  colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.withOpacity(0.3),
                                    Colors.grey.withOpacity(0.2),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _connectedPlatforms.isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00D4FF).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: _connectedPlatforms.isNotEmpty ? widget.onConnectAndContinue : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_connectedPlatforms.isNotEmpty) ...[
                                const Icon(Icons.arrow_forward, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  _connectedPlatforms.isEmpty
                                      ? 'Connect Platform'
                                      : 'Continue',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _connectedPlatforms.isNotEmpty 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}