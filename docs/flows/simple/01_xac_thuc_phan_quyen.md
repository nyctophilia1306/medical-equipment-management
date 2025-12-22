# Luồng Xác Thực và Phân Quyền (Đơn Giản)

```mermaid
graph TB
    Start([Khởi Động App]) --> CheckSession{Có Session?}
    
    CheckSession -->|Có| GetUser[Lấy Thông Tin User]
    CheckSession -->|Không| Guest[Chế Độ Khách]
    
    GetUser --> CheckRole{Vai Trò?}
    
    CheckRole -->|Admin| AdminAccess[Toàn Quyền]
    CheckRole -->|Manager| ManagerAccess[Quản Lý TB & Mượn]
    CheckRole -->|User| UserAccess[Tạo Request Mượn]
    
    Guest --> GuestAccess[Chỉ Xem TB]
    
    AdminAccess --> App[Sử Dụng App]
    ManagerAccess --> App
    UserAccess --> App
    GuestAccess --> App
    
    App --> Action{Hành Động}
    
    Action -->|Login| DoLogin[Đăng Nhập]
    Action -->|Logout| DoLogout[Đăng Xuất]
    Action -->|Continue| App
    
    DoLogin --> CheckSession
    DoLogout --> Guest
    
    style Start fill:#4CAF50
    style Guest fill:#9E9E9E
    style AdminAccess fill:#F44336
    style ManagerAccess fill:#FF9800
    style UserAccess fill:#2196F3
```

## Tóm Tắt

### 4 Cấp Độ Quyền
- **👤 Khách**: Xem thiết bị
- **🔵 User**: Tạo request mượn
- **🟠 Manager**: Quản lý thiết bị & mượn trả
- **🔴 Admin**: Toàn quyền hệ thống

### Quy Trình
1. Kiểm tra session khi khởi động
2. Xác định vai trò nếu đã đăng nhập
3. Cấp quyền theo vai trò
4. Cho phép login/logout bất kỳ lúc nào
