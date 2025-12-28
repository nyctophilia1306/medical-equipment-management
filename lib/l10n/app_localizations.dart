import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý Thiết Bị Y Tế'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài Đặt'**
  String get settings;

  /// No description provided for @userProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ Sơ Người Dùng'**
  String get userProfile;

  /// No description provided for @role.
  ///
  /// In vi, this message translates to:
  /// **'Vai Trò'**
  String get role;

  /// No description provided for @phone.
  ///
  /// In vi, this message translates to:
  /// **'Điện Thoại'**
  String get phone;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn Ngữ'**
  String get language;

  /// No description provided for @english.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông Báo'**
  String get notifications;

  /// No description provided for @emailNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông Báo Email'**
  String get emailNotifications;

  /// No description provided for @emailNotificationSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận cảnh báo email cho thiết bị quá hạn'**
  String get emailNotificationSubtitle;

  /// No description provided for @about.
  ///
  /// In vi, this message translates to:
  /// **'Về Ứng Dụng'**
  String get about;

  /// No description provided for @version.
  ///
  /// In vi, this message translates to:
  /// **'Phiên Bản'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In vi, this message translates to:
  /// **'Điều Khoản Dịch Vụ'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính Sách Bảo Mật'**
  String get privacyPolicy;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng Xuất'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng Nhập'**
  String get signIn;

  /// No description provided for @languageUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngôn ngữ thành công'**
  String get languageUpdated;

  /// No description provided for @emailNotificationsEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật thông báo email'**
  String get emailNotificationsEnabled;

  /// No description provided for @emailNotificationsDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo email'**
  String get emailNotificationsDisabled;

  /// No description provided for @administrator.
  ///
  /// In vi, this message translates to:
  /// **'Quản Trị Viên'**
  String get administrator;

  /// No description provided for @manager.
  ///
  /// In vi, this message translates to:
  /// **'Người Quản Lý'**
  String get manager;

  /// No description provided for @user.
  ///
  /// In vi, this message translates to:
  /// **'Người Dùng'**
  String get user;

  /// No description provided for @unknown.
  ///
  /// In vi, this message translates to:
  /// **'Không Rõ'**
  String get unknown;

  /// No description provided for @guest.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get guest;

  /// No description provided for @equipmentCatalog.
  ///
  /// In vi, this message translates to:
  /// **'Danh Mục Thiết Bị'**
  String get equipmentCatalog;

  /// No description provided for @borrowManagement.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý Mượn'**
  String get borrowManagement;

  /// No description provided for @adminDashboard.
  ///
  /// In vi, this message translates to:
  /// **'Bảng Điều Khiển'**
  String get adminDashboard;

  /// No description provided for @userManagement.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý Người Dùng'**
  String get userManagement;

  /// No description provided for @equipment.
  ///
  /// In vi, this message translates to:
  /// **'Thiết Bị'**
  String get equipment;

  /// No description provided for @categories.
  ///
  /// In vi, this message translates to:
  /// **'Danh Mục'**
  String get categories;

  /// No description provided for @analytics.
  ///
  /// In vi, this message translates to:
  /// **'Phân Tích'**
  String get analytics;

  /// No description provided for @auditLogs.
  ///
  /// In vi, this message translates to:
  /// **'Nhật Ký Kiểm Toán'**
  String get auditLogs;

  /// No description provided for @categoryManagement.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý Danh Mục'**
  String get categoryManagement;

  /// No description provided for @welcome.
  ///
  /// In vi, this message translates to:
  /// **'Chào Mừng'**
  String get welcome;

  /// No description provided for @guestMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế Độ Khách'**
  String get guestMode;

  /// No description provided for @signInToAccessMore.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để truy cập thêm tính năng'**
  String get signInToAccessMore;

  /// No description provided for @changeLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Đổi Ngôn Ngữ'**
  String get changeLanguage;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm Kiếm'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In vi, this message translates to:
  /// **'Lọc'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In vi, this message translates to:
  /// **'Tất Cả'**
  String get all;

  /// No description provided for @available.
  ///
  /// In vi, this message translates to:
  /// **'Có Sẵn'**
  String get available;

  /// No description provided for @borrowed.
  ///
  /// In vi, this message translates to:
  /// **'Đã Mượn'**
  String get borrowed;

  /// No description provided for @maintenance.
  ///
  /// In vi, this message translates to:
  /// **'Bảo Trì'**
  String get maintenance;

  /// No description provided for @status.
  ///
  /// In vi, this message translates to:
  /// **'Trạng Thái'**
  String get status;

  /// No description provided for @quantity.
  ///
  /// In vi, this message translates to:
  /// **'Số Lượng'**
  String get quantity;

  /// No description provided for @totalQuantity.
  ///
  /// In vi, this message translates to:
  /// **'Tổng Số Lượng'**
  String get totalQuantity;

  /// No description provided for @availableQuantity.
  ///
  /// In vi, this message translates to:
  /// **'Số Lượng Có Sẵn'**
  String get availableQuantity;

  /// No description provided for @model.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu'**
  String get model;

  /// No description provided for @serialNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số Serial'**
  String get serialNumber;

  /// No description provided for @category.
  ///
  /// In vi, this message translates to:
  /// **'Danh Mục'**
  String get category;

  /// No description provided for @description.
  ///
  /// In vi, this message translates to:
  /// **'Mô Tả'**
  String get description;

  /// No description provided for @addEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Thêm Thiết Bị'**
  String get addEquipment;

  /// No description provided for @editEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Sửa Thiết Bị'**
  String get editEquipment;

  /// No description provided for @deleteEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Xóa Thiết Bị'**
  String get deleteEquipment;

  /// No description provided for @importEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Thiết Bị'**
  String get importEquipment;

  /// No description provided for @exportEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Xuất Thiết Bị'**
  String get exportEquipment;

  /// No description provided for @equipmentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi Tiết Thiết Bị'**
  String get equipmentDetails;

  /// No description provided for @name.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get name;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get add;

  /// No description provided for @create.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get create;

  /// No description provided for @update.
  ///
  /// In vi, this message translates to:
  /// **'Cập Nhật'**
  String get update;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác Nhận'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In vi, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @borrowDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày Mượn'**
  String get borrowDate;

  /// No description provided for @returnDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày Trả'**
  String get returnDate;

  /// No description provided for @requestDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày Yêu Cầu'**
  String get requestDate;

  /// No description provided for @borrower.
  ///
  /// In vi, this message translates to:
  /// **'Người Mượn'**
  String get borrower;

  /// No description provided for @requestSerial.
  ///
  /// In vi, this message translates to:
  /// **'Mã Yêu Cầu'**
  String get requestSerial;

  /// No description provided for @activeBorrows.
  ///
  /// In vi, this message translates to:
  /// **'Đang Mượn'**
  String get activeBorrows;

  /// No description provided for @returnedBorrows.
  ///
  /// In vi, this message translates to:
  /// **'Đã Trả'**
  String get returnedBorrows;

  /// No description provided for @createBorrowRequest.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Yêu Cầu Mượn'**
  String get createBorrowRequest;

  /// No description provided for @scanQRCode.
  ///
  /// In vi, this message translates to:
  /// **'Quét Mã QR'**
  String get scanQRCode;

  /// No description provided for @enterSerialNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Số Serial'**
  String get enterSerialNumber;

  /// No description provided for @selectEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Thiết Bị'**
  String get selectEquipment;

  /// No description provided for @borrowQuantity.
  ///
  /// In vi, this message translates to:
  /// **'Số Lượng Mượn'**
  String get borrowQuantity;

  /// No description provided for @returnEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Trả Thiết Bị'**
  String get returnEquipment;

  /// No description provided for @markAsReturned.
  ///
  /// In vi, this message translates to:
  /// **'Đánh Dấu Đã Trả'**
  String get markAsReturned;

  /// No description provided for @equipmentReturned.
  ///
  /// In vi, this message translates to:
  /// **'Thiết Bị Đã Trả'**
  String get equipmentReturned;

  /// No description provided for @notReturned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa Trả'**
  String get notReturned;

  /// No description provided for @overdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá Hạn'**
  String get overdue;

  /// No description provided for @dueDate.
  ///
  /// In vi, this message translates to:
  /// **'Hạn Trả'**
  String get dueDate;

  /// No description provided for @systemOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng Quan Hệ Thống'**
  String get systemOverview;

  /// No description provided for @totalEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Tổng Thiết Bị'**
  String get totalEquipment;

  /// No description provided for @totalUsers.
  ///
  /// In vi, this message translates to:
  /// **'Tổng Người Dùng'**
  String get totalUsers;

  /// No description provided for @activeRequests.
  ///
  /// In vi, this message translates to:
  /// **'Yêu Cầu Đang Hoạt Động'**
  String get activeRequests;

  /// No description provided for @utilizationRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ Lệ Sử Dụng'**
  String get utilizationRate;

  /// No description provided for @recentActivity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt Động Gần Đây'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem Tất Cả'**
  String get viewAll;

  /// No description provided for @admins.
  ///
  /// In vi, this message translates to:
  /// **'Quản Trị Viên'**
  String get admins;

  /// No description provided for @managers.
  ///
  /// In vi, this message translates to:
  /// **'Người Quản Lý'**
  String get managers;

  /// No description provided for @users.
  ///
  /// In vi, this message translates to:
  /// **'Người Dùng'**
  String get users;

  /// No description provided for @createUser.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Người Dùng'**
  String get createUser;

  /// No description provided for @editUser.
  ///
  /// In vi, this message translates to:
  /// **'Sửa Người Dùng'**
  String get editUser;

  /// No description provided for @deleteUser.
  ///
  /// In vi, this message translates to:
  /// **'Xóa Người Dùng'**
  String get deleteUser;

  /// No description provided for @email.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật Khẩu'**
  String get password;

  /// No description provided for @username.
  ///
  /// In vi, this message translates to:
  /// **'Tên Đăng Nhập'**
  String get username;

  /// No description provided for @fullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ Tên'**
  String get fullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In vi, this message translates to:
  /// **'Ngày Sinh'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In vi, this message translates to:
  /// **'Giới Tính'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get male;

  /// No description provided for @female.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get female;

  /// No description provided for @other.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get other;

  /// No description provided for @selectRole.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Vai Trò'**
  String get selectRole;

  /// No description provided for @userCreated.
  ///
  /// In vi, this message translates to:
  /// **'Tạo người dùng thành công'**
  String get userCreated;

  /// No description provided for @userUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật người dùng thành công'**
  String get userUpdated;

  /// No description provided for @userDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Xóa người dùng thành công'**
  String get userDeleted;

  /// No description provided for @confirmDelete.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa?'**
  String get confirmDelete;

  /// No description provided for @addCategory.
  ///
  /// In vi, this message translates to:
  /// **'Thêm Danh Mục'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In vi, this message translates to:
  /// **'Sửa Danh Mục'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In vi, this message translates to:
  /// **'Xóa Danh Mục'**
  String get deleteCategory;

  /// No description provided for @categoryName.
  ///
  /// In vi, this message translates to:
  /// **'Tên Danh Mục'**
  String get categoryName;

  /// No description provided for @parentCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh Mục Cha'**
  String get parentCategory;

  /// No description provided for @subcategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh Mục Con'**
  String get subcategories;

  /// No description provided for @noSubcategories.
  ///
  /// In vi, this message translates to:
  /// **'Không có danh mục con'**
  String get noSubcategories;

  /// No description provided for @lineChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu Đồ Đường'**
  String get lineChart;

  /// No description provided for @barChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu Đồ Cột'**
  String get barChart;

  /// No description provided for @pieChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu Đồ Tròn'**
  String get pieChart;

  /// No description provided for @areaChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu Đồ Vùng'**
  String get areaChart;

  /// No description provided for @radarChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu Đồ Radar'**
  String get radarChart;

  /// No description provided for @scatterChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu Đồ Phân Tán'**
  String get scatterChart;

  /// No description provided for @selectChartType.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Loại Biểu Đồ'**
  String get selectChartType;

  /// No description provided for @selectDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Khoảng Thời Gian'**
  String get selectDateRange;

  /// No description provided for @from.
  ///
  /// In vi, this message translates to:
  /// **'Từ'**
  String get from;

  /// No description provided for @to.
  ///
  /// In vi, this message translates to:
  /// **'Đến'**
  String get to;

  /// No description provided for @apply.
  ///
  /// In vi, this message translates to:
  /// **'Áp Dụng'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In vi, this message translates to:
  /// **'Đặt Lại'**
  String get reset;

  /// No description provided for @action.
  ///
  /// In vi, this message translates to:
  /// **'Hành Động'**
  String get action;

  /// No description provided for @details.
  ///
  /// In vi, this message translates to:
  /// **'Chi Tiết'**
  String get details;

  /// No description provided for @timestamp.
  ///
  /// In vi, this message translates to:
  /// **'Thời Gian'**
  String get timestamp;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng Nhập'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng Xuất'**
  String get logout;

  /// No description provided for @created.
  ///
  /// In vi, this message translates to:
  /// **'Đã Tạo'**
  String get created;

  /// No description provided for @updated.
  ///
  /// In vi, this message translates to:
  /// **'Đã Cập Nhật'**
  String get updated;

  /// No description provided for @deleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã Xóa'**
  String get deleted;

  /// No description provided for @roleChanged.
  ///
  /// In vi, this message translates to:
  /// **'Đã Đổi Vai Trò'**
  String get roleChanged;

  /// No description provided for @noDataAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get noDataAvailable;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang Tải'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get error;

  /// No description provided for @success.
  ///
  /// In vi, this message translates to:
  /// **'Thành Công'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In vi, this message translates to:
  /// **'Thất Bại'**
  String get failed;

  /// No description provided for @required.
  ///
  /// In vi, this message translates to:
  /// **'Bắt Buộc'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In vi, this message translates to:
  /// **'Tùy Chọn'**
  String get optional;

  /// No description provided for @backToDashboard.
  ///
  /// In vi, this message translates to:
  /// **'Về Trang Chủ'**
  String get backToDashboard;

  /// No description provided for @refresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm Mới'**
  String get refresh;

  /// No description provided for @showMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem Thêm'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In vi, this message translates to:
  /// **'Thu Gọn'**
  String get showLess;

  /// No description provided for @allCategories.
  ///
  /// In vi, this message translates to:
  /// **'Tất Cả Danh Mục'**
  String get allCategories;

  /// No description provided for @allStatuses.
  ///
  /// In vi, this message translates to:
  /// **'Tất Cả Trạng Thái'**
  String get allStatuses;

  /// No description provided for @outOfOrder.
  ///
  /// In vi, this message translates to:
  /// **'Hỏng Hóc'**
  String get outOfOrder;

  /// No description provided for @partiallyAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Một Phần Có Sẵn'**
  String get partiallyAvailable;

  /// No description provided for @confirmDeleteEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa thiết bị này?'**
  String get confirmDeleteEquipment;

  /// No description provided for @equipmentDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa thiết bị thành công'**
  String get equipmentDeleted;

  /// No description provided for @importExcel.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Excel'**
  String get importExcel;

  /// No description provided for @errorReadingFile.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: Không thể đọc tệp'**
  String get errorReadingFile;

  /// No description provided for @errorOpeningFile.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi mở tệp'**
  String get errorOpeningFile;

  /// No description provided for @equipmentCatalogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh Mục Thiết Bị'**
  String get equipmentCatalogTitle;

  /// No description provided for @equipmentCatalogSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt và tìm kiếm thiết bị y tế'**
  String get equipmentCatalogSubtitle;

  /// No description provided for @fullNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Họ Và Tên *'**
  String get fullNameRequired;

  /// No description provided for @enterFullName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ và tên'**
  String get enterFullName;

  /// No description provided for @enterPhone.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại'**
  String get enterPhone;

  /// No description provided for @dateOfBirthRequired.
  ///
  /// In vi, this message translates to:
  /// **'Ngày Sinh *'**
  String get dateOfBirthRequired;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày sinh'**
  String get selectDateOfBirth;

  /// No description provided for @selectDate.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get selectDate;

  /// No description provided for @genderRequired.
  ///
  /// In vi, this message translates to:
  /// **'Giới Tính *'**
  String get genderRequired;

  /// No description provided for @selectGender.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giới tính'**
  String get selectGender;

  /// No description provided for @scannedEquipment.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đã quét (theo QR/serial)'**
  String get scannedEquipment;

  /// No description provided for @enterSerial.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số serial'**
  String get enterSerial;

  /// No description provided for @addButton.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get addButton;

  /// No description provided for @noEquipmentScanned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thiết bị nào được quét'**
  String get noEquipmentScanned;

  /// No description provided for @saveRequest.
  ///
  /// In vi, this message translates to:
  /// **'Lưu Yêu Cầu'**
  String get saveRequest;

  /// No description provided for @clear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get clear;

  /// No description provided for @newUser.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get newUser;

  /// No description provided for @existingUser.
  ///
  /// In vi, this message translates to:
  /// **'Cũ'**
  String get existingUser;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng Điều Khiển Quản Trị'**
  String get adminDashboardTitle;

  /// No description provided for @systemOverviewSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan hệ thống và quản lý'**
  String get systemOverviewSubtitle;

  /// No description provided for @systemStatistics.
  ///
  /// In vi, this message translates to:
  /// **'Thống Kê Hệ Thống'**
  String get systemStatistics;

  /// No description provided for @adminsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Quản Trị'**
  String get adminsLabel;

  /// No description provided for @managersLabel.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý'**
  String get managersLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số Lượng'**
  String get quantityLabel;

  /// No description provided for @approvedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã Duyệt'**
  String get approvedLabel;

  /// No description provided for @totalLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tổng'**
  String get totalLabel;

  /// No description provided for @pendingRequests.
  ///
  /// In vi, this message translates to:
  /// **'Yêu Cầu Chờ Duyệt'**
  String get pendingRequests;

  /// No description provided for @returned.
  ///
  /// In vi, this message translates to:
  /// **'Đã Trả'**
  String get returned;

  /// No description provided for @management.
  ///
  /// In vi, this message translates to:
  /// **'Quản Trị'**
  String get management;

  /// No description provided for @userManagementSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý người dùng & vai trò'**
  String get userManagementSubtitle;

  /// No description provided for @equipmentManagementSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thiết bị'**
  String get equipmentManagementSubtitle;

  /// No description provided for @categoryManagementSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý danh mục'**
  String get categoryManagementSubtitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê chi tiết'**
  String get analyticsSubtitle;

  /// No description provided for @auditLogsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi hoạt động'**
  String get auditLogsSubtitle;

  /// No description provided for @categoryNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục không được để trống'**
  String get categoryNameRequired;

  /// No description provided for @pleasSelectCategoryForAll.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn danh mục cho tất cả thiết bị'**
  String get pleasSelectCategoryForAll;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
