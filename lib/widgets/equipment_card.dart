import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/equipment.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (equipment.model != null) ...[
                        const SizedBox(height: 4),
                        Text('Model: ${equipment.model}'),
                      ],
                      const SizedBox(height: 4),
                      Text('Available: ${equipment.quantity}'),
                      Text('Status: ${equipment.status}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${equipment.categoryName ?? "General"}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isDense: true,
                          initialValue: quantity,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            border: OutlineInputBorder(),
                            constraints: BoxConstraints(maxHeight: 28),
                          ),
                          style: const TextStyle(fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          iconSize: 18,
                          menuMaxHeight: 200,
                          items: List.generate(
                            equipment.quantity,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              onQuantityChanged(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // QR Code display in bottom right
                if (equipment.serialNumber != null && equipment.serialNumber!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: QrImageView(
                      data: equipment.serialNumber!,
                      version: QrVersions.auto,
                      size: 60,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}