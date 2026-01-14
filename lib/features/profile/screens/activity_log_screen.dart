import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Activity Log"), centerTitle: true),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text("No profile data"));
          }
          final lastCheckIn = profile.lastCheckIn;

          // Mock history removed. Only showing real latest check-in.
          final List<DateTime> history = [lastCheckIn];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final date = history[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    child: Icon(
                      Icons.check_circle,
                      color: index == 0 ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(
                    index == 0 ? "Latest Check-in" : "Routine Check-in",
                    style: TextStyle(
                      fontWeight: index == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(DateFormat('MMMM d, y • h:mm a').format(date)),
                  trailing: index == 0
                      ? const Chip(
                          label: Text(
                            "Verified",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
