import 'package:flutter/material.dart';
import '../../models/borrow_request.dart';
import '../../services/borrow_service.dart';
import '../../widgets/grouped_borrow_request_card.dart';

/// Tab showing completed/returned borrow requests
/// Displays requests where all equipment is marked as returned
class ReturnedRequestsTab extends StatefulWidget {
  const ReturnedRequestsTab({super.key});

  @override
  State<ReturnedRequestsTab> createState() => _ReturnedRequestsTabState();
}

class _ReturnedRequestsTabState extends State<ReturnedRequestsTab> {
  final BorrowService _borrowService = BorrowService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  Map<String, List<BorrowRequest>> _groupedRequests = {};
  String _searchMode = 'serial'; // 'serial', 'user', or 'date'
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadReturnedRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReturnedRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get requests marked as returned
      final rawRequests = await _borrowService.getBorrowRequests(
        isReturned: true,
      );

      // Convert raw data to BorrowRequest objects
      final requests = rawRequests.map((data) {
        final equipmentData = data['equipment'] as Map<String, dynamic>?;
        final userData = data['users'] as Map<String, dynamic>?;

        return BorrowRequest(
          id: data['request_id'] as String,
          equipmentId: data['equipment_id'] as String,
          equipmentName:
              equipmentData?['equipment_name'] as String? ?? 'Unknown',
          equipmentSerialNumber: equipmentData?['serial_number'] as String?,
          userId: data['user_id'] as String,
          userName: userData?['full_name'] as String? ?? 'Unknown',
          requestedBy: data['created_by'] as String? ?? '',
          requestedByName: 'Manager',
          quantity: data['quantity'] as int? ?? 0,
          borrowDate: DateTime.parse(data['request_date'] as String),
          expectedReturnDate: DateTime.parse(data['return_date'] as String),
          actualReturnDate: data['actual_return_date'] != null
              ? DateTime.parse(data['actual_return_date'] as String)
              : null,
          status: data['status'] as String? ?? 'returned',
          purpose: data['purpose'] as String? ?? '',
          notes: data['notes'] as String?,
          createdAt: DateTime.parse(data['created_at'] as String),
          updatedAt: data['updated_at'] != null
              ? DateTime.parse(data['updated_at'] as String)
              : null,
          requestSerial: data['request_serial'] as String?,
          isEquipmentReturned: data['is_equipment_returned'] as bool? ?? true,
        );
      }).toList();

      setState(() {
        _groupedRequests = _groupRequestsBySerial(requests);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load returned requests: $e';
      });
    }
  }

  Map<String, List<BorrowRequest>> _groupRequestsBySerial(
    List<BorrowRequest> requests,
  ) {
    final Map<String, List<BorrowRequest>> grouped = {};

    for (final request in requests) {
      final serial =
          request.requestSerial ?? 'LEGACY-${request.id.substring(0, 8)}';
      grouped.putIfAbsent(serial, () => []).add(request);
    }

    // Filter to only show fully returned requests
    final fullyReturned = <String, List<BorrowRequest>>{};
    for (final entry in grouped.entries) {
      final allReturned = entry.value.every((r) => r.isEquipmentReturned);
      if (allReturned) {
        fullyReturned[entry.key] = entry.value;
      }
    }

    return fullyReturned;
  }

  List<MapEntry<String, List<BorrowRequest>>> _getFilteredRequests() {
    final entries = _groupedRequests.entries.toList();
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty && _selectedDate == null) {
      return entries;
    }

    return entries.where((entry) {
      final requests = entry.value;
      final firstRequest = requests.first;

      // Date filter
      if (_selectedDate != null) {
        final returnDate =
            firstRequest.actualReturnDate ?? firstRequest.expectedReturnDate;
        final isSameDate =
            returnDate.year == _selectedDate!.year &&
            returnDate.month == _selectedDate!.month &&
            returnDate.day == _selectedDate!.day;
        if (!isSameDate) return false;
      }

      // Text search filter
      if (query.isEmpty) return true;

      switch (_searchMode) {
        case 'serial':
          return entry.key.toLowerCase().contains(query);
        case 'user':
          return firstRequest.userName.toLowerCase().contains(query);
        case 'date':
          final returnDate =
              firstRequest.actualReturnDate ?? firstRequest.expectedReturnDate;
          final dateStr =
              '${returnDate.day}/${returnDate.month}/${returnDate.year}';
          return dateStr.contains(query);
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Mode Selector
              Row(
                children: [
                  _buildSearchModeChip('Serial', 'serial'),
                  const SizedBox(width: 8),
                  _buildSearchModeChip('Người Dùng', 'user'),
                  const SizedBox(width: 8),
                  _buildSearchModeChip('Ngày', 'date'),
                  const Spacer(),

                  // Date Filter Button
                  if (_selectedDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _clearDateFilter,
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _selectDate,
                    tooltip: 'Filter by return date',
                    color: _selectedDate != null ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),

        // Content Area
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildSearchModeChip(String label, String mode) {
    final isSelected = _searchMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _searchMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getSearchHint() {
    switch (_searchMode) {
      case 'serial':
        return 'Tìm theo số serial yêu cầu (ví dụ: 15012501)';
      case 'user':
        return 'Search by user name';
      case 'date':
        return 'Search by return date (e.g., 15/01/2025)';
      default:
        return 'Search...';
    }
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReturnedRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredRequests = _getFilteredRequests();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedDate != null
                  ? 'No returned requests match your search'
                  : 'No returned requests yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReturnedRequests,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final entry = filteredRequests[index];
          final requestSerial = entry.key;
          final requests = entry.value;

          return GroupedBorrowRequestCard(
            requestSerial: requestSerial,
            requests: requests,
            onReturn: null, // No return button for already returned items
          );
        },
      ),
    );
  }
}
