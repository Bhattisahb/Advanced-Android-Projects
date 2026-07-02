import 'package:flutter/material.dart';

class TableSelector extends StatefulWidget {
  final Function(int) onTableSelected;

  const TableSelector({
    super.key,
    required this.onTableSelected,
  });

  @override
  State<TableSelector> createState() => _TableSelectorState();
}

class _TableSelectorState extends State<TableSelector> {
  int selectedTable = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Select a Table (2-20)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: selectedTable,
            underline: const SizedBox(),
            items: List.generate(
              19,
              (index) => DropdownMenuItem(
                value: index + 2,
                child: Text(
                  'Table ${index + 2}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedTable = value;
                });
                widget.onTableSelected(value);
              }
            },
          ),
        ),
      ],
    );
  }
}
