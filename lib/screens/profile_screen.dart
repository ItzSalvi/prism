import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  int _totalReadings = 0;
  int _normalReadings = 0;
  int _elevatedReadings = 0;

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

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user != null) {
        // Load user profile
        final userProfile = await firebaseService.getUserProfile(authProvider.user!.uid);
        
        // Load all measurements for statistics
        final measurements = await firebaseService.getRecentMeasurements(authProvider.user!.uid, limit: 100);
        
        if (mounted) {
          setState(() {
            _userProfile = userProfile;
            _totalReadings = measurements.length;
            
            // Calculate reading statistics
            _normalReadings = measurements.where((m) {
              int systolic = m['systolic'] as int;
              int diastolic = m['diastolic'] as int;
              return systolic < 120 && diastolic < 80;
            }).length;
            
            _elevatedReadings = measurements.where((m) {
              int systolic = m['systolic'] as int;
              int diastolic = m['diastolic'] as int;
              return systolic >= 120 || diastolic >= 80;
            }).length;
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: Color(0xFFFEF7F7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                  onPressed: () {
                    _showLogoutDialog(context, authProvider);
                  },
                ),
              ),
            ],
          ),
          body: _isLoading 
              ? _buildProfileSkeleton()
              : AnimatedBuilder(
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
                              _buildProfileHeader(user),
                              SizedBox(height: 16),
                              _buildHealthStats(),
                              SizedBox(height: 16),
                              _buildPersonalInfo(user),
                              SizedBox(height: 16),
                              _buildEmergencyContacts(),
                              SizedBox(height: 16),
                              _buildSettings(),
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 40, backgroundColor: Color(0xFFE5E7EB)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 20, width: 150, color: Color(0xFFE5E7EB)),
                      SizedBox(height: 8),
                      Container(height: 16, width: 200, color: Color(0xFFE5E7EB)),
                      SizedBox(height: 4),
                      Container(height: 16, width: 120, color: Color(0xFFE5E7EB)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                authProvider.signOut();
              },
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
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
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: user?.photoURL != null 
                    ? ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Color(0xFFDC2626),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Color(0xFFDC2626),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(user),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.email_rounded, size: 16, color: Color(0xFF6B7280)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user?.email ?? 'No email',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6B7280)),
                    SizedBox(width: 6),
                    Text(
                      'Member since ${_getMemberSince(user)}',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStats() {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Health Overview',
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('$_totalReadings', 'Total\nReadings', Color(0xFFDC2626)),
              _buildStatItem('$_normalReadings', 'Normal\nReadings', Color(0xFF10B981)),
              _buildStatItem('$_elevatedReadings', 'Elevated\nReadings', Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(User? user) {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoItem('Email Address', user?.email ?? 'Not set', Icons.email_rounded),
          _buildInfoItem('Phone Number', _getPhoneNumber(), Icons.phone_rounded),
          _buildInfoItem('Emergency Contact', _getEmergencyContact(), Icons.emergency_rounded),
          _buildInfoItem('Primary Physician', _getPhysician(), Icons.medical_services_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFFDC2626), size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emergency_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_getEmergencyContactName().isNotEmpty)
            _buildContactItem(_getEmergencyContactName(), 'Emergency Contact', _getEmergencyPhone()),
          if (_getPhysician().isNotEmpty) ...[
            SizedBox(height: 12),
            _buildContactItem(_getPhysician(), 'Primary Physician', ''),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, String relationship, String phone) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_rounded, color: Color(0xFFDC2626), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$relationship • $phone',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.message_rounded, color: Color(0xFF10B981), size: 18),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFDC2626).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.call_rounded, color: Color(0xFFDC2626), size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildSettingItem('Notification Settings', Icons.notifications_active_rounded, Color(0xFFEF4444)),
          _buildSettingItem('Measurement Reminders', Icons.access_alarm_rounded, Color(0xFFF59E0B)),
          _buildSettingItem('Data Sharing', Icons.share_rounded, Color(0xFF3B82F6)),
          _buildSettingItem('Privacy & Security', Icons.security_rounded, Color(0xFF10B981)),
          _buildSettingItem('Help & Support', Icons.help_rounded, Color(0xFF8B5CF6)),
          _buildSettingItem('About PRISM', Icons.info_rounded, Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF3F4F6)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF9CA3AF)),
        onTap: () {},
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  String _getMemberSince(User? user) {
    if (user?.metadata.creationTime != null) {
      return '${user!.metadata.creationTime!.year}';
    }
    return '2024';
  }

  String _getDisplayName(User? user) {
    if (_userProfile != null) {
      if (_userProfile!['fullName'] != null) {
        return _userProfile!['fullName'];
      } else if (_userProfile!['firstName'] != null && _userProfile!['lastName'] != null) {
        return '${_userProfile!['firstName']} ${_userProfile!['lastName']}';
      }
    }
    return user?.displayName ?? 'User';
  }

  String _getPhoneNumber() {
    return _userProfile?['phoneNumber'] ?? 'Not set';
  }

  String _getEmergencyContact() {
    if (_userProfile != null) {
      String name = _userProfile!['emergencyContact'] ?? '';
      String phone = _userProfile!['emergencyPhone'] ?? '';
      if (name.isNotEmpty && phone.isNotEmpty) {
        return '$name - $phone';
      } else if (name.isNotEmpty) {
        return name;
      }
    }
    return 'Not set';
  }

  String _getEmergencyContactName() {
    return _userProfile?['emergencyContact'] ?? '';
  }

  String _getEmergencyPhone() {
    return _userProfile?['emergencyPhone'] ?? '';
  }

  String _getPhysician() {
    return _userProfile?['physician'] ?? '';
  }
}