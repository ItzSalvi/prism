import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/insights_skeleton.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _timeRange = 'Month'; // 'Week', 'Month', 'Year'
  
  // Real user data
  List<Map<String, dynamic>> _measurements = [];
  double _averageSystolic = 0.0;
  double _averageDiastolic = 0.0;
  double _averageHeartRate = 0.0;
  int _totalReadings = 0;
  String _riskLevel = 'Low';
  double _riskPercentage = 30.0;
  List<Map<String, dynamic>> _recommendations = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;
      
      // Load user profile (for future use)
      await firebaseService.getUserProfile(authProvider.user!.uid);
      
      // Load measurements based on time range
      _measurements = await firebaseService.getRecentMeasurements(
        authProvider.user!.uid,
        limit: _getLimitForTimeRange(),
      );
      
      // Calculate insights from real data
      _calculateInsights();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getLimitForTimeRange() {
    switch (_timeRange) {
      case 'Week':
        return 7;
      case 'Month':
        return 30;
      case 'Year':
        return 365;
      default:
        return 30;
    }
  }

  void _calculateInsights() {
    if (_measurements.isEmpty) {
      _averageSystolic = 0.0;
      _averageDiastolic = 0.0;
      _averageHeartRate = 0.0;
      _totalReadings = 0;
      _riskLevel = 'Unknown';
      _riskPercentage = 0.0;
      _recommendations = _getDefaultRecommendations();
      return;
    }

    // Calculate averages
    double totalSystolic = 0.0;
    double totalDiastolic = 0.0;
    double totalHeartRate = 0.0;

    for (var measurement in _measurements) {
      totalSystolic += (measurement['systolic'] ?? 0).toDouble();
      totalDiastolic += (measurement['diastolic'] ?? 0).toDouble();
      totalHeartRate += (measurement['heartRate'] ?? 0).toDouble();
    }

    _totalReadings = _measurements.length;
    _averageSystolic = totalSystolic / _totalReadings;
    _averageDiastolic = totalDiastolic / _totalReadings;
    _averageHeartRate = totalHeartRate / _totalReadings;

    // Calculate risk assessment
    _calculateRiskAssessment();
    
    // Generate personalized recommendations
    _generateRecommendations();
  }

  void _calculateRiskAssessment() {
    // Risk assessment based on blood pressure categories
    if (_averageSystolic >= 140 || _averageDiastolic >= 90) {
      _riskLevel = 'High';
      _riskPercentage = 85.0;
    } else if (_averageSystolic >= 130 || _averageDiastolic >= 80) {
      _riskLevel = 'Medium';
      _riskPercentage = 60.0;
    } else if (_averageSystolic >= 120 || _averageDiastolic >= 80) {
      _riskLevel = 'Elevated';
      _riskPercentage = 45.0;
    } else {
      _riskLevel = 'Low';
      _riskPercentage = 25.0;
    }
  }

  void _generateRecommendations() {
    _recommendations = [];
    
    // Generate recommendations based on actual data
    if (_averageSystolic >= 140 || _averageDiastolic >= 90) {
      _recommendations.add({
        'title': 'Consult Your Doctor',
        'description': 'Your blood pressure readings indicate hypertension. Please consult with your healthcare provider immediately.',
        'icon': Icons.medical_services_rounded,
        'color': Color(0xFFEF4444),
        'priority': 'high'
      });
    }
    
    if (_averageSystolic >= 120) {
      _recommendations.add({
        'title': 'Reduce Sodium Intake',
        'description': 'Aim for less than 2,300mg per day to help lower your blood pressure.',
        'icon': Icons.restaurant_rounded,
        'color': Color(0xFFEF4444),
        'priority': 'medium'
      });
    }
    
    if (_averageHeartRate > 100) {
      _recommendations.add({
        'title': 'Stress Management',
        'description': 'Your heart rate suggests elevated stress. Practice relaxation techniques.',
        'icon': Icons.self_improvement_rounded,
        'color': Color(0xFF8B5CF6),
        'priority': 'medium'
      });
    }
    
    if (_totalReadings < 7) {
      _recommendations.add({
        'title': 'Increase Monitoring',
        'description': 'Take more frequent readings to get better insights into your health patterns.',
        'icon': Icons.monitor_heart_rounded,
        'color': Color(0xFFDC2626),
        'priority': 'medium'
      });
    }
    
    // Add general recommendations if no specific ones
    if (_recommendations.isEmpty) {
      _recommendations = _getDefaultRecommendations();
    }
  }

  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'title': 'Regular Physical Activity',
        'description': '30 minutes of moderate exercise daily can improve cardiovascular health.',
        'icon': Icons.directions_run_rounded,
        'color': Color(0xFF10B981),
        'priority': 'low'
      },
      {
        'title': 'Balanced Diet',
        'description': 'Focus on fruits, vegetables, and whole grains for optimal heart health.',
        'icon': Icons.fastfood_rounded,
        'color': Color(0xFFF59E0B),
        'priority': 'low'
      },
      {
        'title': 'Adequate Sleep',
        'description': 'Aim for 7-9 hours of quality sleep each night for better health.',
        'icon': Icons.bedtime_rounded,
        'color': Color(0xFF8B5CF6),
        'priority': 'low'
      }
    ];
  }

  Color _getRiskColor() {
    switch (_riskLevel) {
      case 'High':
        return Color(0xFFEF4444);
      case 'Medium':
        return Color(0xFFF59E0B);
      case 'Elevated':
        return Color(0xFF8B5CF6);
      case 'Low':
        return Color(0xFF10B981);
      default:
        return Color(0xFF6B7280);
    }
  }

  List<Color> _getRiskGradientColors() {
    switch (_riskLevel) {
      case 'High':
        return [Color(0xFFEF4444), Color(0xFFDC2626)];
      case 'Medium':
        return [Color(0xFFF59E0B), Color(0xFFD97706)];
      case 'Elevated':
        return [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
      case 'Low':
        return [Color(0xFF10B981), Color(0xFF059669)];
      default:
        return [Color(0xFF6B7280), Color(0xFF4B5563)];
    }
  }

  String _getRiskDescription() {
    switch (_riskLevel) {
      case 'High':
        return 'Immediate medical attention recommended';
      case 'Medium':
        return 'Monitor closely and consult healthcare provider';
      case 'Elevated':
        return 'Take preventive measures';
      case 'Low':
        return 'Continue your healthy habits';
      default:
        return 'Insufficient data for assessment';
    }
  }

  String _getRiskAnalysisText() {
    if (_measurements.isEmpty) {
      return 'No measurement data available. Start taking regular blood pressure readings to get personalized health insights and risk assessment.';
    }
    
    switch (_riskLevel) {
      case 'High':
        return 'Your blood pressure readings indicate hypertension. Please consult with your healthcare provider immediately for proper treatment and monitoring.';
      case 'Medium':
        return 'Your blood pressure is elevated. Consider lifestyle changes and consult your healthcare provider for guidance on managing your blood pressure.';
      case 'Elevated':
        return 'Your blood pressure is slightly elevated. Focus on lifestyle modifications like diet, exercise, and stress management to prevent further increases.';
      case 'Low':
        return 'Based on your recent readings, your blood pressure is within a healthy range. Continue maintaining your healthy habits and regular monitoring.';
      default:
        return 'Insufficient data available for a comprehensive risk assessment. Please take more measurements to get accurate insights.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return InsightsSkeleton();
    }
    
    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Health Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTimeRangeFilter(),
                    SizedBox(height: 16),
                    _buildRiskCard(),
                    SizedBox(height: 16),
                    _buildTrendChart(),
                    SizedBox(height: 16),
                    _buildHealthMetrics(),
                    SizedBox(height: 16),
                    _buildRecommendations(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeFilter() {
    final timeRanges = ['Week', 'Month', 'Year'];
    
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Time Range:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          Row(
            children: timeRanges.map((range) {
              bool isSelected = _timeRange == range;
              return Padding(
                padding: EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _timeRange = range;
                      _isLoading = true;
                    });
                    _loadUserData();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFDC2626) : Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      range,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hypertension Risk Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981).withOpacity(0.1),
                  Color(0xFF059669).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_riskLevel Risk Level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _getRiskColor(),
                            ),
                          ),
                          Text(
                            _getRiskDescription(),
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_riskPercentage.toInt()}%',
                        style: TextStyle(
                          color: _getRiskColor(),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          height: 12,
                          width: constraints.maxWidth * (_riskPercentage / 100),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getRiskGradientColors(),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: _getRiskColor().withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Low',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Medium',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      'High',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  _getRiskAnalysisText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Blood Pressure Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFF3F4F6)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFFDC2626),
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Blood Pressure Trends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last $_timeRange',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrendIndicator('Systolic', Color(0xFFEF4444), 'Stable', Icons.arrow_upward_rounded),
              _buildTrendIndicator('Diastolic', Color(0xFFF59E0B), 'Stable', Icons.remove_rounded),
              _buildTrendIndicator('Heart Rate', Color(0xFFDC2626), 'Normal', Icons.favorite_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(String title, Color color, String status, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Health Metrics Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Average Systolic', '${_averageSystolic.toInt()}', 'mmHg', Color(0xFFEF4444), Icons.arrow_upward_rounded),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem('Average Diastolic', '${_averageDiastolic.toInt()}', 'mmHg', Color(0xFFF59E0B), Icons.arrow_downward_rounded),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Readings Taken', '$_totalReadings', 'times', Color(0xFFDC2626), Icons.history_rounded),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem('Heart Rate', '${_averageHeartRate.toInt()}', 'bpm', Color(0xFF10B981), Icons.favorite_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.recommend_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Personalized Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...(_recommendations.isEmpty 
            ? [
                _buildRecommendationItem(
                  'No Data Available',
                  'Start taking measurements to get personalized health insights and recommendations.',
                  Icons.info_outline_rounded,
                  Color(0xFF6B7280),
                ),
              ]
            : _recommendations.map((rec) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildRecommendationItem(
                  rec['title'],
                  rec['description'],
                  rec['icon'],
                  rec['color'],
                ),
              )).toList()
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}