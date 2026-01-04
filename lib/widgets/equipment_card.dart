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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image at the top with more space
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty
                    ? Image.network(
                        equipment.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.medical_services,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.medical_services,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Equipment name
            Text(
              equipment.getLocalizedName(context),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Category
            Row(
              children: [
                const Icon(Icons.category, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    equipment.categoryName ?? "General",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (equipment.model != null) ...[
              const SizedBox(height: 4),
              Text(
                'Model: ${equipment.model}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 4),
            Text(_getQuantityDisplay(), style: const TextStyle(fontSize: 13)),
            Text(
              'Trạng thái: ${_getStatusText()}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            // QR Code and Quantity selector at bottom
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // QR Code on the left
                if (equipment.serialNumber != null &&
                    equipment.serialNumber!.isNotEmpty)
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
                if (equipment.serialNumber != null &&
                    equipment.serialNumber!.isNotEmpty)
                  const SizedBox(width: 12),
                // Quantity selector
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
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
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 13),
                              ),
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
                // Delete button on the right
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getQuantityDisplay() {
    if (equipment.quantity == equipment.availableQty) {
      return 'Số lượng: ${equipment.quantity}';
    } else {
      return 'Số lượng: ${equipment.quantity} (Có sẵn: ${equipment.availableQty})';
    }
  }

  String _getStatusText() {
    switch (equipment.status.toLowerCase()) {
      case 'available':
        return 'Có sẵn';
      case 'borrowed':
        return 'Đang mượn';
      case 'maintenance':
        return 'Bảo trì';
      case 'out_of_order':
        return 'Hỏng';
      default:
        return equipment.status;
    }
  }
}
