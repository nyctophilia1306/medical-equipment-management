import 'package:flutter/material.dart';
import '../models/borrow_request.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Widget that displays a group of borrow requests sharing the same request serial
/// Shows request serial, user info, dates, and expandable equipment list
class GroupedBorrowRequestCard extends StatefulWidget {
  final String requestSerial;
  final List<BorrowRequest> requests;
  final VoidCallback? onTap;
  final VoidCallback? onReturn;
  final VoidCallback? onApprove; // New: Admin approval
  final VoidCallback? onReject; // New: Admin rejection
  final Function(String equipmentId)?
  onEditEquipment; // New: Admin edit equipment
  final Function(String equipmentId)?
  onDeleteEquipment; // New: Admin delete equipment

  const GroupedBorrowRequestCard({
    super.key,
    required this.requestSerial,
    required this.requests,
    this.onTap,
    this.onReturn,
    this.onApprove,
    this.onReject,
    this.onEditEquipment,
    this.onDeleteEquipment,
  });

  @override
  State<GroupedBorrowRequestCard> createState() =>
      _GroupedBorrowRequestCardState();
}

class _GroupedBorrowRequestCardState extends State<GroupedBorrowRequestCard> {
  bool _isExpanded = false;

  // Get the first request for common information
  BorrowRequest get _firstRequest => widget.requests.first;

  // Calculate how many equipment items are returned
  int get _returnedCount =>
      widget.requests.where((r) => r.isEquipmentReturned).length;

  // Check if all equipment is returned
  bool get _allReturned => _returnedCount == widget.requests.length;

  // Check if partially returned
  bool get _partiallyReturned => _returnedCount > 0 && !_allReturned;

  // Check if all requests are pending (waiting for approval)
  bool get _isPending =>
      widget.requests.every((r) => r.status.toLowerCase() == 'pending');

  // Check if all requests are rejected
  bool get _isRejected =>
      widget.requests.every((r) => r.status.toLowerCase() == 'rejected');

  // Check if all requests are approved
  bool get _isApproved =>
      widget.requests.every((r) => r.status.toLowerCase() == 'approved');

  // Check if any equipment is overdue
  bool get _isOverdue =>
      widget.requests.any((r) => r.isOverdueByDate && !r.isEquipmentReturned);

  Color get _statusColor {
    if (_allReturned) return Colors.green;
    if (_isRejected) return Colors.grey; // Rejected requests in grey
    if (_isPending) return Colors.orange; // Pending requests in orange
    if (_isApproved) return Colors.blue; // Approved requests in blue
    if (_isOverdue) return Colors.red;
    if (_partiallyReturned) return Colors.orange;
    return AppColors.primaryBlue;
  }

  String _getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_allReturned) return l10n.returned; // 'Returned' / 'Đã trả'
    if (_isRejected) return l10n.rejected; // 'Rejected' / 'Từ chối'
    if (_isPending) return l10n.pendingApproval; // 'Pending' / 'Chờ duyệt'
    if (_isApproved) return l10n.approvedLabel; // 'Approved' / 'Đã duyệt'
    if (_partiallyReturned) {
      return '${l10n.returned} $_returnedCount/${widget.requests.length}'; // 'Returned X/Y' / 'Đã trả X/Y'
    }
    if (_isOverdue) return l10n.overdue; // 'Overdue' / 'Quá hạn'
    return l10n.active; // 'Active' / 'Đang hoạt động'
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _isRejected ? 1 : 2, // Reduced elevation for rejected
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isRejected
          ? Colors.grey[100]
          : null, // Light grey background for rejected
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isRejected ? Colors.grey[400]! : _statusColor.withValues(alpha: 0.3), 
          width: _isRejected ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          widget.onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Serial, User, Badge
              Row(
                children: [
                  // Request Serial
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'REQ #${widget.requestSerial}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Equipment Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, size: 14, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.requests.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Expand/Collapse Icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // User Information
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: _isRejected ? Colors.grey[400] : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _firstRequest.userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _isRejected ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dates Information
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      context: context,
                      icon: Icons.calendar_today,
                      label: AppLocalizations.of(context)!.borrowDate,
                      date: _firstRequest.borrowDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInfo(
                      context: context,
                      icon: Icons.event,
                      label: AppLocalizations.of(context)!.expectedReturnDate,
                      date: _firstRequest.expectedReturnDate,
                      isOverdue: _isOverdue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(context),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isRejected ? Colors.grey[600] : _statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Admin Actions for Pending Requests (hide for rejected/approved)
                  if (_isPending &&
                      !_isRejected &&
                      !_isApproved &&
                      (widget.onApprove != null ||
                          widget.onReject != null)) ...[
                    if (widget.onApprove != null)
                      ElevatedButton.icon(
                        onPressed: widget.onApprove,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: Text(AppLocalizations.of(context)!.approve, style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (widget.onReject != null)
                      OutlinedButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: Text(AppLocalizations.of(context)!.reject, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],

                  // Mark as Return Button (only if approved and not all returned and not rejected)
                  if (!_allReturned &&
                      _isApproved &&
                      !_isRejected &&
                      widget.onReturn != null)
                    TextButton.icon(
                      onPressed: widget.onReturn,
                      icon: const Icon(Icons.assignment_return, size: 16),
                      label: Text(AppLocalizations.of(context)!.returnEquipment, style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                ],
              ),

              // Expandable Equipment List
              if (_isExpanded) ...[
                const Divider(height: 24),
                _buildEquipmentList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo({
    required BuildContext context,
    required IconData icon,
    required String label,
    required DateTime date,
    bool isOverdue = false,
  }) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 13, 
          color: _isRejected ? Colors.grey[400] : (isOverdue ? Colors.red : Colors.grey),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9, 
                  color: _isRejected ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _isRejected ? Colors.grey[600] : (isOverdue ? Colors.red : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.equipmentList,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _isRejected ? Colors.grey[600] : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.requests.map((request) => _buildEquipmentItem(request)),
      ],
    );
  }

  Widget _buildEquipmentItem(BorrowRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: request.isEquipmentReturned
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: request.isEquipmentReturned
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Equipment Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: request.isEquipmentReturned
                  ? Colors.green.withValues(alpha: 0.1)
                  : AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medical_services,
              size: 20,
              color: request.isEquipmentReturned
                  ? Colors.green
                  : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),

          // Equipment Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.equipmentName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: request.isEquipmentReturned
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${request.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Return Status Icon
          if (request.isEquipmentReturned)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else if (request.isOverdueByDate)
            const Icon(Icons.warning, color: Colors.red, size: 24),

          // Admin CRUD Actions for Equipment
          if (widget.onEditEquipment != null ||
              widget.onDeleteEquipment != null) ...[
            const SizedBox(width: 8),
            if (widget.onEditEquipment != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => widget.onEditEquipment!(request.equipmentId),
                tooltip: 'Edit Equipment',
              ),
            const SizedBox(width: 4),
            if (widget.onDeleteEquipment != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => widget.onDeleteEquipment!(request.equipmentId),
                tooltip: 'Delete Equipment',
              ),
          ],
        ],
      ),
    );
  }
}
