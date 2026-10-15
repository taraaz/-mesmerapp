import 'package:flutter/material.dart';

class EditableTable extends StatefulWidget {
  final String title;
  final List<String> columns;

  const EditableTable({
    super.key,
    required this.title,
    required this.columns,
  });

  @override
  State<EditableTable> createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  final List<List<TextEditingController>> rows = [];

  @override
  void dispose() {
    for (final row in rows) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void addRow() {
    setState(() {
      rows.add(
        List.generate(
          widget.columns.length,
          (_) => TextEditingController(),
        ),
      );
    });
  }

  void deleteRow(int index) {
    for (final controller in rows[index]) {
      controller.dispose();
    }

    setState(() {
      rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Row(
          children: [

            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: addRow,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),

          ],
        ),

        const SizedBox(height: 20),

        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    "No ${widget.title} Added",
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, rowIndex) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [

                            for (int i = 0;
                                i < widget.columns.length;
                                i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextField(
                                  controller: rows[rowIndex][i],
                                  decoration: InputDecoration(
                                    labelText: widget.columns[i],
                                    border:
                                        const OutlineInputBorder(),
                                  ),
                                ),
                              ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  deleteRow(rowIndex);
                                },
                              ),
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

      ],
    );
  }
}