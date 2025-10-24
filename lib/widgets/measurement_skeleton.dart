import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class MeasurementSkeleton extends StatelessWidget {
  const MeasurementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Pressure Measurement'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMeasurementCardSkeleton(),
            SizedBox(height: 20),
            _buildManualInputSkeleton(),
            SizedBox(height: 20),
            _buildSymptomsChecklistSkeleton(),
            SizedBox(height: 20),
            _buildSaveButtonSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCardSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SkeletonBox(width: 50, height: 50, borderRadius: BorderRadius.circular(25)),
              SizedBox(height: 16),
              SkeletonBox(width: 150, height: 18),
              SizedBox(height: 8),
              SkeletonBox(width: 250, height: 16),
              SizedBox(height: 20),
              SkeletonBox(
                width: 200,
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualInputSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: SkeletonCard(
        hasHeader: true,
        children: [
          // Blood pressure inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 80, height: 14),
                    SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE5E7EB)),
                      ),
                      child: Center(
                        child: SkeletonText(width: 60, height: 18),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 80, height: 14),
                    SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE5E7EB)),
                      ),
                      child: Center(
                        child: SkeletonText(width: 60, height: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Heart rate input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(width: 100, height: 14),
              SizedBox(height: 8),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: SkeletonText(width: 60, height: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsChecklistSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 150, height: 18),
              SizedBox(height: 16),
              _buildSymptomItemSkeleton(),
              _buildSymptomItemSkeleton(),
              _buildSymptomItemSkeleton(),
              _buildSymptomItemSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomItemSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SkeletonBox(width: 20, height: 20, borderRadius: BorderRadius.circular(4)),
          SizedBox(width: 12),
          Expanded(
            child: SkeletonBox(width: double.infinity, height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButtonSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: SkeletonButton(
        width: double.infinity,
        height: 50,
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }
}









