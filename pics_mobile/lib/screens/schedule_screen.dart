import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<Schedule>> _futureSchedules;

  @override
  void initState() {
    super.initState();
    _futureSchedules = ScheduleService.fetchSchedules();
  }

  void _retry() {
    setState(() {
      _futureSchedules = ScheduleService.fetchSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Schedule>>(
        future: _futureSchedules,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat jadwal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final schedules = snapshot.data!;

          if (schedules.isEmpty) {
            return const Center(child: Text('Tidak ada jadwal'));
          }

          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: schedule.valid == 1
                        ? Colors.green
                        : Colors.grey,
                    child: Icon(
                      schedule.valid == 1 ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(schedule.equipmentCode),
                  subtitle: Text(schedule.date),
                  trailing: Text(
                    schedule.valid == 1 ? 'Valid' : 'Invalid',
                    style: TextStyle(
                      color: schedule.valid == 1 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
