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

  String _selectedChart = 'Equipment Usage Over Time';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  final List<String> _chartTypes = [
    'Equipment Usage Over Time',
    'Borrow Trends by Category',
    'Equipment Status Distribution',
    'User Activity',
    'Top Borrowed Equipment',
    'Return Rate',
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
        title: const Text('Analytics Dashboard'),
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
                    labelText: 'Select Chart Type',
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
      case 'Equipment Usage Over Time':
        return _buildEquipmentUsageChart();
      case 'Borrow Trends by Category':
        return _buildBorrowTrendsByCategoryChart();
      case 'Equipment Status Distribution':
        return _buildEquipmentStatusPieChart();
      case 'User Activity':
        return _buildUserActivityChart();
      case 'Top Borrowed Equipment':
        return _buildTopBorrowedEquipmentChart();
      case 'Return Rate':
        return _buildReturnRateChart();
      default:
        return const Center(child: Text('Chart not available'));
    }
  }

  Widget _buildEquipmentUsageChart() {
    return _buildChartCard(
      title: 'Equipment Usage Over Time',
      description: 'Shows equipment borrowing trends over the selected period',
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
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
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
      title: 'Borrow Trends by Category',
      description: 'Equipment borrow requests grouped by category',
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
                      'Cat A',
                      'Cat B',
                      'Cat C',
                      'Cat D',
                      'Cat E',
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
      title: 'Equipment Status Distribution',
      description: 'Current status breakdown of all equipment',
      chart: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                value: 45,
                title: 'Available',
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
                title: 'Borrowed',
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
                title: 'Maintenance',
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
                title: 'Out of Order',
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
      title: 'User Activity',
      description: 'Number of active users per day',
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
                    'Day ${value.toInt() + 1}',
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
      title: 'Top Borrowed Equipment',
      description: 'Most frequently borrowed items',
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
                      'Item 1',
                      'Item 2',
                      'Item 3',
                      'Item 4',
                      'Item 5',
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
      title: 'Return Rate Analysis',
      description: 'On-time vs late returns',
      chart: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                value: 75,
                title: 'On Time\n75%',
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
                title: 'Late\n15%',
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
                title: 'Overdue\n10%',
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
