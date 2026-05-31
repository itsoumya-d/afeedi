import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/subscription_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isAnnual = true;
  int _selectedPlan = 1; // 0=Free, 1=Pro

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackUserInteraction(
      action: 'screen_view',
      screen: 'premium',
    );
    AnalyticsService.instance.trackPaywallShown('premium_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildBillingToggle(),
                    const SizedBox(height: 20),
                    _buildPlanCards(),
                    const SizedBox(height: 24),
                    _buildFeatureComparison(),
                    const SizedBox(height: 24),
                    _buildCTAButton(),
                    const SizedBox(height: 12),
                    _buildFooter(),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _showRestoreDialog(context),
            child: const Text(
              'Restore',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Watch everything.\nNo ads. Cancel anytime.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'One feed. All your platforms. Fully personalized.',
          style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // Social proof
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt_outlined,
                color: Color(0xFF00D4FF),
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'Join 50,000+ viewers watching ad-free',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            'Monthly',
            !_isAnnual,
            () => setState(() => _isAnnual = false),
          ),
          _toggleButton(
            'Annual  ',
            _isAnnual,
            () => setState(() => _isAnnual = true),
            badge: 'Save 33%',
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    String label,
    bool selected,
    VoidCallback onTap, {
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00D4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white60,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.black26 : const Color(0xFF7B61FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCards() {
    final plans = [
      _PlanData(
        index: 0,
        name: 'Free',
        monthlyPrice: 0,
        annualPrice: 0,
        color: const Color(0xFF2A2A4A),
        accentColor: Colors.white54,
        features: [
          'Basic feed personalization',
          'Up to 20 saves',
          'Standard quality',
          'Ads included',
        ],
      ),
      _PlanData(
        index: 1,
        name: 'Pro',
        monthlyPrice: 4.99,
        annualPrice: 39.99,
        color: const Color(0xFF003A4A),
        accentColor: const Color(0xFF00D4FF),
        features: [
          'Advanced AI personalization',
          'Unlimited saves',
          'Ad-free experience',
          'Google Calendar sync',
          'Creator follow insights',
        ],
        popular: true,
      ),
      // Creator tier: not yet available — removed to comply with App Store Guideline 2.1
    ];

    return Column(children: plans.map((plan) => _buildPlanCard(plan)).toList());
  }

  Widget _buildPlanCard(_PlanData plan) {
    final isSelected = _selectedPlan == plan.index;
    final price = plan.index == 0
        ? 'Free'
        : _isAnnual
        ? '\$${plan.annualPrice.toStringAsFixed(2)}/yr'
        : '\$${plan.monthlyPrice.toStringAsFixed(2)}/mo';
    final monthlyEquivalent =
        plan.index != 0 && _isAnnual && plan.annualPrice > 0
        ? 'Only \$${(plan.annualPrice / 12).toStringAsFixed(2)}/mo'
        : null;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? plan.color : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? plan.accentColor : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (plan.popular)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: plan.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? plan.accentColor : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (monthlyEquivalent != null)
                      Text(
                        monthlyEquivalent,
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? plan.accentColor : Colors.white24,
                      width: 2,
                    ),
                    color: isSelected ? plan.accentColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              ...plan.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: plan.accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    final features = [
      ('Feed personalization', 'Basic', 'AI-powered'),
      ('Saves', '20', 'Unlimited'),
      ('Ads', 'Yes', 'No'),
      ('Google Calendar sync', 'No', 'Yes'),
      ('Creator insights', 'No', 'Yes'),
      ('Offline access', 'No', 'Yes'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compare plans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              children: ['Feature', 'Free', 'Pro']
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      child: Text(
                        h,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...features.map(
              (row) => TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white10, width: 0.5),
                  ),
                ),
                children: [row.$1, row.$2, row.$3]
                    .map(
                      (cell) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 2,
                        ),
                        child: Text(
                          cell,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cell == 'No'
                                ? Colors.white24
                                : Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCTAButton() {
    if (_selectedPlan == 0) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Continue with Free',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ),
      );
    }

    const planName = 'Pro';
    // Prices are fetched from the store — fall back to default if not yet loaded
    final monthlyProduct = SubscriptionService.instance.monthlyProduct;
    final annualProduct = SubscriptionService.instance.yearlyProduct;
    final price = _isAnnual
        ? (annualProduct?.price ?? '\$39.99/year')
        : (monthlyProduct?.price ?? '\$4.99/month');
    const color = Color(0xFF00D4FF);

    return ListenableBuilder(
      listenable: SubscriptionService.instance,
      builder: (context, _) {
        final sub = SubscriptionService.instance;

        if (sub.isPremium) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'You\'re already Pro!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        if (sub.isLoading) {
          return const SizedBox(
            width: double.infinity,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                ),
              ),
            ),
          );
        }

        if (sub.purchaseState == PurchaseState.error) {
          return Column(
            children: [
              Text(
                sub.errorMessage ?? 'Purchase failed. Please try again.',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    sub.resetError();
                    _handleSubscribe(context, planName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleSubscribe(context, planName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Start My Free 7 Days — $price after',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleWatchAd(context),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text(
                  'Watch a short ad for 24-hour access',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleWatchAd(BuildContext context) {
    AnalyticsService.instance.trackUserInteraction(
      action: 'watch_ad_tap',
      screen: 'premium',
    );
    AdService.instance.showRewardedAd(
      onRewarded: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('24-hour Pro access unlocked! Enjoy Afeedi.'),
            backgroundColor: Color(0xFF32D74B),
          ),
        );
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFooter() {
    return const Text(
      'Cancel anytime during trial. No charge until trial ends.\nBilled via App Store / Google Play.',
      style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.6),
      textAlign: TextAlign.center,
    );
  }

  void _handleSubscribe(BuildContext context, String planName) {
    AnalyticsService.instance.trackUserInteraction(
      action: 'subscribe_tap',
      screen: 'premium',
      additionalData: {
        'plan': planName,
        'billing': _isAnnual ? 'annual' : 'monthly',
      },
    );

    if (planName == 'Pro') {
      if (_isAnnual) {
        SubscriptionService.instance.purchaseYearly();
      } else {
        SubscriptionService.instance.purchaseMonthly();
      }
      return;
    }

    // Only Pro plan is available; other plan names are not purchasable
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This plan is not yet available. Please select Afeedi Pro.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    SubscriptionService.instance.restorePurchases();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking previous purchases...'),
        backgroundColor: Color(0xFF1A1A2E),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class _PlanData {
  final int index;
  final String name;
  final double monthlyPrice;
  final double annualPrice;
  final Color color;
  final Color accentColor;
  final List<String> features;
  final bool popular;

  const _PlanData({
    required this.index,
    required this.name,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.color,
    required this.accentColor,
    required this.features,
    this.popular = false,
  });
}
