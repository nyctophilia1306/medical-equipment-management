# Luồng Quản Lý Thiết Bị (Đơn Giản)

```mermaid
graph TB
    Start([Vào Quản Lý TB]) --> CheckPerm{Có Quyền?}
    
    CheckPerm -->|Guest/User| ViewOnly[Chỉ Xem]
    CheckPerm -->|Manager/Admin| FullAccess[Toàn Quyền]
    
    ViewOnly --> List[Danh Sách TB]
    FullAccess --> List
    
    List --> Actions{Chọn}
    
    Actions --> View[Xem Chi Tiết]
    Actions --> Search[Tìm Kiếm]
    
    FullAccess --> ManageActions{Quản Lý}
    
    ManageActions --> Add[Thêm TB]
    ManageActions --> Edit[Sửa TB]
    ManageActions --> Delete[Xóa TB]
    ManageActions --> Import[Import Excel]
    
    Add --> AddForm[Form Thêm]
    AddForm --> Save[Lưu]
    Save --> List
    
    Edit --> EditForm[Form Sửa]
    EditForm --> Update[Cập Nhật]
    Update --> List
    
    Delete --> Confirm{Xác Nhận?}
    Confirm -->|Có| Remove[Xóa]
    Confirm -->|Không| List
    Remove --> List
    
    Import --> UploadFile[Upload Excel]
    UploadFile --> Preview[Xem Trước]
    Preview --> Process[Xử Lý]
    Process --> List
    
    View --> List
    Search --> List
    
    style Start fill:#4CAF50
    style ViewOnly fill:#9E9E9E
    style FullAccess fill:#FF9800
```

## Tóm Tắt

### Quyền Truy Cập
- **Guest/User**: Chỉ xem, tìm kiếm
- **Manager/Admin**: CRUD + Import Excel

### Chức Năng Chính
1. **Xem & Tìm**: Danh sách, chi tiết, lọc
2. **Thêm**: Form nhập thông tin + upload ảnh
3. **Sửa**: Cập nhật thông tin
4. **Xóa**: Soft delete có xác nhận
5. **Import**: Upload Excel, preview, xử lý
