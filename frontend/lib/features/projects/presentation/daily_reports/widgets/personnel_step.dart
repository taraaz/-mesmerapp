import 'package:flutter/material.dart';

import '../../../../../core/widgets/editable_table.dart';

class PersonnelStep extends StatelessWidget {
  const PersonnelStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditableTable(
      title: 'Personnel',
      columns: [
        'Company',
        'Trade',
        'Count',
      ],
    );
  }
}