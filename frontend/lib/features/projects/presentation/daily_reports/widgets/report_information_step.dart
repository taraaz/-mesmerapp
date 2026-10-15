import 'package:flutter/material.dart';

class ReportInformationStep extends StatelessWidget {
  const ReportInformationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Report Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            initialValue: 'DR-0001',
            readOnly: true,
          ),

          const SizedBox(height: 20),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Report Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Weather',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cloud),
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
            onChanged: (_) {},
          ),

          const SizedBox(height: 20),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Temperature (°C)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.thermostat),
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Shift',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Day',
                child: Text('Day'),
              ),
              DropdownMenuItem(
                value: 'Night',
                child: Text('Night'),
              ),
            ],
            onChanged: (_) {},
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Prepared By',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Site Engineer',
                child: Text('Site Engineer'),
              ),
              DropdownMenuItem(
                value: 'Construction Manager',
                child: Text('Construction Manager'),
              ),
              DropdownMenuItem(
                value: 'Project Manager',
                child: Text('Project Manager'),
              ),
            ],
            onChanged: (_) {},
          ),

        ],
      ),
    );
  }
}