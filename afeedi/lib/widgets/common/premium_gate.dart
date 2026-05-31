import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../services/navigation_service.dart';

/// Wraps [child] and blurs/locks it for free users.
/// Premium users see [child] unmodified.
class PremiumGate extends StatelessWidget {
  const PremiumGate({super.key, required this.child, this.featureName});

  final Widget child;
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SubscriptionService.instance,
      builder: (context, _) {
        if (SubscriptionService.instance.isPremium) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          featureName != null
                              ? '$featureName is Pro'
                              : 'Premium Feature',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.premium),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
