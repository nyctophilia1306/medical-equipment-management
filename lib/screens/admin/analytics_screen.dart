import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../services/statistics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final StatisticsService _statsService = StatisticsService();

  String _selectedChart = 'Thiết bị sử dụng theo thời gian';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  final List<String> _chartTypes = [
    'Thiết bị sử dụng theo thời gian',
    'Xu hướng mượn theo danh mục',
    'Phân phối trạng thái thiết bị',
    'Hoạt động người dùng',
    'Thiết bị mượn nhiều nhất',
    'Tỷ lệ trả lại',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _statsService.getSystemStatistics();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.textOnPrimary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text('Thống Kê & Phân Tích'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppColors.backgroundWhite,
            child: Column(
              children: [
                // Chart Type Selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedChart,
                  decoration: const InputDecoration(
                    labelText: 'Chọn loại biểu đồ',
                    prefixIcon: Icon(Icons.analytics_outlined),
                  ),
                  items: _chartTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedChart = value);
                    }
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Date Range Selector
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),

          // Chart Display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: _buildSelectedChart(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedChart) {
      case 'Thiết bị sử dụng theo thời gian':
        return _buildEquipmentUsageChart();
      case 'Xu hướng mượn theo danh mục':
        return _buildBorrowTrendsByCategoryChart();
      case 'Phân phối trạng thái thiết bị':
        return _buildEquipmentStatusPieChart();
      case 'Hoạt động người dùng':
        return _buildUserActivityChart();
      case 'Thiết bị mượn nhiều nhất':
        return _buildTopBorrowedEquipmentChart();
      case 'Tỷ lệ trả lại':
        return _buildReturnRateChart();
      default:
        return const Center(child: Text('Chart not available'));
    }
  }

  Widget _buildEquipmentUsageChart() {
    return _buildChartCard(
      title: 'Thiết bị sử dụng theo thời gian',
      description: 'Hiển thị xu hướng mượn thiết bị trong khoảng thời gian đã chọn',
      chart: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = [
                      'Thứ 2',
                      'Thứ 3',
                      'Thứ 4',
                      'Thứ 5',
                      'Thứ 6',
                      'Thứ 7',
                      'Chủ Nhật',
                    ];
                    return Text(
                      days[value.toInt() % 7],
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  const FlSpot(0, 3),
                  const FlSpot(1, 5),
                  const FlSpot(2, 4),
                  const FlSpot(3, 7),
                  const FlSpot(4, 6),
                  const FlSpot(5, 8),
                  const FlSpot(6, 5),
                ],
                isCurved: true,
                color: AppColors.primaryBlue,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorrowTrendsByCategoryChart() {
    return _buildChartCard(
      title: 'Xu hướng mượn theo danh mục',
      description: 'Yêu cầu mượn thiết bị được nhóm theo danh mục',
      chart: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const categories = [
                      'Danh mục A',
                      'Danh mục B',
                      'Danh mục C',
                      'Danh mục D',
                      'Danh mục E',
                    ];
                    if (value.toInt() < categories.length) {
                      return Text(
                        categories[value.toInt()],
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(toY: 8, color: AppColors.primaryBlue),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(toY: 10, color: AppColors.successGreen),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(toY: 6, color: AppColors.warningYellow),
                ],
              ),
              BarChartGroupData(
                x: 3,
                barRods: [BarChartRodData(toY: 12, color: AppColors.softTeal)],
              ),
              BarChartGroupData(
                x: 4,
                barRods: [
                  BarChartRodData(toY: 5, color: AppColors.grayNeutral600),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentStatusPieChart() {
    return _buildChartCard(
      title: 'Trạng thái thiết bị',
      description: 'Phân bố trạng thái hiện tại của tất cả thiết bị',
      chart: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                value: 45,
                title: 'Sẵn có',
                color: AppColors.successGreen,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              PieChartSectionData(
                value: 30,
                title: 'Đang mượn',
                color: AppColors.warningYellow,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              PieChartSectionData(
                value: 15,
                title: 'Bảo trì',
                color: AppColors.primaryBlue,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              PieChartSectionData(
                value: 10,
                title: 'Hỏng',
                color: AppColors.errorRed,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserActivityChart() {
    return _buildChartCard(
      title: 'Hoạt động người dùng',
      description: 'Số lượng người dùng hoạt động mỗi ngày',
      chart: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    'Ngày ${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  const FlSpot(0, 12),
                  const FlSpot(1, 15),
                  const FlSpot(2, 10),
                  const FlSpot(3, 18),
                  const FlSpot(4, 14),
                  const FlSpot(5, 20),
                  const FlSpot(6, 16),
                ],
                isCurved: true,
                color: AppColors.successGreen,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBorrowedEquipmentChart() {
    return _buildChartCard(
      title: 'Top Thiết bị được mượn',
      description: 'Các thiết bị được mượn nhiều nhất',
      chart: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const items = [
                      'Thiết bị 1',
                      'Thiết bị 2',
                      'Thiết bị 3',
                      'Thiết bị 4',
                      'Thiết bị 5',
                    ];
                    if (value.toInt() < items.length) {
                      return Text(
                        items[value.toInt()],
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(toY: 25, color: AppColors.primaryBlue),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(toY: 20, color: AppColors.primaryBlue),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(toY: 18, color: AppColors.primaryBlue),
                ],
              ),
              BarChartGroupData(
                x: 3,
                barRods: [
                  BarChartRodData(toY: 15, color: AppColors.primaryBlue),
                ],
              ),
              BarChartGroupData(
                x: 4,
                barRods: [
                  BarChartRodData(toY: 12, color: AppColors.primaryBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnRateChart() {
    return _buildChartCard(
      title: 'Phân tích tỷ lệ trả',
      description: 'Trả đúng hạn và trả muộn',
      chart: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                value: 75,
                title: 'Trả đúng hạn\n75%',
                color: AppColors.successGreen,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              PieChartSectionData(
                value: 15,
                title: 'Trả muộn\n15%',
                color: AppColors.warningYellow,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              PieChartSectionData(
                value: 10,
                title: 'Quá hạn\n10%',
                color: AppColors.errorRed,
                radius: 100,
                titleStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String description,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          chart,
        ],
      ),
    );
  }
}
