import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
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
          _buildDateSectionSkeleton('Today'),
          _buildDateSectionSkeleton('Yesterday'),
          _buildDateSectionSkeleton('December 10, 2024'),
        ],
      ),
    );
  }

  Widget _buildDateSectionSkeleton(String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SkeletonLoader(
            isLoading: true,
            child: SkeletonBox(width: 120, height: 16),
          ),
        ),
        _buildHistoryItemSkeleton(),
        _buildHistoryItemSkeleton(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryItemSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 1,
        margin: EdgeInsets.only(bottom: 8),
        child: Container(
          padding: EdgeInsets.all(16),
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
                    SkeletonBox(width: 80, height: 18),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 14),
                    SizedBox(height: 4),
                    SkeletonBox(width: 100, height: 14),
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
        ),
      ),
    );
  }
}






