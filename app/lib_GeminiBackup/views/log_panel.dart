import 'package:flutter/material.dart';

class LogPanel extends StatelessWidget {
  final List<String> logs;

  const LogPanel({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'アクションログ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final logIndex = logs.length - 1 - index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '• ${logs[logIndex]}',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}