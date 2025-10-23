import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class InsightsSkeleton extends StatelessWidget {
  const InsightsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Insights'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRiskCardSkeleton(),
            SizedBox(height: 20),
            _buildTrendChartSkeleton(),
            SizedBox(height: 20),
            _buildRecommendationsSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCardSkeleton() {
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
                children: [
                  SkeletonBox(width: 20, height: 20),
                  SizedBox(width: 8),
                  SkeletonBox(width: 150, height: 18),
                ],
              ),
              SizedBox(height: 16),
              SkeletonBox(
                width: double.infinity,
                height: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 60, height: 16),
                  SkeletonBox(width: 30, height: 16),
                ],
              ),
              SizedBox(height: 8),
              SkeletonBox(width: double.infinity, height: 14),
              SizedBox(height: 4),
              SkeletonBox(width: 200, height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChartSkeleton() {
    return SkeletonLoader(
      isLoading: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 180, height: 18),
              SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonBox(width: 200, height: 16),
                      SizedBox(height: 8),
                      SkeletonBox(width: 150, height: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTrendIndicatorSkeleton(),
                  _buildTrendIndicatorSkeleton(),
                  _buildTrendIndicatorSkeleton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicatorSkeleton() {
    return Column(
      children: [
        SkeletonBox(
          width: 8,
          height: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        SizedBox(height: 4),
        SkeletonBox(width: 50, height: 12),
        SizedBox(height: 2),
        SkeletonBox(width: 40, height: 10),
      ],
    );
  }

  Widget _buildRecommendationsSkeleton() {
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
                children: [
                  SkeletonBox(width: 20, height: 20),
                  SizedBox(width: 8),
                  SkeletonBox(width: 150, height: 18),
                ],
              ),
              SizedBox(height: 16),
              _buildRecommendationItemSkeleton(),
              _buildRecommendationItemSkeleton(),
              _buildRecommendationItemSkeleton(),
              _buildRecommendationItemSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationItemSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 20, height: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: 4),
                SkeletonBox(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}









