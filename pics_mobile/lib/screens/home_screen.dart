import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'schedule_screen.dart';
import 'execution_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PICS Mobile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: AppConfig.users.indexOf(AppConfig.currentUser),
                icon: const Icon(Icons.arrow_drop_down),
                items: List.generate(
                  AppConfig.users.length,
                  (i) {
                    final user = AppConfig.users[i];
                    return DropdownMenuItem<int>(
                      value: i,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${user.name} (${user.role})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    AppConfig.currentUser = AppConfig.users[value];
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selamat datang, ${AppConfig.currentUser.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Role: ${AppConfig.currentUser.role} • Section: ${AppConfig.currentUser.section}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Inspector (NRP): '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: AppConfig.currentInspector,
                  items: AppConfig.inspectors
                      .map(
                        (nrp) => DropdownMenuItem<String>(
                          value: nrp,
                          child: Text(nrp),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      AppConfig.currentInspector = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildMenuCard(
                icon: Icons.calendar_month,
                title: 'Jadwal',
                description: 'Lihat jadwal inspeksi & maintenance',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ScheduleScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildMenuCard(
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
