import 'package:flutter/material.dart';

import '../services/progress_store.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key, required this.store, required this.onRefresh});

  final ProgressStore store;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('我的进度', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _StatCard(label: '已学单词', value: '${store.learnedCount()}'),
          const SizedBox(height: 12),
          _StatCard(label: '今日新学', value: '${store.todayCount()}'),
          const SizedBox(height: 12),
          _StatCard(label: '连续天数', value: '${store.streakDays()}'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
