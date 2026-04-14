import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'schedule_screen.dart';
import 'execution_screen.dart';
import 'approval_screen.dart';
import 'landing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is logged in, redirect to login if not
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppConfig.loggedInUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const LandingScreen(),
          ),
        );
      }
    });
  }

  void _showUserProfileDialog() {
    final user = AppConfig.loggedInUser;
    if (user == null) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profil User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileRow('NRP', user.nrp),
                _buildProfileRow('Nama User', user.nama ?? 'N/A'),
                _buildProfileRow('Section', user.section ?? 'N/A'),
                _buildProfileRow('Perusahaan', user.perusahaan ?? 'N/A'),
                _buildProfileRow('Jabatan', user.jabatan ?? 'N/A'),
                _buildProfileRow('Job Group', user.jobGroup ?? 'N/A'),
                _buildProfileRow('Job Rank', user.jobRank ?? 'N/A'),
                _buildProfileRow('Role', user.role ?? 'N/A'),
                _buildProfileRow('Type User', user.typeUser ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            FilledButton.icon(
              onPressed: () {
                AppConfig.clearLoggedInUser();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LandingScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppConfig.loggedInUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final menuItems = [
      // _HomeMenuItem(
      //   icon: Icons.calendar_month,
      //   title: 'Jadwal',
      //   description: 'Lihat jadwal inspeksi & maintenance',
      //   color: Colors.blue,
      //   onTap: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute<void>(
      //         builder: (_) => const ScheduleScreen(),
      //       ),
      //     );
      //   },
      // ),
      _HomeMenuItem(
        icon: Icons.build_circle,
        title: 'Eksekusi',
        description: 'Eksekusi inspeksi per unit & part of check',
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const ExecutionScreen(),
            ),
          );
        },
      ),
      // Conditionally show Approval menu only for 'glup' type_user or 'administrator' role
      if (user.jobRank == 'GROUP LEADER (SETARA)' || user.role == 'administrator')
        _HomeMenuItem(
          icon: Icons.approval,
          title: 'Approval',
          description: 'Persetujuan hasil inspeksi dan tindak lanjut',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ApprovalScreen(),
              ),
            );
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PICS Mobile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            // child: DropdownButtonHideUnderline(
            //   child: DropdownButton<int>(
            //     value: AppConfig.users.indexOf(AppConfig.currentUser),
            //     icon: const Icon(Icons.arrow_drop_down),
            //     items: List.generate(
            //       AppConfig.users.length,
            //       (i) {
            //         final user = AppConfig.users[i];
            //         return DropdownMenuItem<int>(
            //           value: i,
            //           child: Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               const Icon(Icons.person, size: 18),
            //               const SizedBox(width: 6),
            //               Text(
            //                 '${user.name} (${user.role})',
            //                 style: const TextStyle(fontSize: 13),
            //               ),
            //             ],
            //           ),
            //         );
            //       },
            //     ),
            //     onChanged: (value) {
            //       if (value == null) return;
            //       setState(() {
            //         AppConfig.currentUser = AppConfig.users[value];
            //       });
            //     },
            //   ),
            // ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _showUserProfileDialog,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang, ${user.nama ?? "User"}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Section: ${user.section ?? "N/A"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.account_circle,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

                  return GridView.builder(
                    itemCount: menuItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: width < 600 ? 1.7 : 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return _buildMenuCard(
                        icon: item.icon,
                        title: item.title,
                        description: item.description,
                        color: item.color,
                        onTap: item.onTap,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuItem {
  const _HomeMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
}
