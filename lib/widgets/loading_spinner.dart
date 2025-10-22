import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'PRISM',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            SpinKitFadingCircle(
              color: Colors.blue[800]!,
              size: 30.0,
            ),
          ],
        ),
      ),
    );
  }
}