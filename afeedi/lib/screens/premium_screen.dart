import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isAnnual = true;
  int _selectedPlan = 1; // 0=Free, 1=Pro, 2=Creator

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackUserInteraction(action: 'screen_view', screen: 'premium');
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
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
            child: const Text('Restore', style: TextStyle(color: Colors.white54, fontSize: 13)),
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
          'Unlock Afeedi Premium',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your entire social media world,\ncurated and ad-free.',
          style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
          textAlign: TextAlign.center,
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
          _toggleButton('Monthly', !_isAnnual, () => setState(() => _isAnnual = false)),
          _toggleButton('Annual  ', _isAnnual, () => setState(() => _isAnnual = true), badge: 'Save 33%'),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap, {String? badge}) {
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
        features: ['Basic feed personalization', 'Up to 20 saves', 'Standard quality', 'Ads included'],
      ),
      _PlanData(
        index: 1,
        name: 'Pro',
        monthlyPrice: 4.99,
        annualPrice: 39.99,
        color: const Color(0xFF003A4A),
        accentColor: const Color(0xFF00D4FF),
        features: ['Advanced AI personalization', 'Unlimited saves', 'Ad-free experience', 'Google Calendar sync', 'Creator follow insights'],
        popular: true,
      ),
      _PlanData(
        index: 2,
        name: 'Creator',
        monthlyPrice: 9.99,
        annualPrice: 79.99,
        color: const Color(0xFF2A1A4A),
        accentColor: const Color(0xFF7B61FF),
        features: ['Everything in Pro', 'Content scheduling', 'Analytics dashboard', 'Multi-platform posting', 'Priority support'],
      ),
    ];

    return Column(
      children: plans.map((plan) => _buildPlanCard(plan)).toList(),
    );
  }

  Widget _buildPlanCard(_PlanData plan) {
    final isSelected = _selectedPlan == plan.index;
    final price = plan.index == 0
        ? 'Free'
        : _isAnnual
            ? '\$${plan.annualPrice.toStringAsFixed(2)}/yr'
            : '\$${plan.monthlyPrice.toStringAsFixed(2)}/mo';

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: plan.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('POPULAR', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
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
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? plan.accentColor : Colors.white24, width: 2),
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
              ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: plan.accentColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    final features = [
      ('Feed personalization', 'Basic', 'AI-powered', 'AI + Creator signals'),
      ('Saves', '20', 'Unlimited', 'Unlimited'),
      ('Ads', 'Yes', 'No', 'No'),
      ('Google Calendar', 'No', 'Yes', 'Yes'),
      ('Creator insights', 'No', 'Basic', 'Advanced'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compare plans',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.4),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
              children: ['Feature', 'Free', 'Pro', 'Creator'].map((h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Text(h, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
            ...features.map((row) => TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
              children: [row.$1, row.$2, row.$3, row.$4].map((cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Text(
                  cell,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cell == 'No' ? Colors.white24 : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              )).toList(),
            )),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Continue with Free', style: TextStyle(color: Colors.white60, fontSize: 16)),
        ),
      );
    }

    final plans = ['Pro', 'Creator'];
    final prices = _isAnnual ? ['\$39.99/year', '\$79.99/year'] : ['\$4.99/month', '\$9.99/month'];
    final planName = plans[_selectedPlan - 1];
    final price = prices[_selectedPlan - 1];
    final color = _selectedPlan == 1 ? const Color(0xFF00D4FF) : const Color(0xFF7B61FF);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleSubscribe(context, planName),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          'Start $planName — $price',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Text(
      'Cancel anytime. Billed via App Store / Google Play.\nSubscription auto-renews unless cancelled.',
      style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.6),
      textAlign: TextAlign.center,
    );
  }

  void _handleSubscribe(BuildContext context, String planName) {
    AnalyticsService.instance.trackUserInteraction(
      action: 'subscribe_tap',
      screen: 'premium',
      additionalData: {'plan': planName, 'billing': _isAnnual ? 'annual' : 'monthly'},
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
        content: Text(
          'In-app purchases for $planName will be available when Afeedi launches on the App Store and Google Play.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Restore Purchases', style: TextStyle(color: Colors.white)),
        content: const Text(
          'No previous purchases found for this account.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
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
