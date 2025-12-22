# Luồng Quản Lý Mượn Trả (Đơn Giản)

```mermaid
graph TB
    Start([Vào Mượn Trả]) --> Tabs{Chọn Tab}
    
    Tabs --> Active[Đang Mượn]
    Tabs --> Returned[Đã Trả]
    Tabs --> Create[Tạo Mới]
    
    Create --> Info[Nhập Thông Tin<br/>Người Mượn]
    Info --> AddEquip[Thêm Thiết Bị:<br/>- QR Scan<br/>- Nhập Serial<br/>- Chọn Catalog]
    
    AddEquip --> Cart[Giỏ Hàng]
    Cart --> MoreEquip{Thêm Nữa?}
    
    MoreEquip -->|Có| AddEquip
    MoreEquip -->|Không| Submit[Gửi Request]
    
    Submit --> Generate[Tạo Mã Request<br/>DDMMYYSS]
    Generate --> Active
    
    Active --> ViewActive[Xem Chi Tiết]
    ViewActive --> Return{Trả TB?}
    
    Return -->|Có| ScanReturn[Scan QR<br/>Để Trả]
    Return -->|Không| Active
    
    ScanReturn --> MarkReturned[Đánh Dấu<br/>Đã Trả]
    MarkReturned --> CheckAll{Trả Hết?}
    
    CheckAll -->|Rồi| Complete[Hoàn Thành]
    CheckAll -->|Chưa| Active
    
    Complete --> Returned
    
    Returned --> ViewReturned[Xem Lịch Sử]
    ViewReturned --> Export[Export PDF/Excel]
    
    style Start fill:#4CAF50
    style Complete fill:#4CAF50
```

## Tóm Tắt

### 3 Tab Chính
1. **Đang Mượn**: Request active, quá hạn highlight đỏ
2. **Đã Trả**: Lịch sử hoàn thành
3. **Tạo Mới**: Form tạo request

### Quy Trình Mượn
1. Nhập thông tin người mượn
2. Thêm thiết bị (3 cách: QR/Serial/Catalog)
3. Review giỏ hàng
4. Submit → Tạo mã request (DDMMYYSS)

### Quy Trình Trả
1. Scan QR thiết bị
2. Đánh dấu đã trả
3. Khi trả hết → Hoàn thành request
