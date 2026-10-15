import 'package:flutter/material.dart';

import 'create_daily_report_page.dart';

class DailyReportsPage extends StatelessWidget {
  final String projectName;

  const DailyReportsPage({
    super.key,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    final reports = [
      "Daily Report #001",
      "Daily Report #002",
      "Daily Report #003",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$projectName - Daily Reports'),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateDailyReportPage(
                projectName: projectName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.assignment),
              ),

              title: Text(
                reports[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: const Text(
                'Date: 07-Aug-2026',
              ),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Open ${reports[index]}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}