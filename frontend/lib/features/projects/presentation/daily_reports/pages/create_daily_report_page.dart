import 'package:flutter/material.dart';

import '../widgets/report_information_step.dart';
import '../widgets/personnel_step.dart';

class CreateDailyReportPage extends StatefulWidget {
  final String projectName;

  const CreateDailyReportPage({
    super.key,
    required this.projectName,
  });

  @override
  State<CreateDailyReportPage> createState() =>
      _CreateDailyReportPageState();
}

class _CreateDailyReportPageState
    extends State<CreateDailyReportPage> {
  int currentStep = 0;

  final List<String> steps = [
    'Report Information',
    'Personnel',
    'Equipment',
    'Materials',
    'Work Performed',
    'HSE',
    'Visitors',
    'Photos',
    'Remarks',
    'Review & Submit',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Report',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: (currentStep + 1) / steps.length,
            ),

            const SizedBox(height: 16),

            Text(
              'Step ${currentStep + 1} of ${steps.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              steps[currentStep],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _buildCurrentStep(),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: currentStep == 0
                        ? null
                        : () {
                            setState(() {
                              currentStep--;
                            });
                          },
                    child: const Text('Previous'),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: ElevatedButton(
                    onPressed: currentStep == steps.length - 1
                        ? null
                        : () {
                            setState(() {
                              currentStep++;
                            });
                          },
                    child: Text(
                        currentStep == steps.length - 2
                            ? 'Review'
                            : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return const ReportInformationStep();

      case 1:
        return const PersonnelStep();

      case 2:
        return const Center(
          child: Text(
            'Equipment Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 3:
        return const Center(
          child: Text(
            'Materials Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 4:
        return const Center(
          child: Text(
            'Work Performed Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 5:
        return const Center(
          child: Text(
            'HSE Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 6:
        return const Center(
          child: Text(
            'Visitors Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 7:
        return const Center(
          child: Text(
            'Photos Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 8:
        return const Center(
          child: Text(
            'Remarks Step',
            style: TextStyle(fontSize: 28),
          ),
        );

      case 9:
        return const Center(
          child: Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}