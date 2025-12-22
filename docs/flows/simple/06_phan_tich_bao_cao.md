# Luồng Phân Tích & Báo Cáo (Đơn Giản)

```mermaid
graph TB
    Start([Vào Analytics]) --> CheckPerm{Quyền?}
    
    CheckPerm -->|Guest| BasicView[Thống Kê<br/>Cơ Bản]
    CheckPerm -->|User+| FullView[Dashboard<br/>Đầy Đủ]
    
    FullView --> Sections{Chọn Phần}
    
    Sections --> Overview[Tổng Quan]
    Sections --> Equipment[Phân Tích TB]
    Sections --> Borrow[Phân Tích Mượn]
    Sections --> Users[Phân Tích User]
    Sections --> Custom[Báo Cáo<br/>Tùy Chỉnh]
    
    Overview --> Cards[Cards:<br/>- Tổng TB<br/>- Đang mượn<br/>- Quá hạn<br/>- Users]
    Cards --> Charts[Charts:<br/>- Timeline<br/>- Top TB<br/>- Phân bố]
    
    Equipment --> EqFilters[Bộ Lọc:<br/>- Thời gian<br/>- Danh mục<br/>- Trạng thái]
    EqFilters --> EqCharts[Charts:<br/>- Line<br/>- Bar<br/>- Pie]
    EqCharts --> EqTable[Bảng Chi Tiết]
    
    Borrow --> BrFilters[Bộ Lọc:<br/>- Thời gian<br/>- User<br/>- Trạng thái]
    BrFilters --> BrCharts[Charts:<br/>- Xu hướng<br/>- Quá hạn<br/>- Duration]
    BrCharts --> BrTable[Bảng Chi Tiết]
    
    Users --> CheckAdmin{Admin?}
    CheckAdmin -->|Không| NoAccess[Từ Chối]
    CheckAdmin -->|Có| UserStats[Thống Kê:<br/>- Active<br/>- Top users<br/>- Activity]
    
    Custom --> Builder[Report Builder:<br/>1. Chọn dữ liệu<br/>2. Chọn fields<br/>3. Chọn filters<br/>4. Chọn chart]
    Builder --> Preview[Preview]
    Preview --> SaveTemplate{Lưu?}
    
    SaveTemplate -->|Có| Save[Lưu Template]
    SaveTemplate -->|Không| ShowReport[Hiện Báo Cáo]
    Save --> ShowReport
    
    Charts --> Export{Export?}
    EqTable --> Export
    BrTable --> Export
    UserStats --> Export
    ShowReport --> Export
    
    Export -->|Có| ChooseFormat[Chọn Format:<br/>- PDF<br/>- Excel<br/>- CSV<br/>- Image]
    Export -->|Không| Sections
    
    ChooseFormat --> Download[Download]
    Download --> Sections
    
    NoAccess --> Sections
    BasicView --> End([Kết Thúc])
    
    style Start fill:#4CAF50
    style NoAccess fill:#F44336
```

## Tóm Tắt

### Quyền Truy Cập
- **Guest**: Thống kê cơ bản
- **User+**: Dashboard đầy đủ
- **Admin**: Thêm phân tích users

### 5 Phần Chính

1. **Tổng Quan**
   - Cards: Số liệu nhanh
   - Charts: Timeline, Top TB, Phân bố

2. **Phân Tích Thiết Bị**
   - Lọc: Thời gian, danh mục, trạng thái
   - Charts: Line, Bar, Pie
   - Bảng chi tiết

3. **Phân Tích Mượn Trả**
   - Xu hướng requests
   - Quá hạn tracking
   - Duration analysis

4. **Phân Tích Users** (Admin)
   - Active users
   - Top borrowers
   - Activity patterns

5. **Báo Cáo Tùy Chỉnh**
   - Report Builder
   - Chọn data, fields, filters, charts
   - Lưu template
   - Schedule auto-generate

### Export
- PDF, Excel, CSV, Image
- Áp dụng cho tất cả reports
