import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../widgets/gradient_app_bar.dart';
import '../screens/access_menu_screen.dart';

/// Left-side navigation drawer with role-based menu visibility.
///
/// Pass [currentRoute] matching one of the route keys defined here
/// ('home', 'access_menu') so the active item gets highlighted.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute = 'home'});

  final String currentRoute;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = AppConfig.loggedInUser;
    final isAdmin = user?.role == 'administrator';
    final initials = _getInitials(user?.nama ?? 'User');

    return Drawer(
      backgroundColor: kDrawerBackground,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          _DrawerHeader(
            initials: initials,
            nama: user?.nama ?? 'User',
            nrp: user?.nrp ?? '—',
            role: user?.role ?? user?.typeUser ?? 'user',
          ),

          const SizedBox(height: 8),

          // ── Navigation items ───────────────────────────────────
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: currentRoute == 'home',
            onTap: () => Navigator.pop(context),
          ),

          // Push admin items to the bottom
          const Spacer(),

          // ── Admin-only section ─────────────────────────────────
          if (isAdmin) ...[
            const Divider(
              color: Color(0x33FFFFFF),
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            _NavItem(
              icon: Icons.manage_accounts_rounded,
              label: 'Menu Akses',
              isActive: currentRoute == 'access_menu',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AccessMenuScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.initials,
    required this.nama,
    required this.nrp,
    required this.role,
  });

  final String initials;
  final String nama;
  final String nrp;
  final String role;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAppBarStart, kAppBarMid, kAppBarEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kAccentTeal,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            'NRP: $nrp',
            style: const TextStyle(
              color: Color(0xFFD6E4FF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _RoleBadge(role: role),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  Color get _badgeColor {
    switch (role.toLowerCase()) {
      case 'administrator':
        return const Color(0xFFFF7043);
      case 'group leader (setara)':
        return const Color(0xFF7C4DFF);
      default:
        return kAccentTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _badgeColor.withValues(alpha: 0.55)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0x1A00BFA5) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: const Color(0x3300BFA5))
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? kAccentTeal.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? kAccentTeal : const Color(0xFFB0C8E8),
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? kAccentTeal : const Color(0xFFD6E4FF),
            fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}
