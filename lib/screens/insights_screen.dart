import 'package:flutter/material.dart';
import '../widgets/insights_skeleton.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading insights data
    Future.delayed(Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return InsightsSkeleton();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Insights'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRiskCard(),
            SizedBox(height: 20),
            _buildTrendChart(),
            SizedBox(height: 20),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue[800]),
                SizedBox(width: 8),
                Text(
                  'Hypertension Risk Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.3,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low Risk', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('30%', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Based on your recent readings and patterns, your risk of developing hypertension is low.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blood Pressure Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Chart showing BP trends over time\n(Chart implementation would go here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTrendIndicator('Systolic', Colors.blue, 'Stable'),
                _buildTrendIndicator('Diastolic', Colors.green, 'Stable'),
                _buildTrendIndicator('Heart Rate', Colors.orange, 'Normal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(String title, Color color, String status) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12)),
        Text(status, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.blue[800]),
                SizedBox(width: 8),
                Text(
                  'Health Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildRecommendationItem(
              'Reduce sodium intake',
              'Aim for less than 2,300mg per day',
            ),
            _buildRecommendationItem(
              'Regular exercise',
              '30 minutes of moderate activity daily',
            ),
            _buildRecommendationItem(
              'Monitor stress levels',
              'Practice relaxation techniques',
            ),
            _buildRecommendationItem(
              'Maintain healthy weight',
              'Follow balanced diet and portion control',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}