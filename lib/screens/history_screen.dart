import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/history_skeleton.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _statusFilter = 'All'; // 'All', 'Normal', 'Elevated'
  String _timeFilter = 'All'; // 'All', 'Day', 'Week', 'Month', 'Year'
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Database data
  List<Map<String, dynamic>> _allReadings = [];
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadHistoryData();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadHistoryData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      // Fetch measurements from Firebase
      List<Map<String, dynamic>> measurements = await _firebaseService.getRecentMeasurements(userId, limit: 100);
      
      // Transform database data to match UI format
      List<Map<String, dynamic>> transformedReadings = measurements.map((measurement) {
        DateTime timestamp;
        if (measurement['timestamp'] is DateTime) {
          timestamp = measurement['timestamp'];
        } else if (measurement['timestamp'] != null) {
          // Handle Firestore Timestamp
          timestamp = DateTime.fromMillisecondsSinceEpoch(measurement['timestamp'].millisecondsSinceEpoch);
        } else {
          // Fallback to current time if timestamp is missing
          timestamp = DateTime.now();
        }
        
        bool isAbnormal = measurement['isAbnormal'] ?? false;
        String status = isAbnormal ? 'Elevated' : 'Normal';
        
        return {
          'id': measurement['id'],
          'date': timestamp,
          'systolic': measurement['systolic'] ?? 0,
          'diastolic': measurement['diastolic'] ?? 0,
          'heartRate': measurement['heartRate'] ?? 0,
          'spo2': measurement['spo2'] ?? 0.0,
          'status': status,
        };
      }).toList();

      setState(() {
        _allReadings = transformedReadings;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load history: $e';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReadings {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> filtered = _allReadings;

    // Apply time filter
    if (_timeFilter != 'All') {
      filtered = filtered.where((reading) {
        DateTime readingDate = reading['date'];
        switch (_timeFilter) {
          case 'Day':
            return readingDate.year == now.year &&
                   readingDate.month == now.month &&
                   readingDate.day == now.day;
          case 'Week':
            DateTime weekAgo = now.subtract(Duration(days: 7));
            return readingDate.isAfter(weekAgo);
          case 'Month':
            return readingDate.year == now.year &&
                   readingDate.month == now.month;
          case 'Year':
            return readingDate.year == now.year;
          default:
            return true;
        }
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((reading) => reading['status'] == _statusFilter).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b['date'].compareTo(a['date']));

    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedReadings {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var reading in _filteredReadings) {
      String dateKey = _getDateGroupKey(reading['date']);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(reading);
    }
    
    return grouped;
  }

  String _getDateGroupKey(DateTime date) {
    if (_timeFilter == 'Day') {
      return 'Today';
    } else if (_timeFilter == 'Week') {
      return 'This Week';
    } else if (_timeFilter == 'Month') {
      return 'This Month';
    } else if (_timeFilter == 'Year') {
      return 'This Year';
    } else {
      // For 'All' filter, group by actual date
      if (date.year == DateTime.now().year && 
          date.month == DateTime.now().month && 
          date.day == DateTime.now().day) {
        return 'Today';
      } else if (date.year == DateTime.now().year && 
                 date.month == DateTime.now().month) {
        return 'This Month';
      } else if (date.year == DateTime.now().year) {
        return 'This Year';
      } else {
        return '${_getMonthName(date.month)} ${date.year}';
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    if (date.year == DateTime.now().year && 
        date.month == DateTime.now().month && 
        date.day == DateTime.now().day) {
      return 'Today, ${_formatTime(date)}';
    } else if (date.year == DateTime.now().year && 
               date.month == DateTime.now().month && 
               date.day == DateTime.now().day - 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${_formatTime(date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return HistorySkeleton();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    final filteredReadings = _filteredReadings;
    final totalReadings = filteredReadings.length;
    final normalReadings = filteredReadings.where((r) => r['status'] == 'Normal').length;
    final elevatedReadings = filteredReadings.where((r) => r['status'] == 'Elevated').length;

    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Measurement History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistoryData,
            icon: Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          _buildFilterButton(),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  // Time Filter Chips
                  _buildTimeFilterChips(),
                  SizedBox(height: 16),
                  
                  // Summary Cards
                  _buildSummaryCards(totalReadings, normalReadings, elevatedReadings),
                  SizedBox(height: 16),
                  
                  // History List
                  Expanded(
                    child: _buildHistoryList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeFilterChips() {
    final timeFilters = ['All', 'Day', 'Week', 'Month', 'Year'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: timeFilters.map((filter) {
          bool isSelected = _timeFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _timeFilter = filter;
                });
              },
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selectedColor: Color(0xFFDC2626),
              checkmarkColor: Colors.white,
              backgroundColor: Color(0xFFF3F4F6),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _statusFilter = value;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'All',
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text('All Readings'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Normal',
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text('Normal Only'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Elevated',
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text('Elevated Only'),
            ],
          ),
        ),
      ],
      child: Container(
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: Color(0xFFDC2626),
              size: 18,
            ),
            SizedBox(width: 4),
            Text(
              _statusFilter,
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(int total, int normal, int elevated) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard('Total Readings', '$total', Icons.history_rounded, Color(0xFFDC2626)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard('Normal', '$normal', Icons.check_circle_rounded, Color(0xFF10B981)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard('Elevated', '$elevated', Icons.warning_rounded, Color(0xFFF59E0B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final groupedReadings = _groupedReadings;
    
    if (groupedReadings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              color: Color(0xFF9CA3AF),
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'No readings found',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try changing your filters or start measuring',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        ...groupedReadings.entries.map((entry) {
          String dateGroup = entry.key;
          List<Map<String, dynamic>> readings = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(dateGroup),
              SizedBox(height: 12),
              ...readings.map((reading) => _buildHistoryItem(reading)),
              SizedBox(height: 20),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDateHeader(String dateGroup) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Text(
            dateGroup,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          Spacer(),
          Text(
            '${_groupedReadings[dateGroup]!.length} readings',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> reading) {
    Color statusColor = reading['status'] == 'Normal' ? Color(0xFF10B981) : Color(0xFFF59E0B);
    
    return GestureDetector(
      onTap: () {
        _showReadingDetailsModal(reading);
      },
      child: Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading['systolic']}/${reading['diastolic']} mmHg',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${reading['heartRate']} bpm',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.air_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${reading['spo2']?.toStringAsFixed(1) ?? '0.0'}%',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF6B7280),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _formatDate(reading['date']),
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  reading['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Measurement History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistoryData,
            icon: Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 80,
              ),
              SizedBox(height: 24),
              Text(
                'Failed to Load History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadHistoryData,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadingDetailsModal(Map<String, dynamic> reading) {
    // Determine blood pressure status and colors
    int systolic = reading['systolic'] as int;
    int diastolic = reading['diastolic'] as int;
    
    Color statusColor;
    List<Color> gradientColors;
    Color borderColor;
    Color textColor;
    
    if (systolic < 120 && diastolic < 80) {
      statusColor = Color(0xFF10B981); // Green
      gradientColors = [Color(0xFFF0FDF4), Color(0xFFDCFCE7)];
      borderColor = Color(0xFFBBF7D0);
      textColor = Color(0xFF059669);
    } else if (systolic < 130 && diastolic < 80) {
      statusColor = Color(0xFFF59E0B); // Yellow
      gradientColors = [Color(0xFFFFFBEB), Color(0xFFFEF3C7)];
      borderColor = Color(0xFFFDE68A);
      textColor = Color(0xFFD97706);
    } else {
      statusColor = Color(0xFFEF4444); // Red
      gradientColors = [Color(0xFFFEF2F2), Color(0xFFFEE2E2)];
      borderColor = Color(0xFFFECACA);
      textColor = Color(0xFFDC2626);
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  gradientColors[1].withOpacity(0.3),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blood Pressure Reading',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDate(reading['date']),
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Main reading
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${reading['systolic']}/${reading['diastolic']} mmHg',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getBloodPressureCategory(reading['systolic'], reading['diastolic']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Additional readings
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        'Heart Rate',
                        '${reading['heartRate']} bpm',
                        Icons.favorite_rounded,
                        Color(0xFFEF4444),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailCard(
                        'SpO2',
                        '${reading['spo2']?.toStringAsFixed(1) ?? '0.0'}%',
                        Icons.air_rounded,
                        Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Notes section
                if (reading['notes'] != null && reading['notes'].toString().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          reading['notes'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else if (systolic < 140 || diastolic < 90) {
      return 'High Blood Pressure Stage 1';
    } else {
      return 'High Blood Pressure Stage 2';
    }
  }
}