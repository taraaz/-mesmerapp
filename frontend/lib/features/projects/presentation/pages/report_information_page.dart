import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/daily_report_provider.dart';

class ReportInformationPage extends ConsumerStatefulWidget {
  const ReportInformationPage({super.key});

  @override
  ConsumerState<ReportInformationPage> createState() =>
      _ReportInformationPageState();
}

class _ReportInformationPageState
    extends ConsumerState<ReportInformationPage> {
  late final TextEditingController temperatureController;
  late final TextEditingController preparedByController;
  late final TextEditingController approvedByController;
  late final TextEditingController workPerformedController;
  late final TextEditingController delaysController;
  late final TextEditingController hseController;
  late final TextEditingController remarksController;

  @override
  void initState() {
    super.initState();

    final report = ref.read(dailyReportProvider);

    temperatureController = TextEditingController(
      text: report.temperature == 0
          ? ''
          : report.temperature.toString(),
    );

    preparedByController =
        TextEditingController(text: report.preparedBy);

    approvedByController =
        TextEditingController(text: report.approvedBy);

    workPerformedController =
        TextEditingController(text: report.workPerformed);

    delaysController =
        TextEditingController(text: report.delays);

    hseController =
        TextEditingController(text: report.hse);

    remarksController =
        TextEditingController(text: report.remarks);
  }

  @override
  void dispose() {
    temperatureController.dispose();
    preparedByController.dispose();
    approvedByController.dispose();
    workPerformedController.dispose();
    delaysController.dispose();
    hseController.dispose();
    remarksController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(dailyReportProvider);
    final notifier = ref.read(dailyReportProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Report Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // PROJECT
            // --------------------------------------------------

            DropdownButtonFormField<String>(
              initialValue: report.projectName.isEmpty
                  ? null
                  : report.projectName,
              decoration: const InputDecoration(
                labelText: 'Project',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Chirchiq',
                  child: Text('Chirchiq'),
                ),
                DropdownMenuItem(
                  value: 'Angeren',
                  child: Text('Angeren'),
                ),
                DropdownMenuItem(
                  value: 'Almalyk',
                  child: Text('Almalyk'),
                ),
                DropdownMenuItem(
                  value: 'Bekobod',
                  child: Text('Bekobod'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.setProjectName(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // REPORT DATE
            // --------------------------------------------------

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Report Date'),
              subtitle: Text(
                '${report.reportDate.day}/'
                '${report.reportDate.month}/'
                '${report.reportDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: report.reportDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (selectedDate != null) {
                  notifier.setReportDate(selectedDate);
                }
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // WEATHER
            // --------------------------------------------------

            DropdownButtonFormField<String>(
              initialValue:
                  report.weather.isEmpty ? null : report.weather,
              decoration: const InputDecoration(
                labelText: 'Weather',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Sunny',
                  child: Text('Sunny'),
                ),
                DropdownMenuItem(
                  value: 'Cloudy',
                  child: Text('Cloudy'),
                ),
                DropdownMenuItem(
                  value: 'Rainy',
                  child: Text('Rainy'),
                ),
                DropdownMenuItem(
                  value: 'Snowy',
                  child: Text('Snowy'),
                ),
                DropdownMenuItem(
                  value: 'Windy',
                  child: Text('Windy'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.setWeather(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // TEMPERATURE
            // --------------------------------------------------

            TextField(
              controller: temperatureController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Temperature (°C)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final temperature = double.tryParse(value);

                if (temperature != null) {
                  notifier.setTemperature(temperature);
                }
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // SHIFT
            // --------------------------------------------------

            DropdownButtonFormField<String>(
              initialValue:
                  report.shift.isEmpty ? null : report.shift,
              decoration: const InputDecoration(
                labelText: 'Shift',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Day',
                  child: Text('Day Shift'),
                ),
                DropdownMenuItem(
                  value: 'Night',
                  child: Text('Night Shift'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.setShift(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // PREPARED BY
            // --------------------------------------------------

            TextField(
              controller: preparedByController,
              decoration: const InputDecoration(
                labelText: 'Prepared By',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setPreparedBy,
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // APPROVED BY
            // --------------------------------------------------

            TextField(
              controller: approvedByController,
              decoration: const InputDecoration(
                labelText: 'Approved By',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setApprovedBy,
            ),

            const SizedBox(height: 24),

            const Divider(),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // WORK INFORMATION
            // --------------------------------------------------

            const Text(
              'Work Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Work Performed
            TextField(
              controller: workPerformedController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Work Performed',
                hintText:
                    'Describe the work completed today...',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setWorkPerformed,
            ),

            const SizedBox(height: 16),

            // Delays
            TextField(
              controller: delaysController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Delays',
                hintText: 'Describe any delays...',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setDelays,
            ),

            const SizedBox(height: 16),

            // HSE
            TextField(
              controller: hseController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'HSE',
                hintText:
                    'Health, safety and environment information...',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setHse,
            ),

            const SizedBox(height: 16),

            // Remarks
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setRemarks,
            ),

            const SizedBox(height: 32),

            // --------------------------------------------------
            // SAVE & CONTINUE
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report information saved.',
                      ),
                    ),
                  );
                },
                child: const Text('Save & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}