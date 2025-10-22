import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/dashboard_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading user data
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
      return ProfileSkeleton();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Sign Out'),
                      content: Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            authProvider.signOut();
                          },
                          child: Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(user),
                SizedBox(height: 20),
                _buildPersonalInfo(user),
                SizedBox(height: 20),
                _buildEmergencyContacts(),
                SizedBox(height: 20),
                _buildSettings(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ... rest of your _buildProfileHeader, _buildPersonalInfo, etc. methods remain the same
  Widget _buildProfileHeader(User? user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              backgroundImage: user?.photoURL != null 
                  ? NetworkImage(user!.photoURL!) 
                  : null,
              child: user?.photoURL == null
                  ? Icon(Icons.person, size: 40, color: Colors.blue[800])
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Member since ${_getMemberSince(user)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _getMemberSince(User? user) {
    if (user?.metadata.creationTime != null) {
      return '${user!.metadata.creationTime!.year}';
    }
    return '2024';
  }

  Widget _buildPersonalInfo(User? user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoItem('Email', user?.email ?? 'Not set'),
            _buildInfoItem('Phone', '+1 (555) 123-4567'),
            _buildInfoItem('Emergency Contact', 'Mary Doe - +1 (555) 987-6543'),
            _buildInfoItem('Primary Physician', 'Dr. Smith - Cardiology'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {},
                ),
              ],
            ),
            _buildContactItem('Mary Doe', 'Spouse', '+1 (555) 987-6543'),
            _buildContactItem('Dr. Smith', 'Physician', '+1 (555) 456-7890'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(String name, String relationship, String phone) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Icon(Icons.person, color: Colors.blue[800]),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('$relationship • $phone'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.message, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.call, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildSettingItem('Notification Settings', Icons.notifications),
          _buildSettingItem('Measurement Reminders', Icons.access_alarm),
          _buildSettingItem('Data Sharing', Icons.share),
          _buildSettingItem('Privacy & Security', Icons.security),
          _buildSettingItem('Help & Support', Icons.help),
          _buildSettingItem('About PRISM', Icons.info),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[800]),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}