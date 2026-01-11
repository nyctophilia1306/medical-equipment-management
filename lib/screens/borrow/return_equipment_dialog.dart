import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
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
      title: Text(AppLocalizations.of(context)!.returnEquipment),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.of(context)!.equipment}: ${widget.equipment?.name ?? AppLocalizations.of(context)!.unknown}'),
            Text('${AppLocalizations.of(context)!.quantity}: ${widget.request['quantity']}'),
            const SizedBox(height: 16),
            TextField(
              controller: _conditionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.returnCondition,
                hintText: AppLocalizations.of(context)!.returnConditionHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.notes,
                hintText: AppLocalizations.of(context)!.notesHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'condition': _conditionController.text,
            'notes': _notesController.text,
          }),
          child: Text(AppLocalizations.of(context)!.confirmReturn),
        ),
      ],
    );
  }
}
