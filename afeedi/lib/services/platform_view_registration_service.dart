import 'package:flutter/material.dart';

// Export the implementation based on platform
export 'platform_view_registration_service_web.dart'
    if (dart.library.io) 'platform_view_registration_service_stub.dart';

/// This file serves as a facade for the platform-specific implementations.
/// The actual implementation is in either:
/// - platform_view_registration_service_web.dart (for web)
/// - platform_view_registration_service_stub.dart (for non-web platforms)
///
/// The correct implementation is automatically selected at compile time
/// based on the target platform.
