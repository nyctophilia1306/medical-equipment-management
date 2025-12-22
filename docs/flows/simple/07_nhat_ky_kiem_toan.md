# Luồng Nhật Ký Kiểm Toán (Đơn Giản)

```mermaid
graph TB
    Start([Vào Audit Logs]) --> CheckPerm{Quyền?}
    
    CheckPerm -->|Guest| Denied[Từ Chối]
    CheckPerm -->|User| MyLogs[Chỉ Logs<br/>Của Mình]
    CheckPerm -->|Manager| TeamLogs[Logs TB<br/>& Requests]
    CheckPerm -->|Admin| AllLogs[Tất Cả Logs]
    
    MyLogs --> Display[Hiển Thị Logs]
    TeamLogs --> Display
    AllLogs --> Display
    
    Display --> Table[Bảng Logs:<br/>- Timestamp<br/>- User<br/>- Action<br/>- Resource<br/>- Status]
    
    Table --> Actions{Chọn}
    
    Actions --> Filter[Lọc]
    Actions --> Search[Tìm Kiếm]
    Actions --> ViewDetail[Xem Chi Tiết]
    Actions --> Export[Export]
    
    Filter --> FilterOptions[Chọn Bộ Lọc:<br/>- Thời gian<br/>- Action type<br/>- User<br/>- Resource<br/>- Status]
    FilterOptions --> Apply[Áp Dụng]
    Apply --> Table
    
    Search --> InputSearch[Nhập Từ Khóa]
    InputSearch --> DoSearch[Tìm Kiếm]
    DoSearch --> Table
    
    ViewDetail --> Modal[Modal Chi Tiết:<br/>- Thông tin đầy đủ<br/>- Before/After<br/>- Technical info<br/>- Related logs]
    Modal --> Table
    
    Export --> SelectFormat{Format?}
    SelectFormat --> PDF[PDF Report]
    SelectFormat --> Excel[Excel Data]
    SelectFormat --> JSON[JSON]
    SelectFormat --> CSV[CSV]
    
    PDF --> Download[Download]
    Excel --> Download
    JSON --> Download
    CSV --> Download
    
    Download --> Table
    
    Denied --> Back([Quay Lại])
    
    style Start fill:#4CAF50
    style Denied fill:#F44336
```

## Tóm Tắt

### Quyền Truy Cập
- **Guest**: Không truy cập được
- **User**: Chỉ logs của mình
- **Manager**: Logs thiết bị & requests
- **Admin**: Tất cả logs

### Log Actions
- Authentication: LOGIN, LOGOUT, PASSWORD_CHANGED
- Equipment: CREATED, UPDATED, DELETED
- Borrow: REQUEST_CREATED, BORROWED, RETURNED
- User: USER_CREATED, ROLE_CHANGED
- System: CONFIG_CHANGED, BACKUP

### Chức Năng

1. **Hiển Thị**
   - Bảng với pagination
   - Timestamp, User, Action, Resource, Status

2. **Lọc**
   - Thời gian (hôm nay, 7 ngày, 30 ngày, custom)
   - Action type (multi-select)
   - User, Resource, Status

3. **Tìm Kiếm**
   - Tìm trong tất cả fields
   - Real-time

4. **Chi Tiết**
   - Full log info
   - Before/After values (diff view)
   - Technical details
   - Related logs timeline

5. **Export**
   - PDF, Excel, JSON, CSV
   - Áp dụng filters hiện tại

### Đặc Điểm
- **Immutable**: Không sửa/xóa logs được
- **Retention**: Lưu 90 ngày (configurable)
- **Security**: RLS, audit trail, compliance
