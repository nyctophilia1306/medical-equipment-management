# Luồng Cài Đặt Hệ Thống (Đơn Giản)

```mermaid
graph TB
    Start([Vào Cài Đặt]) --> CheckAuth{Đăng Nhập?}
    
    CheckAuth -->|Không| GuestSettings[Cài Đặt Guest:<br/>- Ngôn ngữ<br/>- Theme]
    CheckAuth -->|Có| UserSettings[Cài Đặt User]
    
    GuestSettings --> LangTheme[Chọn Ngôn Ngữ<br/>& Theme]
    LangTheme --> SaveLocal[Lưu LocalStorage]
    SaveLocal --> Apply[Áp Dụng]
    Apply --> GuestSettings
    
    UserSettings --> Tabs{Chọn Tab}
    
    Tabs --> Profile[Hồ Sơ]
    Tabs --> Account[Tài Khoản]
    Tabs --> Language[Ngôn Ngữ]
    Tabs --> Notifications[Thông Báo]
    Tabs --> Appearance[Giao Diện]
    Tabs --> About[Giới Thiệu]
    
    Profile --> EditProfile[Sửa:<br/>- Họ tên<br/>- SĐT<br/>- Phòng ban]
    EditProfile --> ChangeAvatar[Đổi Avatar]
    ChangeAvatar --> SaveProfile[Lưu]
    SaveProfile --> Tabs
    
    Account --> AccActions{Chọn}
    AccActions --> ChangePass[Đổi Mật Khẩu]
    AccActions --> Sessions[Quản Lý Sessions]
    AccActions --> TwoFA[2FA]
    
    ChangePass --> InputPass[Nhập MK Cũ<br/>& Mới]
    InputPass --> UpdatePass[Cập Nhật]
    UpdatePass --> Tabs
    
    Sessions --> ViewSessions[Xem Sessions]
    ViewSessions --> Revoke[Thu Hồi]
    Revoke --> Tabs
    
    TwoFA --> Toggle2FA[Bật/Tắt 2FA]
    Toggle2FA --> Tabs
    
    Language --> SelectLang[Chọn Ngôn Ngữ:<br/>vi / en]
    SelectLang --> SaveLang[Lưu]
    SaveLang --> Reload[Reload App]
    Reload --> Tabs
    
    Notifications --> ToggleNotif[Bật/Tắt:<br/>- Email<br/>- Push<br/>- Do Not Disturb]
    ToggleNotif --> SaveNotif[Lưu]
    SaveNotif --> Tabs
    
    Appearance --> SelectTheme[Chọn Theme:<br/>Light / Dark / Auto]
    SelectTheme --> SelectColor[Chọn Màu]
    SelectColor --> SaveAppearance[Lưu]
    SaveAppearance --> ApplyTheme[Áp Dụng]
    ApplyTheme --> Tabs
    
    About --> ShowInfo[Hiển Thị:<br/>- Version<br/>- Developed by<br/>- Contact<br/>- Licenses]
    ShowInfo --> CheckUpdate[Kiểm Tra<br/>Cập Nhật]
    CheckUpdate --> Tabs
    
    %% Admin System Settings
    Tabs --> CheckAdmin{Admin?}
    CheckAdmin -->|Có| SystemSettings[Cài Đặt<br/>Hệ Thống]
    CheckAdmin -->|Không| Tabs
    
    SystemSettings --> SysOptions{Chọn}
    
    SysOptions --> General[General]
    SysOptions --> Email[Email Config]
    SysOptions --> Security[Security]
    SysOptions --> Backup[Backup]
    
    General --> EditGeneral[Sửa:<br/>- Site name<br/>- Contact info]
    EditGeneral --> SaveSys[Lưu]
    
    Email --> EditEmail[Sửa:<br/>- SMTP settings]
    EditEmail --> TestEmail[Test Connection]
    TestEmail --> SaveSys
    
    Security --> EditSecurity[Sửa:<br/>- Session timeout<br/>- Password policy<br/>- 2FA required]
    EditSecurity --> SaveSys
    
    Backup --> BackupNow[Backup Ngay]
    BackupNow --> SaveSys
    
    SaveSys --> Tabs
    
    style Start fill:#4CAF50
    style GuestSettings fill:#9E9E9E
    style SystemSettings fill:#FF9800
```

## Tóm Tắt

### Cài Đặt Guest (Không Đăng Nhập)
- Ngôn ngữ (vi/en)
- Theme (Light/Dark/System)
- Lưu LocalStorage

### Cài Đặt User (Đã Đăng Nhập)

1. **Hồ Sơ**
   - Sửa thông tin: Tên, SĐT, Phòng ban
   - Đổi avatar (upload/crop)

2. **Tài Khoản & Bảo Mật**
   - Đổi mật khẩu
   - Quản lý sessions (revoke)
   - Xác thực 2 bước (enable/disable)

3. **Ngôn Ngữ**
   - Tiếng Việt / English
   - Date/Number format

4. **Thông Báo**
   - Email notifications (on/off từng loại)
   - Push notifications
   - Do Not Disturb hours

5. **Giao Diện**
   - Theme: Light/Dark/Auto
   - Color scheme: Blue/Green/Purple/Red
   - Font size: Small/Medium/Large
   - Accessibility options

6. **Giới Thiệu**
   - App version & info
   - Check for updates
   - Open source licenses
   - Send feedback

### Cài Đặt Hệ Thống (Admin Only)

1. **General**: Site name, contact, logo
2. **Email**: SMTP configuration, test
3. **Security**: Session, password policy, 2FA
4. **Backup**: Auto backup, manual backup
5. **Maintenance**: Maintenance mode
6. **API**: API keys, rate limits

### Lưu Trữ
- Guest: LocalStorage
- User: Database (users table)
- System: Database (settings table)
