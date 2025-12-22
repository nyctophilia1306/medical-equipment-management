# Luồng Quản Lý Danh Mục (Đơn Giản)

```mermaid
graph TB
    Start([Vào Danh Mục]) --> CheckAdmin{Admin?}
    
    CheckAdmin -->|Không| Denied[Từ Chối]
    CheckAdmin -->|Có| Tree[Hiển Thị Cây<br/>Danh Mục]
    
    Tree --> Actions{Chọn}
    
    Actions --> View[Xem Chi Tiết]
    Actions --> Add[Thêm Danh Mục]
    Actions --> Edit[Sửa Danh Mục]
    Actions --> Delete[Xóa Danh Mục]
    Actions --> Move[Di Chuyển]
    
    Add --> SelectParent[Chọn Vị Trí<br/>Parent]
    SelectParent --> AddForm[Form Thêm:<br/>- Tên<br/>- Mô tả<br/>- Icon]
    AddForm --> CheckLevel{Level ≤ 5?}
    
    CheckLevel -->|Không| LevelErr[Lỗi: Quá 5 Cấp]
    CheckLevel -->|Có| Create[Tạo Danh Mục]
    Create --> Tree
    
    LevelErr --> Add
    
    Edit --> EditForm[Form Sửa:<br/>- Tên<br/>- Mô tả<br/>- Icon]
    EditForm --> Update[Cập Nhật]
    Update --> Tree
    
    Delete --> CheckChild{Có Danh Mục<br/>Con?}
    CheckChild -->|Có| CannotDel1[Không Thể Xóa]
    CheckChild -->|Không| CheckEquip{Có Thiết Bị?}
    
    CheckEquip -->|Có| CannotDel2[Phải Di Chuyển<br/>TB Trước]
    CheckEquip -->|Không| ConfirmDel{Xác Nhận?}
    
    ConfirmDel -->|Không| Tree
    ConfirmDel -->|Có| Remove[Xóa]
    Remove --> Tree
    
    CannotDel1 --> Tree
    CannotDel2 --> Tree
    
    Move --> ChooseNew[Chọn Parent Mới]
    ChooseNew --> ValidateMove{Hợp Lệ?}
    ValidateMove -->|Không| MoveErr[Lỗi]
    ValidateMove -->|Có| DoMove[Di Chuyển]
    
    MoveErr --> Tree
    DoMove --> Tree
    
    View --> Tree
    Denied --> Back([Quay Lại])
    
    style Start fill:#4CAF50
    style Denied fill:#F44336
    style CannotDel1 fill:#F44336
    style CannotDel2 fill:#F44336
    style LevelErr fill:#F44336
    style MoveErr fill:#F44336
```

## Tóm Tắt

### Quyền Truy Cập
- **Chỉ Admin** được quản lý danh mục

### Cấu Trúc
- Cây phân cấp tối đa **5 level**
- Mỗi danh mục có: Tên, Mô tả, Icon, Path

### Chức Năng
1. **Thêm**: Tạo danh mục mới (chọn parent)
2. **Sửa**: Đổi tên, mô tả, icon
3. **Xóa**: Không xóa nếu có con hoặc có thiết bị
4. **Di Chuyển**: Thay đổi parent (validate level)
5. **Sắp Xếp**: Drag & drop để đổi thứ tự

### Rules
- Không vượt 5 cấp
- Không trùng tên trong cùng cấp
- Không xóa nếu có con/thiết bị
- Không di chuyển vào chính nó
