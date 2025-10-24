import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "Loading...";
  String _hypertensionRisk = "Low Risk";
  Color _riskColor = Color(0xFF10B981);
  String _riskDescription = "Continue healthy habits";
  double _riskPercentage = 0.3;
  List<Map<String, dynamic>> _recentReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user != null) {
        // Load user profile
        final userProfile = await firebaseService.getUserProfile(authProvider.user!.uid);
        
        // Load recent measurements
        final recentMeasurements = await firebaseService.getRecentMeasurements(authProvider.user!.uid, limit: 4);
        
        if (mounted) {
          setState(() {
            _recentReadings = recentMeasurements;
            _isLoading = false;
            
            // Update user name
            if (userProfile != null) {
              if (userProfile['fullName'] != null) {
                _userName = userProfile['fullName'];
              } else if (userProfile['firstName'] != null && userProfile['lastName'] != null) {
                _userName = '${userProfile['firstName']} ${userProfile['lastName']}';
              } else {
                _userName = authProvider.user!.displayName ?? 'User';
              }
            } else {
              _userName = authProvider.user!.displayName ?? 'User';
            }
            
            // Calculate risk based on recent readings
            _calculateRiskLevel();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userName = 'User';
        });
      }
    }
  }

  void _calculateRiskLevel() {
    if (_recentReadings.isEmpty) {
      _hypertensionRisk = "No Data";
      _riskColor = Color(0xFF6B7280);
      _riskDescription = "Take your first measurement to assess risk";
      _riskPercentage = 0.0;
      return;
    }

    // Calculate average systolic and diastolic from recent readings
    double avgSystolic = _recentReadings.map((r) => r['systolic'] as int).reduce((a, b) => a + b) / _recentReadings.length;
    double avgDiastolic = _recentReadings.map((r) => r['diastolic'] as int).reduce((a, b) => a + b) / _recentReadings.length;

    // Determine risk level based on AHA guidelines
    if (avgSystolic < 120 && avgDiastolic < 80) {
      _hypertensionRisk = "Low Risk";
      _riskColor = Color(0xFF10B981);
      _riskDescription = "Excellent! Keep maintaining healthy habits";
      _riskPercentage = 0.2;
    } else if (avgSystolic < 130 && avgDiastolic < 80) {
      _hypertensionRisk = "Elevated Risk";
      _riskColor = Color(0xFFF59E0B);
      _riskDescription = "Monitor closely and maintain healthy lifestyle";
      _riskPercentage = 0.4;
    } else if (avgSystolic < 140 || avgDiastolic < 90) {
      _hypertensionRisk = "High Risk";
      _riskColor = Color(0xFFEF4444);
      _riskDescription = "Consider consulting your physician";
      _riskPercentage = 0.7;
    } else {
      _hypertensionRisk = "Very High Risk";
      _riskColor = Color(0xFFDC2626);
      _riskDescription = "Please consult your physician immediately";
      _riskPercentage = 0.9;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with User Profile
            _buildHeaderSection(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Hypertension Risk Card
            _buildRiskAssessment(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Recent Readings
            _buildRecentReadings(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
            Color(0xFF991B1B),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isSmallScreen ? 20 : 30),
          bottomRight: Radius.circular(isSmallScreen ? 20 : 30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEF4444).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // PRISM Logo/Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'PRISM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 32 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Profile Circle - Centered
            Center(
              child: Container(
                width: isSmallScreen ? 90 : 100,
                height: isSmallScreen ? 90 : 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFFECACA),
                      Color(0xFFFEE2E2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(-3, -3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(_userName),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            // Greeting Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _getGreeting(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 8 : 12),
            
            // User Name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _userName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessment(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFEF7F7),
            ],
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFEE2E2),
                          Color(0xFFFECACA),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFECACA).withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFFDC2626),
                      size: isSmallScreen ? 20 : 22,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Expanded(
                    child: Text(
                      'Hypertension Risk',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 16 : 18),
              
              // Risk Level
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 18, 
                  vertical: isSmallScreen ? 10 : 12
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _riskColor.withOpacity(0.12),
                      _riskColor.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                  border: Border.all(color: _riskColor.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: _riskColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _hypertensionRisk,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 17,
                      fontWeight: FontWeight.w800,
                      color: _riskColor,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 16 : 18),
              
              // Progress Bar
              Stack(
                children: [
                  // Background track
                  Container(
                    height: isSmallScreen ? 12 : 14,
                    decoration: BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress
                  Container(
                    height: isSmallScreen ? 12 : 14,
                    width: math.max(0.0, (MediaQuery.of(context).size.width - (isSmallScreen ? 56 : 72)) * _riskPercentage),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _riskColor,
                          _riskColor.withOpacity(0.7),
                          _riskColor,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 7),
                      boxShadow: [
                        BoxShadow(
                          color: _riskColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 10 : 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_riskPercentage * 100).toInt()}% Risk Level',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    _getRiskLevelText(_riskPercentage),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: _riskColor,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 14 : 16),
              
              // Risk Description
              Text(
                _riskDescription,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReadings(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFEF7F7),
            ],
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFEE2E2),
                          Color(0xFFFECACA),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFECACA).withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Color(0xFFDC2626),
                      size: isSmallScreen ? 20 : 22,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Expanded(
                    child: Text(
                      'Recent Blood Pressure',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  // View All Button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14, 
                        vertical: isSmallScreen ? 6 : 7
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFEF2F2),
                            Color(0xFFFEE2E2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 16 : 18),
              
              // Recent Readings List
              if (_isLoading)
                Container(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                    ),
                  ),
                )
              else if (_recentReadings.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No measurements yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Take your first measurement to see your data here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _recentReadings.map((reading) {
                    return Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                      child: _buildReadingItem(reading, isSmallScreen),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingItem(Map<String, dynamic> reading, bool isSmallScreen) {
    // Determine status based on blood pressure values
    int systolic = reading['systolic'] as int;
    int diastolic = reading['diastolic'] as int;
    
    String status;
    Color statusColor;
    
    if (systolic < 120 && diastolic < 80) {
      status = 'Normal';
      statusColor = Color(0xFF10B981);
    } else if (systolic < 130 && diastolic < 80) {
      status = 'Elevated';
      statusColor = Color(0xFFF59E0B);
    } else if (systolic < 140 || diastolic < 90) {
      status = 'High';
      statusColor = Color(0xFFEF4444);
    } else {
      status = 'Very High';
      statusColor = Color(0xFFDC2626);
    }
    
    // Format timestamp
    String timeString = 'No time data';
    if (reading['timestamp'] != null) {
      DateTime timestamp = reading['timestamp'] is DateTime 
          ? reading['timestamp'] 
          : DateTime.fromMillisecondsSinceEpoch(reading['timestamp'].millisecondsSinceEpoch);
      
      DateTime now = DateTime.now();
      Duration difference = now.difference(timestamp);
      
      if (difference.inDays == 0) {
        timeString = 'Today, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        timeString = 'Yesterday, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      } else {
        timeString = '${timestamp.day}/${timestamp.month}, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      }
    }
    
    return GestureDetector(
      onTap: () {
        // Navigate to history screen
        Navigator.of(context).pushNamed('/history');
      },
      child: Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardColors(statusColor),
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.25),
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: statusColor,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          
          SizedBox(width: isSmallScreen ? 12 : 14),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading['systolic']}/${reading['diastolic']} mmHg',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 3 : 4),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12, 
              vertical: isSmallScreen ? 5 : 6
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.12),
                  statusColor.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              border: Border.all(color: statusColor.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.08),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 5 : 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: isSmallScreen ? 11 : 12,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String _getRiskLevelText(double percentage) {
    if (percentage < 0.3) return 'Low';
    if (percentage < 0.6) return 'Medium';
    return 'High';
  }

  // Helper method to get card colors based on blood pressure status
  List<Color> _getCardColors(Color statusColor) {
    if (statusColor == Color(0xFF10B981)) {
      // Normal - Green
      return [
        Color(0xFFF0FDF4),
        Color(0xFFDCFCE7),
        Color(0xFFBBF7D0),
      ];
    } else if (statusColor == Color(0xFFF59E0B)) {
      // Elevated - Yellow
      return [
        Color(0xFFFFFBEB),
        Color(0xFFFEF3C7),
        Color(0xFFFDE68A),
      ];
    } else {
      // High/Very High - Red
      return [
        Color(0xFFFEF2F2),
        Color(0xFFFEE2E2),
        Color(0xFFFECACA),
      ];
    }
  }
}