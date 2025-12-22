class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'MedEquip Manager';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Manage and Track Medical Equipment Borrowing with Ease';
  static const String appTagline = 'Professional • Efficient • Trustworthy';

  // User Roles
  static const String roleUser = 'user';
  static const String roleManager = 'manager';
  static const String roleAdmin = 'admin';

  // Equipment Status
  static const String statusAvailable = 'available';
  static const String statusBorrowed = 'borrowed';
  static const String statusMaintenance = 'maintenance';
  static const String statusOutOfOrder = 'out_of_order';

  // Borrow Request Status
  static const String requestPending = 'pending';
  static const String requestApproved = 'approved';
  static const String requestRejected = 'rejected';
  static const String requestReturned = 'returned';
  static const String requestOverdue = 'overdue';

  // Equipment Categories
  static const List<String> equipmentCategories = [
    'Diagnostic Equipment',
    'Laboratory Instruments',
    'Surgical Tools',
    'Monitoring Devices',
    'Imaging Equipment',
    'Therapeutic Equipment',
    'Life Support Systems',
    'Safety Equipment',
    'Consumables',
    'Other',
  ];

  // Locations
  static const List<String> defaultLocations = [
    'Main Laboratory',
    'Emergency Room',
    'Operating Theater 1',
    'Operating Theater 2',
    'ICU',
    'Radiology Department',
    'Pharmacy',
    'Storage Room A',
    'Storage Room B',
    'Maintenance Workshop',
  ];

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Grid Layout
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.8;
  static const double gridSpacing = 16.0;

  // Padding and Margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Default Values
  static const int defaultBorrowDurationDays = 7;
  static const int maxBorrowDurationDays = 30;
  static const int lowStockThreshold = 5;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Error Messages
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please sign in again.';
  static const String errorPermission = 'You don\'t have permission to perform this action.';
  static const String errorNotFound = 'Item not found.';
  static const String errorInvalidInput = 'Please check your input and try again.';

  // Success Messages
  static const String successSaved = 'Saved successfully!';
  static const String successDeleted = 'Deleted successfully!';
  static const String successUpdated = 'Updated successfully!';
  static const String successBorrowRequested = 'Borrow request submitted successfully!';
  static const String successReturned = 'Item returned successfully!';

  // Placeholder Texts
  static const String placeholderSearch = 'Search equipment...';
  static const String placeholderNoData = 'No data available';
  static const String placeholderLoading = 'Loading...';
  static const String placeholderNoEquipment = 'No equipment found';
  static const String placeholderNoBorrowRequests = 'No borrow requests found';
  static const String placeholderNoUsers = 'No users found';

  // API Endpoints (if using custom backend)
  static const String baseUrl = 'https://your-api-domain.com/api/v1';
  static const String authEndpoint = '/auth';
  static const String equipmentEndpoint = '/equipment';
  static const String borrowRequestEndpoint = '/borrow-requests';
  static const String usersEndpoint = '/users';

  // Storage Keys
  static const String storageKeyUser = 'user';
  static const String storageKeyTheme = 'theme';
  static const String storageKeyLanguage = 'language';
  static const String storageKeyFirstTime = 'first_time';

  // Supabase Configuration (replace with your actual Supabase details)
  static const String supabaseUrl = 'https://aowxsljcxqfkrsvikmzf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvd3hzbGpjeHFma3JzdmlrbXpmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTkzNDQxOCwiZXhwIjoyMDc1NTEwNDE4fQ.Iukr26GpghAwXxhPiuU-xFyuBYLHbKiv4l74oCSPaDE';

  // QR Code Configuration
  static const double qrCodeSize = 200.0;
  static const String qrCodePrefix = 'MEDEQUIP_';

  // Chart Configuration
  static const int chartAnimationDuration = 1000;
  static const double chartBarWidth = 12.0;
  static const double chartRadius = 8.0;

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxQuantity = 9999;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
}