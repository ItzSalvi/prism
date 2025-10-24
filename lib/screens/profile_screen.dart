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
              Spacer(),
              GestureDetector(
                onTap: () => _showEditPersonalInfoDialog(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoItem('Full Name', _getFullName(), Icons.person_rounded),
          _buildInfoItem('Email Address', user?.email ?? 'Not set', Icons.email_rounded),
          _buildInfoItem('Phone Number', _getPhoneNumber(), Icons.phone_rounded),
          _buildInfoItem('Birth Date', _getBirthDate(), Icons.calendar_today_rounded),
          _buildInfoItem('Age', _getAge(), Icons.cake_rounded),
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
              GestureDetector(
                onTap: () => _showAddEmergencyContactDialog(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_getEmergencyContactName().isNotEmpty)
            _buildEmergencyContactItem(_getEmergencyContactName(), _getEmergencyPhone()),
          if (_getPhysician().isNotEmpty) ...[
            SizedBox(height: 12),
            _buildPhysicianItem(_getPhysician()),
          ],
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
          _buildSettingItem('About PRISM', Icons.info_rounded, Color(0xFF6B7280), () => _showAboutDialog()),
          SizedBox(height: 16),
          _buildDeleteAccountButton(),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, Color color, VoidCallback onTap) {
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
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFECACA)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 20),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF4444),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFEF4444)),
        onTap: () => _showDeleteAccountDialog(),
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


  String _getEmergencyContactName() {
    return _userProfile?['emergencyContact'] ?? '';
  }

  String _getEmergencyPhone() {
    return _userProfile?['emergencyPhone'] ?? '';
  }

  String _getPhysician() {
    return _userProfile?['physician'] ?? '';
  }

  String _getFullName() {
    if (_userProfile != null) {
      if (_userProfile!['fullName'] != null) {
        return _userProfile!['fullName'];
      } else if (_userProfile!['firstName'] != null && _userProfile!['lastName'] != null) {
        return '${_userProfile!['firstName']} ${_userProfile!['lastName']}';
      }
    }
    return 'Not set';
  }

  String _getBirthDate() {
    if (_userProfile != null && _userProfile!['birthDate'] != null) {
      DateTime birthDate = _userProfile!['birthDate'].toDate();
      return '${birthDate.day}/${birthDate.month}/${birthDate.year}';
    }
    return 'Not set';
  }

  String _getAge() {
    if (_userProfile != null && _userProfile!['age'] != null) {
      return '${_userProfile!['age']} years old';
    }
    return 'Not set';
  }

  Widget _buildEmergencyContactItem(String name, String phone) {
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
            child: Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 20),
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
                  phone,
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
              GestureDetector(
                onTap: () => _showEditEmergencyContactDialog(name, phone),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 18),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDeleteEmergencyContactDialog(name),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicianItem(String name) {
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
            child: Icon(Icons.medical_services_rounded, color: Color(0xFFDC2626), size: 20),
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
                  'Primary Physician',
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
              GestureDetector(
                onTap: () => _showEditPhysicianDialog(name),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 18),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDeletePhysicianDialog(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditPersonalInfoDialog() {
    final firstNameController = TextEditingController(text: _userProfile?['firstName'] ?? '');
    final middleNameController = TextEditingController(text: _userProfile?['middleName'] ?? '');
    final lastNameController = TextEditingController(text: _userProfile?['lastName'] ?? '');
    final phoneController = TextEditingController(text: _userProfile?['phoneNumber'] ?? '');
    
    DateTime? selectedBirthDate = _userProfile?['birthDate']?.toDate();
    int? calculatedAge;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                  child: Icon(Icons.edit_rounded, color: Color(0xFFDC2626), size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditTextField('First Name', firstNameController, Icons.person_rounded),
                  SizedBox(height: 16),
                  _buildEditTextField('Middle Name', middleNameController, Icons.person_rounded),
                  SizedBox(height: 16),
                  _buildEditTextField('Last Name', lastNameController, Icons.person_rounded),
                  SizedBox(height: 16),
                  _buildEditTextField('Phone Number', phoneController, Icons.phone_rounded, TextInputType.phone),
                  SizedBox(height: 16),
                  _buildBirthDateField(selectedBirthDate, calculatedAge, (date, age) {
                    setState(() {
                      selectedBirthDate = date;
                      calculatedAge = age;
                    });
                  }),
                ],
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
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () async {
                    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('First name and last name are required')),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    await _updatePersonalInfo(
                      firstNameController.text.trim(),
                      middleNameController.text.trim(),
                      lastNameController.text.trim(),
                      phoneController.text.trim(),
                      selectedBirthDate,
                      calculatedAge,
                    );
                  },
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEmergencyContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

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
              child: Icon(Icons.add_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add Emergency Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditTextField('Contact Name', nameController, Icons.person_rounded),
            SizedBox(height: 16),
            _buildEditTextField('Phone Number', phoneController, Icons.phone_rounded, TextInputType.phone),
          ],
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
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Name and phone number are required')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _updateEmergencyContact(nameController.text.trim(), phoneController.text.trim());
              },
              child: Text(
                'Add Contact',
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

  void _showEditEmergencyContactDialog(String name, String phone) {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);

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
              child: Icon(Icons.edit_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit Emergency Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditTextField('Contact Name', nameController, Icons.person_rounded),
            SizedBox(height: 16),
            _buildEditTextField('Phone Number', phoneController, Icons.phone_rounded, TextInputType.phone),
          ],
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
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Name and phone number are required')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _updateEmergencyContact(nameController.text.trim(), phoneController.text.trim());
              },
              child: Text(
                'Save Changes',
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

  void _showDeleteEmergencyContactDialog(String name) {
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
              child: Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Emergency Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name" from your emergency contacts?',
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
              onPressed: () async {
                Navigator.pop(context);
                await _deleteEmergencyContact();
              },
              child: Text(
                'Delete',
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

  void _showEditPhysicianDialog(String name) {
    final TextEditingController physicianController = TextEditingController(text: name);
    
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
              child: Icon(Icons.edit_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit Physician',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditTextField('Physician Name', physicianController, Icons.person_rounded),
          ],
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
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updatePhysician(physicianController.text.trim());
              },
              child: Text(
                'Save',
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

  void _showDeletePhysicianDialog() {
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
              child: Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Physician',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your primary physician information?',
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
              onPressed: () async {
                Navigator.pop(context);
                await _deletePhysician();
              },
              child: Text(
                'Delete',
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

  void _showAboutDialog() {
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
              child: Icon(Icons.info_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'About PRISM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRISM - Hypertension Risk Monitor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'PRISM is a comprehensive hypertension monitoring application that helps you track your blood pressure, monitor your health trends, and receive personalized insights to prevent hypertension risks.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Real-time blood pressure monitoring\n• Health trend analysis\n• Personalized recommendations\n• Emergency contact management\n• Data export and sharing',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
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

  void _showDeleteAccountDialog() {
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
              child: Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ WARNING: This action cannot be undone!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Deleting your account will permanently remove:',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• All your health records and measurements\n• Personal information and profile data\n• Emergency contact information\n• All associated data and history',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Are you absolutely sure you want to delete your account?',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAccount();
              },
              child: Text(
                'Delete Account',
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

  // Helper methods for edit dialogs
  Widget _buildEditTextField(String label, TextEditingController controller, IconData icon, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 12, left: 4),
          padding: EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Color(0xFFDC2626),
            size: 20,
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBirthDateField(DateTime? selectedDate, int? age, Function(DateTime?, int?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth Date',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Color(0xFFDC2626),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF1F2937),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (picked != null) {
              int calculatedAge = DateTime.now().year - picked.year;
              if (DateTime.now().month < picked.month || 
                  (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) {
                calculatedAge--;
              }
              onChanged(picked, calculatedAge);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFFDC2626), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                        : 'Select your birth date',
                    style: TextStyle(
                      color: selectedDate != null ? Color(0xFF1F2937) : Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (age != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Age: $age',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Implementation methods
  Future<void> _updatePersonalInfo(String firstName, String middleName, String lastName, String phoneNumber, DateTime? birthDate, int? age) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;

      await firebaseService.updateUserProfile(
        userId: authProvider.user!.uid,
        firstName: firstName,
        middleName: middleName.isNotEmpty ? middleName : null,
        lastName: lastName,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        birthDate: birthDate,
        age: age,
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personal information updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update personal information: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _updateEmergencyContact(String name, String phone) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;

      await firebaseService.updateEmergencyContact(
        userId: authProvider.user!.uid,
        emergencyContact: name,
        emergencyPhone: phone,
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency contact updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update emergency contact: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deleteEmergencyContact() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;

      await firebaseService.updateEmergencyContact(
        userId: authProvider.user!.uid,
        emergencyContact: '',
        emergencyPhone: '',
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency contact deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete emergency contact: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _updatePhysician(String physicianName) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;

      if (physicianName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a physician name'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      await firebaseService.updatePhysician(
        userId: authProvider.user!.uid,
        physician: physicianName,
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Physician information updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update physician information: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deletePhysician() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;

      await firebaseService.updatePhysician(
        userId: authProvider.user!.uid,
        physician: null,
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Physician information deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete physician information: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      if (authProvider.user == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
              ),
              SizedBox(height: 16),
              Text(
                'Deleting account and all data...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );

      await firebaseService.deleteUserAccount(authProvider.user!.uid);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}