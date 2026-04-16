import 'package:flutter/material.dart';
import '../widgets/gradient_app_bar.dart';

class AccessMenuScreen extends StatelessWidget {
  const AccessMenuScreen({super.key});

  static const List<Map<String, String>> _dummyUsers = [
    {
      'name': 'M. ILMI',
      'nrp': '0113151',
      'role': 'user',
      'section': 'PLANT PRIME MOVER',
    },
    {
      'name': 'Siti Rahayu',
      'nrp': '10230002',
      'role': 'user',
      'section': 'Plant Prime Mover',
    },
    {
      'name': 'Agus Supriadi',
      'nrp': '0209316',
      'role': 'glup',
      'section': 'PLANT PRIME MOVER',
    },
    {
      'name': 'Prawoto',
      'nrp': '0207687',
      'role': 'user',
      'section': 'PLANT VESSEL',
    },
    {
      'name': 'Agus Sugianor',
      'nrp': '0206632',
      'role': 'user',
      'section': 'PLANT TYRE SUPPORT',
    },
    {
      'name': 'Titin Ismaya',
      'nrp': '702200243',
      'role': 'user',
      'section': 'PLANT PRIME MOVER',
    },
  ];

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'U';
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
        return const Color(0xFFFF7043);
      case 'group leader':
        return const Color(0xFF7C4DFF);
      case 'inspector':
        return kAccentTeal;
      default:
        return const Color(0xFF78909C);
    }
  }

  Color _avatarColor(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
        return const Color(0xFFBF360C);
      case 'group leader':
        return const Color(0xFF4527A0);
      case 'inspector':
        return const Color(0xFF00796B);
      default:
        return const Color(0xFF455A64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Menu Akses'),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _dummyUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final u = _dummyUsers[index];
          final role = u['role']!;
          final rc = _roleColor(role);
          final ac = _avatarColor(role);

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ac,
                    child: Text(
                      _initials(u['name']!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NRP: ${u['nrp']!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u['section']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Role chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: rc.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: rc,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
