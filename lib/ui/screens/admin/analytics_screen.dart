import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Overview'), Tab(text: 'Donors'), Tab(text: 'Requests')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverview(),
            const Center(child: Text('Donor Statistics')),
            const Center(child: Text('Request Statistics')),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Request Distribution by Blood Group', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(color: AppColors.bloodOPos, value: 40, title: 'O+', radius: 50),
                  PieChartSectionData(color: AppColors.bloodAPos, value: 30, title: 'A+', radius: 50),
                  PieChartSectionData(color: AppColors.bloodBPos, value: 20, title: 'B+', radius: 50),
                  PieChartSectionData(color: AppColors.bloodABPos, value: 10, title: 'AB+', radius: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
