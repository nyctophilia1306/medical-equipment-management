import 'package:flutter/material.dart';
import '../../models/equipment.dart';

class ReturnEquipmentDialog extends StatefulWidget {
  final Map<String, dynamic> request;
  final Equipment? equipment;

  const ReturnEquipmentDialog({
    super.key,
    required this.request,
    this.equipment,
  });

  @override
  State<ReturnEquipmentDialog> createState() => _ReturnEquipmentDialogState();
}

class _ReturnEquipmentDialogState extends State<ReturnEquipmentDialog> {
  final _conditionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _conditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Return Equipment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipment: ${widget.equipment?.name ?? 'Unknown'}'),
            Text('Quantity: ${widget.request['quantity']}'),
            const SizedBox(height: 16),
            TextField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: 'Return Condition',
                hintText: 'e.g., Good, Damaged, etc.',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi Chú',
                hintText: 'Any additional notes about the return',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'condition': _conditionController.text,
            'notes': _notesController.text,
          }),
          child: const Text('Confirm Return'),
        ),
      ],
    );
  }
}