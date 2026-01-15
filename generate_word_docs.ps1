# PowerShell script to generate Word documents from Dart files with explanations

# File explanations mapping
$fileExplanations = @{
    "main.dart" = @"
FILE PURPOSE:
This is the entry point of the Flutter application. It initializes the app, sets up Supabase authentication, configures localization, and manages the authentication flow.

KEY FUNCTIONS:
- main(): Initializes Flutter bindings and Supabase, then runs the app
- MedEquipApp: Root widget that configures MaterialApp with theme, localization, and routing
- AuthGate: Handles authentication state checking and redirects users to appropriate screens based on their authentication status
"@

    # Constants
    "constants\app_colors.dart" = @"
FILE PURPOSE:
Defines the color palette used throughout the application for consistent UI styling.

KEY FUNCTIONS:
- Provides centralized color definitions
- Ensures consistent visual design across the app
"@

    "constants\app_theme.dart" = @"
FILE PURPOSE:
Defines the application's theme configuration including light and dark theme settings.

KEY FUNCTIONS:
- Configures MaterialApp theme properties
- Sets up color schemes, text styles, and component themes
- Provides consistent look and feel across the application
"@

    "constants\constants.dart" = @"
FILE PURPOSE:
Contains global constants used throughout the application such as API keys, URLs, and configuration values.

KEY FUNCTIONS:
- Stores Supabase URL and API keys
- Defines application-wide constant values
- Centralizes configuration management
"@

    "constants\database_translations.dart" = @"
FILE PURPOSE:
Manages translations and mappings for database values to display-friendly text in multiple languages.

KEY FUNCTIONS:
- Translates database enum values to user-friendly text
- Supports multi-language localization
- Maps status codes to readable labels
"@

    # Models
    "models\audit_log.dart" = @"
FILE PURPOSE:
Data model for audit log entries that track all system activities and changes.

KEY FUNCTIONS:
- Represents audit trail records
- Tracks who, what, when, and where actions occurred
- Provides serialization/deserialization for database operations
"@

    "models\borrow_request.dart" = @"
FILE PURPOSE:
Data model representing equipment borrowing requests made by users.

KEY FUNCTIONS:
- Stores borrowing details (requester, equipment, dates, status)
- Manages borrow request lifecycle
- Provides serialization/deserialization for database operations
"@

    "models\category.dart" = @"
FILE PURPOSE:
Data model for equipment categories used to organize and classify medical equipment.

KEY FUNCTIONS:
- Represents equipment categories
- Stores category metadata (name, description, ID)
- Provides serialization/deserialization for database operations
"@

    "models\equipment.dart" = @"
FILE PURPOSE:
Core data model representing medical equipment items in the system.

KEY FUNCTIONS:
- Stores comprehensive equipment information (name, serial, status, category, location)
- Manages equipment lifecycle and availability
- Provides serialization/deserialization for database operations
"@

    "models\inventory_log.dart" = @"
FILE PURPOSE:
Data model for tracking inventory changes and stock movements.

KEY FUNCTIONS:
- Records inventory transactions
- Tracks quantity changes and reasons
- Provides audit trail for inventory management
"@

    "models\user.dart" = @"
FILE PURPOSE:
Data model representing system users with their roles and permissions.

KEY FUNCTIONS:
- Stores user profile information
- Manages user roles and authentication data
- Provides serialization/deserialization for database operations
"@

    "models\user_settings.dart" = @"
FILE PURPOSE:
Data model for storing user preferences and application settings.

KEY FUNCTIONS:
- Manages user-specific settings (language, notifications, theme)
- Persists user preferences
- Provides serialization/deserialization for database operations
"@

    # Providers
    "providers\locale_provider.dart" = @"
FILE PURPOSE:
State management provider for handling application language/locale changes.

KEY FUNCTIONS:
- Manages current locale state
- Persists language preference
- Notifies widgets when locale changes
- Integrates with user settings
"@

    # Services
    "services\audit_log_service.dart" = @"
FILE PURPOSE:
Service layer for managing audit logs - recording and retrieving system activity logs.

KEY FUNCTIONS:
- Creates audit log entries for all system actions
- Retrieves audit logs with filtering and pagination
- Provides audit trail for compliance and debugging
"@

    "services\auth_service.dart" = @"
FILE PURPOSE:
Handles all authentication operations including sign in, sign up, password reset, and session management.

KEY FUNCTIONS:
- Manages user authentication with Supabase
- Handles sign in/sign up/sign out operations
- Manages password reset functionality
- Maintains user session state
"@

    "services\borrow_service.dart" = @"
FILE PURPOSE:
Service layer for managing equipment borrowing operations.

KEY FUNCTIONS:
- Creates and updates borrow requests
- Manages approval/rejection workflow
- Handles equipment return process
- Retrieves borrow history and active requests
"@

    "services\data_service.dart" = @"
FILE PURPOSE:
Core data service providing CRUD operations for all database entities.

KEY FUNCTIONS:
- Generic data access layer for Supabase operations
- Handles create, read, update, delete operations
- Provides data fetching with filtering and sorting
- Manages relationships between entities
"@

    "services\email_notification_service.dart" = @"
FILE PURPOSE:
Manages email notifications for various system events.

KEY FUNCTIONS:
- Sends email notifications for borrow requests
- Notifies users of approval/rejection/return events
- Integrates with email service provider
- Handles email templates and formatting
"@

    "services\equipment_identifier_service.dart" = @"
FILE PURPOSE:
Service for generating and validating unique equipment identifiers.

KEY FUNCTIONS:
- Generates unique equipment IDs
- Validates identifier formats
- Ensures uniqueness across the system
- Manages identifier schemas
"@

    "services\excel_import_service.dart" = @"
FILE PURPOSE:
Handles importing equipment data from Excel files.

KEY FUNCTIONS:
- Parses Excel files containing equipment data
- Validates imported data
- Bulk imports equipment into database
- Provides import preview and error reporting
"@

    "services\metadata_service.dart" = @"
FILE PURPOSE:
Manages system metadata and reference data.

KEY FUNCTIONS:
- Retrieves lookup data (categories, statuses, etc.)
- Caches frequently accessed metadata
- Provides dropdown options for forms
"@

    "services\qr_code_service.dart" = @"
FILE PURPOSE:
Handles QR code generation and scanning operations for equipment.

KEY FUNCTIONS:
- Generates QR codes for equipment
- Scans and decodes QR codes
- Links QR codes to equipment records
- Enables quick equipment lookup via QR scanning
"@

    "services\statistics_service.dart" = @"
FILE PURPOSE:
Provides statistical data and analytics for dashboards and reports.

KEY FUNCTIONS:
- Calculates equipment usage statistics
- Generates borrowing trends and analytics
- Provides data for charts and reports
- Aggregates system-wide metrics
"@

    "services\user_service.dart" = @"
FILE PURPOSE:
Service layer for managing user accounts and profiles.

KEY FUNCTIONS:
- Creates and updates user profiles
- Manages user roles and permissions
- Retrieves user information
- Handles user account operations
"@

    "services\user_settings_service.dart" = @"
FILE PURPOSE:
Manages user preferences and application settings.

KEY FUNCTIONS:
- Saves and retrieves user settings
- Manages language preferences
- Handles notification settings
- Persists user customizations
"@

    # Utils
    "utils\equipment_identifiers.dart" = @"
FILE PURPOSE:
Utility functions for handling equipment identifier operations.

KEY FUNCTIONS:
- Identifier format validation
- ID parsing and formatting
- Identifier utility functions
"@

    "utils\equipment_utils.dart" = @"
FILE PURPOSE:
General utility functions for equipment-related operations.

KEY FUNCTIONS:
- Common equipment operations
- Helper functions for equipment data manipulation
- Equipment-specific formatting utilities
"@

    "utils\equipment_validation.dart" = @"
FILE PURPOSE:
Validation logic for equipment data and forms.

KEY FUNCTIONS:
- Validates equipment input data
- Checks required fields and formats
- Provides validation error messages
- Ensures data integrity
"@

    "utils\logger.dart" = @"
FILE PURPOSE:
Logging utility for debugging and monitoring application behavior.

KEY FUNCTIONS:
- Provides structured logging
- Logs errors, warnings, and info messages
- Helps with debugging and troubleshooting
"@

    "utils\serial_generator.dart" = @"
FILE PURPOSE:
Generates unique serial numbers for equipment.

KEY FUNCTIONS:
- Creates unique serial numbers
- Ensures serial number uniqueness
- Follows configurable serial number formats
"@

    # Widgets
    "widgets\continuous_scan_popup.dart" = @"
FILE PURPOSE:
UI widget for continuous QR code scanning functionality.

KEY FUNCTIONS:
- Displays QR scanner in a popup dialog
- Allows continuous scanning without closing
- Provides feedback for successful scans
"@

    "widgets\equipment_card.dart" = @"
FILE PURPOSE:
Reusable card widget for displaying equipment information in lists.

KEY FUNCTIONS:
- Shows equipment summary (name, status, location)
- Provides consistent card layout
- Handles tap interactions for equipment details
"@

    "widgets\error_dialog.dart" = @"
FILE PURPOSE:
Reusable dialog widget for displaying error messages.

KEY FUNCTIONS:
- Shows user-friendly error messages
- Provides consistent error UI
- Handles error dismissal
"@

    "widgets\grouped_borrow_request_card.dart" = @"
FILE PURPOSE:
Displays multiple borrow requests grouped together in a card format.

KEY FUNCTIONS:
- Shows grouped borrow request information
- Provides expandable/collapsible view
- Handles batch operations on grouped requests
"@

    "widgets\loading_indicator.dart" = @"
FILE PURPOSE:
Reusable loading indicator widget for async operations.

KEY FUNCTIONS:
- Shows loading spinner during data fetches
- Provides consistent loading UI
- Customizable loading message
"@

    "widgets\qr_scanner_widget.dart" = @"
FILE PURPOSE:
Core QR code scanner widget component.

KEY FUNCTIONS:
- Integrates camera for QR scanning
- Handles QR code detection and parsing
- Provides scan result callbacks
"@

    "widgets\qr_scan_return_dialog.dart" = @"
FILE PURPOSE:
Dialog widget for returning equipment via QR code scanning.

KEY FUNCTIONS:
- Combines QR scanning with return workflow
- Validates scanned equipment for return
- Confirms return operations
"@

    # Screens - Admin
    "screens\admin\admin_dashboard_screen.dart" = @"
FILE PURPOSE:
Main dashboard screen for administrators showing system overview and quick actions.

KEY FUNCTIONS:
- Displays admin-specific metrics and statistics
- Provides navigation to admin features
- Shows system health and alerts
"@

    "screens\admin\analytics_screen.dart" = @"
FILE PURPOSE:
Analytics and reporting screen showing charts and statistics.

KEY FUNCTIONS:
- Displays usage analytics and trends
- Shows charts and graphs
- Provides data export functionality
- Filters data by date ranges
"@

    "screens\admin\audit_logs_screen.dart" = @"
FILE PURPOSE:
Screen for viewing and searching system audit logs.

KEY FUNCTIONS:
- Displays chronological list of system actions
- Provides search and filter functionality
- Shows detailed audit information
- Supports audit log export
"@

    "screens\admin\category_management_screen.dart" = @"
FILE PURPOSE:
Screen for managing equipment categories (CRUD operations).

KEY FUNCTIONS:
- Lists all equipment categories
- Creates new categories
- Edits existing categories
- Deletes unused categories
"@

    "screens\admin\user_management_screen.dart" = @"
FILE PURPOSE:
Screen for managing user accounts and permissions.

KEY FUNCTIONS:
- Lists all system users
- Creates new user accounts
- Edits user roles and permissions
- Deactivates/activates user accounts
"@

    # Screens - Auth
    "screens\auth\sign_in_screen.dart" = @"
FILE PURPOSE:
User authentication screen for signing into the application.

KEY FUNCTIONS:
- Provides email/password login form
- Handles authentication submission
- Shows error messages for failed login
- Provides link to sign up and password reset
- Includes guest access option
"@

    "screens\auth\sign_up_screen.dart" = @"
FILE PURPOSE:
User registration screen for creating new accounts.

KEY FUNCTIONS:
- Provides registration form with required fields
- Validates user input
- Creates new user account
- Handles registration errors
- Redirects to sign in after successful registration
"@

    # Screens - Borrow
    "screens\borrow\borrow_list_tab.dart" = @"
FILE PURPOSE:
Tab displaying active borrow requests in the borrow management screen.

KEY FUNCTIONS:
- Lists pending and approved borrow requests
- Provides filtering and sorting options
- Shows request details and status
- Enables request approval/rejection actions
"@

    "screens\borrow\borrow_management_screen.dart" = @"
FILE PURPOSE:
Main screen for managing all borrow requests with tabs for different views.

KEY FUNCTIONS:
- Container for borrow request tabs
- Provides navigation between active and returned requests
- Shows summary statistics
- Enables bulk actions on requests
"@

    "screens\borrow\returned_requests_tab.dart" = @"
FILE PURPOSE:
Tab displaying returned/completed borrow requests.

KEY FUNCTIONS:
- Lists historical borrow records
- Provides filtering by date and user
- Shows return details and timestamps
- Enables viewing of completed request details
"@

    "screens\borrow\return_equipment_dialog.dart" = @"
FILE PURPOSE:
Dialog for processing equipment returns.

KEY FUNCTIONS:
- Displays equipment return form
- Validates return conditions
- Records return timestamp and notes
- Updates equipment status to available
"@

    # Screens - Dashboard
    "screens\dashboard\main_dashboard.dart" = @"
FILE PURPOSE:
Main dashboard screen with navigation drawer and role-based menu options.

KEY FUNCTIONS:
- Provides main navigation structure
- Shows different options based on user role
- Displays key metrics and statistics
- Enables quick access to common functions
"@

    # Screens - Equipment
    "screens\equipment\equipment_catalog_screen.dart" = @"
FILE PURPOSE:
Screen displaying searchable catalog of all equipment.

KEY FUNCTIONS:
- Lists all equipment with search/filter
- Shows equipment availability status
- Enables QR code scanning for quick lookup
- Provides navigation to equipment details
- Allows creating borrow requests
"@

    "screens\equipment\equipment_form_screen.dart" = @"
FILE PURPOSE:
Form screen for creating and editing equipment records.

KEY FUNCTIONS:
- Provides input form for equipment details
- Validates equipment data
- Generates equipment identifiers
- Saves new or updated equipment
- Generates QR codes for equipment
"@

    "screens\equipment\equipment_import_preview_screen.dart" = @"
FILE PURPOSE:
Preview screen for bulk equipment imports from Excel files.

KEY FUNCTIONS:
- Displays parsed Excel data
- Shows validation errors and warnings
- Allows editing before import
- Executes bulk import to database
- Reports import success/failure statistics
"@

    # Screens - Settings
    "screens\settings\settings_screen.dart" = @"
FILE PURPOSE:
User settings screen for managing preferences and profile.

KEY FUNCTIONS:
- Displays user profile information
- Allows language selection
- Manages notification preferences
- Provides logout functionality
- Shows app version and about information
"@
}

# Create Word documents
Add-Type -AssemblyName Microsoft.Office.Interop.Word

$word = New-Object -ComObject Word.Application
$word.Visible = $false

$libPath = "c:\Users\PC\Documents\DATN\medical\flutter_application_1\lib"
$outputPath = "c:\Users\PC\Documents\DATN\medical\flutter_application_1\lib_documentation"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

Write-Host "Starting Word document generation..." -ForegroundColor Green

foreach ($fileKey in $fileExplanations.Keys) {
    $filePath = Join-Path $libPath $fileKey
    
    if (Test-Path $filePath) {
        Write-Host "Processing: $fileKey" -ForegroundColor Cyan
        
        # Read file content
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        
        # Create Word document
        $doc = $word.Documents.Add()
        $selection = $word.Selection
        
        # Title
        $selection.Font.Size = 16
        $selection.Font.Bold = $true
        $selection.Font.Color = 255  # Red
        $selection.TypeText("FLUTTER APPLICATION - CODE DOCUMENTATION")
        $selection.TypeParagraph()
        $selection.TypeParagraph()
        
        # File name
        $selection.Font.Size = 14
        $selection.Font.Bold = $true
        $selection.Font.Color = 0  # Black
        $selection.TypeText("File: $fileKey")
        $selection.TypeParagraph()
        $selection.TypeParagraph()
        
        # Explanation section
        $selection.Font.Size = 12
        $selection.Font.Bold = $true
        $selection.Font.Color = 16711680  # Blue
        $selection.TypeText("FILE EXPLANATION:")
        $selection.TypeParagraph()
        
        $selection.Font.Size = 11
        $selection.Font.Bold = $false
        $selection.Font.Color = 0
        $selection.TypeText($fileExplanations[$fileKey])
        $selection.TypeParagraph()
        $selection.TypeParagraph()
        
        # Code section
        $selection.Font.Size = 12
        $selection.Font.Bold = $true
        $selection.Font.Color = 16711680  # Blue
        $selection.TypeText("SOURCE CODE:")
        $selection.TypeParagraph()
        
        $selection.Font.Name = "Courier New"
        $selection.Font.Size = 9
        $selection.Font.Bold = $false
        $selection.Font.Color = 0
        $selection.TypeText($content)
        
        # Save document
        $outputFileName = $fileKey -replace "\\", "_"
        $outputFileName = $outputFileName -replace ".dart", ".docx"
        $outputFile = Join-Path $outputPath $outputFileName
        
        $doc.SaveAs([ref]$outputFile)
        $doc.Close()
        
        Write-Host "Created: $outputFileName" -ForegroundColor Green
    }
    else {
        Write-Host "File not found: $fileKey" -ForegroundColor Yellow
    }
}

$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
Remove-Variable word

Write-Host "`nAll documents generated successfully!" -ForegroundColor Green
Write-Host "Output location: $outputPath" -ForegroundColor Cyan
