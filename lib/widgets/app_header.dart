import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? currentTabName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int unreadNotificationsCount;

  const AppHeader({
    super.key,
    this.currentTabName,
    this.onNotificationTap,
    this.onProfileTap,
    this.unreadNotificationsCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E7FF), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo (Clean brand icon/logo)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/brand/wey_birre_logo.png',
              height: 38,
              fit: BoxFit.contain,
            ),
          ),

          // Wide spacer in top navbar
          const Spacer(),

          // Right Notification Action with Badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                color: AppColors.onSurfaceVariant,
                onPressed: onNotificationTap ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All bank alert notifications parsed locally.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
