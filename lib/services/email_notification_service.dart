import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Service for sending email notifications through Supabase Edge Functions
class EmailNotificationService {
  static final EmailNotificationService _instance =
      EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send email notification for new borrow request (Admin notification)
  Future<void> sendNewRequestNotification({
    required String adminEmail,
    required String userName,
    required String equipmentName,
    required String requestId,
  }) async {
    try {
      Logger.info('Sending new request notification to $adminEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'new_request',
          'to': adminEmail,
          'data': {
            'user_name': userName,
            'equipment_name': equipmentName,
            'request_id': requestId,
          },
        },
      );

      Logger.info('New request notification sent successfully');
    } catch (e) {
      Logger.error('Failed to send new request notification: $e');
    }
  }

  /// Send email notification for approved borrow request
  Future<void> sendApprovedNotification({
    required String userEmail,
    required String userName,
    required String equipmentName,
    required DateTime borrowDate,
    required DateTime returnDate,
  }) async {
    try {
      Logger.info('Sending approval notification to $userEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'request_approved',
          'to': userEmail,
          'data': {
            'user_name': userName,
            'equipment_name': equipmentName,
            'borrow_date': borrowDate.toIso8601String(),
            'return_date': returnDate.toIso8601String(),
          },
        },
      );

      Logger.info('Approval notification sent successfully');
    } catch (e) {
      Logger.error('Failed to send approval notification: $e');
    }
  }

  /// Send email notification for rejected borrow request
  Future<void> sendRejectedNotification({
    required String userEmail,
    required String userName,
    required String equipmentName,
    String? reason,
  }) async {
    try {
      Logger.info('Sending rejection notification to $userEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'request_rejected',
          'to': userEmail,
          'data': {
            'user_name': userName,
            'equipment_name': equipmentName,
            'reason': reason ?? 'Không có lý do cụ thể',
          },
        },
      );

      Logger.info('Rejection notification sent successfully');
    } catch (e) {
      Logger.error('Failed to send rejection notification: $e');
    }
  }

  /// Send email notification for overdue equipment (Admin and User)
  Future<void> sendOverdueNotification({
    required String userEmail,
    required String userName,
    required String equipmentName,
    required DateTime returnDate,
    required int daysOverdue,
    bool sendToAdmin = false,
    String? adminEmail,
  }) async {
    try {
      Logger.info('Sending overdue notification to $userEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'equipment_overdue',
          'to': userEmail,
          'data': {
            'user_name': userName,
            'equipment_name': equipmentName,
            'return_date': returnDate.toIso8601String(),
            'days_overdue': daysOverdue,
          },
        },
      );

      // Also notify admin if requested
      if (sendToAdmin && adminEmail != null) {
        await _supabase.functions.invoke(
          'send-email',
          body: {
            'type': 'equipment_overdue_admin',
            'to': adminEmail,
            'data': {
              'user_name': userName,
              'equipment_name': equipmentName,
              'return_date': returnDate.toIso8601String(),
              'days_overdue': daysOverdue,
            },
          },
        );
      }

      Logger.info('Overdue notification sent successfully');
    } catch (e) {
      Logger.error('Failed to send overdue notification: $e');
    }
  }

  /// Send email notification for return reminder (1 day before due date)
  Future<void> sendReturnReminderNotification({
    required String userEmail,
    required String userName,
    required String equipmentName,
    required DateTime returnDate,
  }) async {
    try {
      Logger.info('Sending return reminder to $userEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'return_reminder',
          'to': userEmail,
          'data': {
            'user_name': userName,
            'equipment_name': equipmentName,
            'return_date': returnDate.toIso8601String(),
          },
        },
      );

      Logger.info('Return reminder sent successfully');
    } catch (e) {
      Logger.error('Failed to send return reminder: $e');
    }
  }

  /// Send welcome email for new self-registered users
  Future<void> sendWelcomeEmail({
    required String userEmail,
    required String userName,
  }) async {
    try {
      Logger.info('Sending welcome email to $userEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'welcome',
          'to': userEmail,
          'data': {'user_name': userName},
        },
      );

      Logger.info('Welcome email sent successfully');
    } catch (e) {
      Logger.error('Failed to send welcome email: $e');
    }
  }

  /// Send password reset notification
  Future<void> sendPasswordResetNotification({
    required String userEmail,
    required String userName,
  }) async {
    try {
      Logger.info('Sending password reset notification to $userEmail');

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': 'password_reset',
          'to': userEmail,
          'data': {'user_name': userName},
        },
      );

      Logger.info('Password reset notification sent successfully');
    } catch (e) {
      Logger.error('Failed to send password reset notification: $e');
    }
  }

  /// Get all admin emails with notification enabled
  Future<List<String>> getAdminEmailsForNotifications() async {
    try {
      final response = await _supabase
          .from('users')
          .select('email, user_settings!inner(email_notifications)')
          .eq('role_id', 0) // Admin role
          .eq('user_settings.email_notifications', true);

      final List<String> adminEmails = [];
      for (final row in response as List) {
        final email = row['email'];
        if (email != null && email.toString().isNotEmpty) {
          adminEmails.add(email.toString());
        }
      }

      Logger.info(
        'Found ${adminEmails.length} admins with notifications enabled',
      );
      return adminEmails;
    } catch (e) {
      Logger.error('Failed to get admin emails: $e');
      return [];
    }
  }

  /// Check if user has email notifications enabled
  Future<bool> isEmailNotificationEnabled(String userId) async {
    try {
      final response = await _supabase
          .from('user_settings')
          .select('email_notifications')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return response['email_notifications'] == true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to check email notification setting: $e');
      return false;
    }
  }

  /// Send batch notifications to multiple users
  Future<void> sendBatchNotifications({
    required List<String> emails,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    for (final email in emails) {
      try {
        await _supabase.functions.invoke(
          'send-email',
          body: {'type': type, 'to': email, 'data': data},
        );
      } catch (e) {
        Logger.error('Failed to send notification to $email: $e');
        // Continue with other emails even if one fails
      }
    }
  }
}
