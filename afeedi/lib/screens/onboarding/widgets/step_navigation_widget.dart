import 'package:flutter/material.dart';

class StepNavigationWidget extends StatefulWidget {
  final bool canGoBack;
  final bool canGoNext;
  final bool isLastStep;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;
  final bool isLoading;
  final String? nextButtonText;
  final String? backButtonText;
  final String? finishButtonText;
  final bool showSkip;
  
  const StepNavigationWidget({
    super.key,
    this.canGoBack = true,
    this.canGoNext = true,
    this.isLastStep = false,
    this.onBack,
    this.onNext,
    this.onSkip,
    this.onFinish,
    this.isLoading = false,
    this.nextButtonText,
    this.backButtonText,
    this.finishButtonText,
    this.showSkip = true,
  });
  
  @override
  State<StepNavigationWidget> createState() => _StepNavigationWidgetState();
}

class _StepNavigationWidgetState extends State<StepNavigationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
    _slideController.forward();
    _scaleController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showSkip && !widget.isLastStep)
                  _buildSkipButton(),
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: widget.onSkip,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip for now',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (widget.canGoBack) ...[
          _buildBackButton(),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: widget.isLastStep
              ? _buildFinishButton()
              : _buildNextButton(),
        ),
      ],
    );
  }
  
  Widget _buildBackButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onBack,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              widget.backButtonText ?? 'Back',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNextButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: widget.canGoNext && !widget.isLoading ? widget.onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: widget.isLoading
            ? _buildLoadingIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.nextButtonText ?? 'Continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildFinishButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: widget.isLoading
            ? _buildLoadingIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.finishButtonText ?? 'Get Started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// Custom button widget for special actions
class OnboardingActionButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  
  const OnboardingActionButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 48,
  });
  
  @override
  State<OnboardingActionButton> createState() => _OnboardingActionButtonState();
}

class _OnboardingActionButtonState extends State<OnboardingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: widget.isPrimary
                ? _buildPrimaryButton()
                : _buildSecondaryButton(),
          ),
        );
      },
    );
  }
  
  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _buildButtonContent(),
    );
  }
  
  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.foregroundColor ?? Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _buildButtonContent(),
    );
  }
  
  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isPrimary
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    
    return Text(
      widget.text,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
  
  void _handlePress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed?.call();
  }
}