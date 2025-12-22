import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart';
import '../../constants/app_colors.dart';
import '../../models/category.dart';
import '../../services/metadata_service.dart';
import '../../services/qr_code_service.dart';
import '../../utils/serial_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParsedEquipmentRow {
  final int rowNumber;
  final String name;
  final String description;
  final int quantity;
  int? categoryId;
  String? categoryName;
  String? serialNumber;

  ParsedEquipmentRow({
    required this.rowNumber,
    required this.name,
    required this.description,
    required this.quantity,
    this.categoryId,
    this.categoryName,
    this.serialNumber,
  });
}

// Main dialog function to show import preview
Future<bool?> showEquipmentImportDialog(
  BuildContext context,
  Uint8List excelBytes,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EquipmentImportPreviewDialog(excelBytes: excelBytes),
  );
}

class EquipmentImportPreviewDialog extends StatefulWidget {
  final Uint8List excelBytes;

  const EquipmentImportPreviewDialog({
    super.key,
    required this.excelBytes,
  });

  @override
  State<EquipmentImportPreviewDialog> createState() =>
      _EquipmentImportPreviewDialogState();
}

class _EquipmentImportPreviewDialogState
    extends State<EquipmentImportPreviewDialog> {
  final MetadataService _metadataService = MetadataService();
  final QrCodeService _qrCodeService = QrCodeService();
  final _supabase = Supabase.instance.client;

  List<ParsedEquipmentRow> _equipmentRows = [];
  List<Category> _categories = [];
  bool _loading = true;
  bool _generating = false;
  bool _importing = false;
  bool _showQrCodes = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _metadataService.getCategories();
      final parsedRows = await _parseExcelFile();

      setState(() {
        _categories = categories;
        _equipmentRows = parsedRows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _loading = false;
      });
    }
  }

  Future<List<ParsedEquipmentRow>> _parseExcelFile() async {
    final rows = <ParsedEquipmentRow>[];

    try {
      final excel = Excel.decodeBytes(widget.excelBytes);

      if (excel.tables.isEmpty) {
        throw Exception('Excel file is empty');
      }

      final table = excel.tables[excel.tables.keys.first];

      if (table == null || table.rows.isEmpty) {
        throw Exception('Sheet is empty');
      }

      // New format: A=number, B=name, C=description, D=date_bought, E=quantity
      for (var i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        final rowNum = i + 1;

        if (row.every((cell) => cell?.value == null)) continue;

        try {
          final name = row.length > 1 ? row[1]?.value?.toString().trim() : null;
          final description = row.length > 2 ? row[2]?.value?.toString().trim() : null;
          final quantityStr = row.length > 4 ? row[4]?.value?.toString().trim() : null;

          if (name == null || name.isEmpty) continue;
          if (description == null || description.isEmpty) continue;
          if (quantityStr == null || quantityStr.isEmpty) continue;

          final quantity = int.tryParse(quantityStr) ?? 1;

          rows.add(ParsedEquipmentRow(
            rowNumber: rowNum,
            name: name,
            description: description,
            quantity: quantity,
          ));
        } catch (e) {
          continue;
        }
      }

      return rows;
    } catch (e) {
      throw Exception('Failed to parse Excel: $e');
    }
  }

  Future<void> _generateQrCodes() async {
    // Check if all rows have categories
    final missingCategory = _equipmentRows.where((r) => r.categoryName == null);
    if (missingCategory.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select category for all equipment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _generating = true);

    try {
      // Simulate generating serial numbers with delay
      await Future.delayed(const Duration(milliseconds: 500));

      for (var row in _equipmentRows) {
        if (row.categoryName != null && row.categoryName!.isNotEmpty) {
          row.serialNumber = SerialGenerator.generateSerialNumber(row.categoryName!);
        }
        // Small delay for loading effect
        await Future.delayed(const Duration(milliseconds: 50));
      }

      setState(() {
        _generating = false;
        _showQrCodes = true;
      });
    } catch (e) {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadQrCode(ParsedEquipmentRow row) async {
    if (row.serialNumber == null) return;

    try {
      final imageBytes =
          await _qrCodeService.generateQrCodeImage(row.serialNumber!);

      if (imageBytes != null) {
        await _qrCodeService.downloadQrCode(
          imageBytes,
          'QR_${row.serialNumber}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code downloaded')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAll() async {
    setState(() => _importing = true);

    try {
      int successCount = 0;
      final errors = <String>[];

      for (var row in _equipmentRows) {
        try {
          final equipmentData = {
            'equipment_name': row.name,
            'description': row.description,
            'qty': row.quantity,
            'available_qty': row.quantity,
            'status': 'available',
            'serial_number': row.serialNumber,
            'qr_code': row.serialNumber,
            'category_id': row.categoryId,
            'created_at': DateTime.now().toIso8601String(),
          };

          await _supabase.from('equipment').insert(equipmentData);
          successCount++;
        } catch (e) {
          errors.add('Row ${row.rowNumber}: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $successCount equipment'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else if (_generating)
              _buildGenerating()
            else
              Expanded(child: _buildContent()),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _showQrCodes ? Icons.qr_code : Icons.upload_file,
          color: AppColors.primaryBlue,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showQrCodes ? 'Review & Download QR Codes' : 'Import Equipment',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _showQrCodes
                    ? 'Check the generated QR codes and download if needed'
                    : '${_equipmentRows.length} items found - Select categories',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerating() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Generating QR codes...',
              style: GoogleFonts.inter(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: _showQrCodes ? 0.8 : 2.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _equipmentRows.length,
      itemBuilder: (context, index) {
        final row = _equipmentRows[index];
        return _buildEquipmentCard(row, index);
      },
    );
  }

  Widget _buildEquipmentCard(ParsedEquipmentRow row, int index) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment info
            Text(
              row.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              row.description,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              'Qty: ${row.quantity}',
              style: GoogleFonts.inter(fontSize: 10),
            ),
            const SizedBox(height: 6),

            // Category dropdown or QR code
            if (!_showQrCodes)
              DropdownButtonFormField<int>(
                initialValue: row.categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 12),
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(
                      cat.name,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    row.categoryId = value;
                    row.categoryName =
                        _categories.firstWhere((c) => c.id == value).name;
                  });
                },
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (row.serialNumber != null)
                      _qrCodeService.buildQrCodeWidget(
                        row.serialNumber!,
                        size: 200,
                        showData: false,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      row.serialNumber ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadQrCode(row),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        if (!_showQrCodes)
          ElevatedButton.icon(
            onPressed: _generating ? null : _generateQrCodes,
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate QR Codes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _importing ? null : _saveAll,
            icon: _importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_importing ? 'Saving...' : 'Save All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

// Deprecated - keeping for compatibility
class EquipmentImportPreviewScreen extends StatefulWidget {
  final Uint8List excelBytes;

  const EquipmentImportPreviewScreen({
    super.key,
    required this.excelBytes,
  });

  @override
  State<EquipmentImportPreviewScreen> createState() =>
      _EquipmentImportPreviewScreenState();
}

class _EquipmentImportPreviewScreenState
    extends State<EquipmentImportPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    // Redirect to dialog
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await showEquipmentImportDialog(context, widget.excelBytes);
      if (!mounted) return;
      if (!context.mounted) return;
      Navigator.of(context).pop(result);
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
