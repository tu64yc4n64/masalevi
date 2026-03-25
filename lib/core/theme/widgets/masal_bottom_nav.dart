import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_colors.dart';
import 'bounce_button.dart';

enum ParentTab { home, library, settings }

class MasalBottomNav extends StatelessWidget {
  const MasalBottomNav({
    super.key,
    required this.currentTab,
  });

  final ParentTab currentTab;

  static ParentTab fromLocation(String location) {
    if (location.startsWith('/library')) return ParentTab.library;
    if (location.startsWith('/settings')) return ParentTab.settings;
    return ParentTab.home;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIcon(
            tab: ParentTab.home,
            currentTab: currentTab,
            icon: Icons.home_rounded,
            label: 'Ana',
            onTap: () => context.go('/home'),
          ),
          _NavIcon(
            tab: ParentTab.library,
            currentTab: currentTab,
            icon: Icons.book_rounded,
            label: 'Favori',
            onTap: () => context.go('/library'),
          ),
          _NavIcon(
            tab: ParentTab.settings,
            currentTab: currentTab,
            icon: Icons.settings_rounded,
            label: 'Ayarlar',
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.tab,
    required this.currentTab,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final ParentTab tab;
  final ParentTab currentTab;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = tab == currentTab;
    final bg = active ? AppColors.primaryPurple : Colors.transparent;
    final fg = active ? AppColors.textBase : AppColors.textBase.withOpacity(0.85);

    return SizedBox(
      height: 48,
      width: 96,
      child: BounceButton(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            // Aktif ikon: label gizli, ikon merkezde.
            // Pasif ikon: label alanını "mantıklı" bir minimumla ayır ki RenderFlex overflow olmasın.
            final labelBoxHeight = active ? 0.0 : (h * 0.25).clamp(10.0, h);
            final gap = active ? 0.0 : h * 0.02;
            final iconSize = (h - labelBoxHeight - gap).clamp(24.0, double.infinity);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: iconSize,
                  width: iconSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : AppColors.primaryPurple.withOpacity(0.25),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Icon(icon, size: 18, color: fg),
                    ),
                  ),
                ),
                if (!active) SizedBox(height: gap),
                if (!active)
                  SizedBox(
                    height: labelBoxHeight,
                    child: Center(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textBase.withOpacity(0.7),
                              fontSize: 10,
                              height: 0.95, // Line-height kontrolü: overflow'u engeller
                            ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

