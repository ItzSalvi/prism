import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class SkeletonExamples extends StatefulWidget {
  const SkeletonExamples({super.key});

  @override
  _SkeletonExamplesState createState() => _SkeletonExamplesState();
}

class _SkeletonExamplesState extends State<SkeletonExamples> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skeleton Loading Examples'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              Future.delayed(Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicExample(),
            SizedBox(height: 20),
            _buildCardExample(),
            SizedBox(height: 20),
            _buildListExample(),
            SizedBox(height: 20),
            _buildCustomShimmerExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Skeleton Components',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        SkeletonLoader(
          isLoading: _isLoading,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      SkeletonCircle(radius: 25),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 200, height: 16),
                            SizedBox(height: 8),
                            SkeletonBox(width: 150, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SkeletonBox(width: double.infinity, height: 20),
                  SizedBox(height: 8),
                  SkeletonBox(width: 250, height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card with Skeleton Loading',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        SkeletonLoader(
          isLoading: _isLoading,
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
                      _buildVitalSkeleton(),
                      _buildVitalSkeleton(),
                      _buildVitalSkeleton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalSkeleton() {
    return Column(
      children: [
        SkeletonBox(
          width: 50,
          height: 50,
          borderRadius: BorderRadius.circular(25),
        ),
        SizedBox(height: 8),
        SkeletonBox(width: 60, height: 12),
        SizedBox(height: 4),
        SkeletonBox(width: 40, height: 10),
      ],
    );
  }

  Widget _buildListExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'List with Skeleton Loading',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        SkeletonLoader(
          isLoading: _isLoading,
          child: Card(
            elevation: 2,
            child: Column(
              children: [
                SkeletonListTile(),
                Divider(height: 1),
                SkeletonListTile(),
                Divider(height: 1),
                SkeletonListTile(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomShimmerExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Shimmer Colors',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        SkeletonLoader(
          isLoading: _isLoading,
          baseColor: Colors.blue[100],
          highlightColor: Colors.blue[50],
          child: Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonBox(width: double.infinity, height: 20),
                  SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 16),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      SkeletonBox(width: 100, height: 40),
                      SizedBox(width: 16),
                      SkeletonBox(width: 100, height: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}









