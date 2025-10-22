import 'package:flutter/material.dart';
import '../widgets/history_skeleton.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading history data
    Future.delayed(Duration(milliseconds: 1500), () {
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
      return HistorySkeleton();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurement History'),
        actions: [
          IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildDateSection('Today', [
            _buildHistoryItem('128/82', '72 bpm', '8:30 AM', 'Normal'),
            _buildHistoryItem('130/84', '75 bpm', '2:15 PM', 'Normal'),
          ]),
          _buildDateSection('Yesterday', [
            _buildHistoryItem('135/85', '78 bpm', '8:15 AM', 'Elevated'),
          ]),
          _buildDateSection('December 10, 2024', [
            _buildHistoryItem('122/78', '70 bpm', '8:45 AM', 'Normal'),
          ]),
        ],
      ),
    );
  }

  Widget _buildDateSection(String date, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ),
        ...items,
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryItem(String reading, String heartRate, String time, String status) {
    Color statusColor = status == 'Normal' ? Colors.green : Colors.orange;
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.favorite, color: Colors.blue[800], size: 20),
        ),
        title: Text(
          reading,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Heart Rate: $heartRate'),
            Text(time),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}