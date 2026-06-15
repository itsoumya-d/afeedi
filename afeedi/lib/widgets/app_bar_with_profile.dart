import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class AppBarWithProfile extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;
  final double elevation;
  final Color? backgroundColor;

  const AppBarWithProfile({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.onProfileTap,
    this.actions,
    this.elevation = 0.0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.heading4.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.textPrimary,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          tooltip: 'Profile',
          icon: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
            radius: 16,
          ),
          onPressed:
              onProfileTap ??
              () {
                // Default profile action if none provided
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile action not implemented')),
                );
              },
        ),
        SizedBox(width: 8),
      ],
      elevation: elevation,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
