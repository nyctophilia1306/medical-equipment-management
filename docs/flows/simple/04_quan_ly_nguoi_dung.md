# Luồng Quản Lý Người Dùng (Đơn Giản)

```mermaid
graph TB
    Start([Vào Quản Lý User]) --> CheckAdmin{Admin?}
    
    CheckAdmin -->|Không| Denied[Từ Chối]
    CheckAdmin -->|Có| List[Danh Sách Users]
    
    List --> Actions{Chọn}
    
    Actions --> View[Xem Chi Tiết]
    Actions --> Add[Thêm User]
    Actions --> Edit[Sửa User]
    Actions --> Delete[Xóa User]
    
    Add --> AddForm[Form Thêm:<br/>- Email<br/>- Mật khẩu<br/>- Vai trò<br/>- Thông tin]
    AddForm --> Create[Tạo Account]
    Create --> List
    
    Edit --> EditForm[Form Sửa:<br/>- Thông tin<br/>- Vai trò<br/>- Trạng thái]
    EditForm --> Update[Cập Nhật]
    Update --> List
    
    Delete --> CheckBorrow{Có Request<br/>Đang Mượn?}
    CheckBorrow -->|Có| CannotDelete[Không Thể Xóa]
    CheckBorrow -->|Không| ConfirmDel{Xác Nhận?}
    
    ConfirmDel -->|Không| List
    ConfirmDel -->|Có| Remove[Soft Delete]
    Remove --> List
    
    CannotDelete --> List
    View --> List
    Denied --> Back([Quay Lại])
    
    style Start fill:#4CAF50
    style CheckAdmin fill:#FF9800
    style Denied fill:#F44336
    style CannotDelete fill:#F44336
```

## Tóm Tắt

### Quyền Truy Cập
- **Chỉ Admin** được quản lý users

### Chức Năng CRUD
1. **Thêm**: Tạo account mới với email, password, role
2. **Xem**: Chi tiết user, activity, requests
3. **Sửa**: Cập nhật info, đổi role, active/inactive
4. **Xóa**: Soft delete (không xóa nếu còn request đang mượn)

### Validation
- Email hợp lệ & không trùng
- Password mạnh (8+ ký tự, chữ hoa, số)
- Phone 10 số
- Không xóa chính mình
- Không xóa user có request active
