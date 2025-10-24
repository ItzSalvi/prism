import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern logo container with gradient and shadow
            Container(
              width: 100,
              height: 100,
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
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFEF4444).withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(-3, -3),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            SizedBox(height: 24),
            
            // PRISM title with modern styling
            Text(
              'PRISM',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Health Monitoring System',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 32),
            
            // Modern loading indicator
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SpinKitPulse(
                    color: Color(0xFFDC2626),
                    size: 50.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
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
}