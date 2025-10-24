import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PRISM Dashboard'),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCardSkeleton(),
            SizedBox(height: 20),
            _buildVitalStatsSkeleton(),
            SizedBox(height: 20),
            _buildRecentReadingsSkeleton(),
            SizedBox(height: 20),
            _buildRiskAssessmentSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCardSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Container(
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
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // PRISM Logo skeleton
                SkeletonBox(width: 120, height: 36, borderRadius: BorderRadius.circular(4)),
                SizedBox(height: 20),
                
                // Profile circle skeleton
                SkeletonAvatar(size: 100, hasIcon: true),
                SizedBox(height: 16),
                
                // Greeting text skeleton
                SkeletonText(width: 150, height: 16),
                SizedBox(height: 8),
                
                // User name skeleton
                SkeletonText(width: 200, height: 20),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitalStatsSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 150, height: 20),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVitalItemSkeleton(),
                  _buildVitalItemSkeleton(),
                  _buildVitalItemSkeleton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalItemSkeleton() {
    return Column(
      children: [
        SkeletonBox(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(30),
        ),
        SizedBox(height: 8),
        SkeletonBox(width: 60, height: 12),
        SizedBox(height: 4),
        SkeletonBox(width: 40, height: 10),
      ],
    );
  }

  Widget _buildRecentReadingsSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 150, height: 20),
                  SkeletonBox(width: 60, height: 16),
                ],
              ),
              SizedBox(height: 12),
              _buildReadingItemSkeleton(),
              _buildReadingItemSkeleton(),
              _buildReadingItemSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingItemSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 80, height: 16),
                SizedBox(height: 4),
                SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
          SkeletonBox(
            width: 60,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: SkeletonCard(
        hasHeader: true,
        hasFooter: true,
        children: [
          // Risk level badge
          SkeletonBox(
            width: double.infinity,
            height: 40,
            borderRadius: BorderRadius.circular(20),
          ),
          SizedBox(height: 16),
          
          // Progress bar
          SkeletonProgressBar(progress: 0.4),
          SizedBox(height: 12),
          
          // Risk percentage and level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(width: 100, height: 14),
              SkeletonText(width: 60, height: 14),
            ],
          ),
          SizedBox(height: 16),
          
          // Risk description
          SkeletonText(width: double.infinity, height: 14, lines: 2),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeaderSkeleton(),
            SizedBox(height: 20),
            _buildPersonalInfoSkeleton(),
            SizedBox(height: 20),
            _buildEmergencyContactsSkeleton(),
            SizedBox(height: 20),
            _buildSettingsSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SkeletonCircle(radius: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 20),
                    SizedBox(height: 8),
                    SkeletonBox(width: 150, height: 16),
                    SizedBox(height: 4),
                    SkeletonBox(width: 100, height: 16),
                  ],
                ),
              ),
              SkeletonBox(width: 24, height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 180, height: 20),
              SizedBox(height: 16),
              _buildInfoItemSkeleton(),
              _buildInfoItemSkeleton(),
              _buildInfoItemSkeleton(),
              _buildInfoItemSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItemSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 100, height: 16),
          SizedBox(width: 16),
          Expanded(
            child: SkeletonBox(width: double.infinity, height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 150, height: 20),
                  SkeletonBox(width: 24, height: 24),
                ],
              ),
              SizedBox(height: 16),
              _buildContactItemSkeleton(),
              _buildContactItemSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItemSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SkeletonCircle(radius: 20),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 16),
                SizedBox(height: 4),
                SkeletonBox(width: 150, height: 12),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 24, height: 24),
              SizedBox(width: 8),
              SkeletonBox(width: 24, height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            _buildSettingItemSkeleton(),
            _buildSettingItemSkeleton(),
            _buildSettingItemSkeleton(),
            _buildSettingItemSkeleton(),
            _buildSettingItemSkeleton(),
            _buildSettingItemSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItemSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SkeletonBox(width: 24, height: 24),
          SizedBox(width: 16),
          Expanded(
            child: SkeletonBox(width: 150, height: 16),
          ),
          SkeletonBox(width: 16, height: 16),
        ],
      ),
    );
  }
}









