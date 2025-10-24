import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const SkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  _SkeletonLoaderState createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? Color(0xFFF3F4F6),
                widget.highlightColor ?? Color(0xFFFEE2E2),
                widget.baseColor ?? Color(0xFFF3F4F6),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final double? height;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 56,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (hasLeading) ...[
            SkeletonBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
          if (hasTrailing) ...[
            SizedBox(width: 16),
            SkeletonBox(width: 24, height: 24),
          ],
        ],
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double? radius;

  const SkeletonCircle({
    super.key,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius != null ? radius! * 2 : 40,
      height: radius != null ? radius! * 2 : 40,
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? lines;

  const SkeletonText({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.lines,
  });

  @override
  Widget build(BuildContext context) {
    if (lines != null && lines! > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines!, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < lines! - 1 ? 8 : 0),
            child: SkeletonBox(
              width: index == lines! - 1 ? (width ?? 200) * 0.7 : width ?? 200,
              height: height ?? 16,
              borderRadius: borderRadius ?? BorderRadius.circular(4),
            ),
          );
        }),
      );
    }
    
    return SkeletonBox(
      width: width,
      height: height ?? 16,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    );
  }
}

class SkeletonButton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonButton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 120,
      height: height ?? 40,
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
    );
  }
}

class SkeletonProgressBar extends StatelessWidget {
  final double? width;
  final double? height;
  final double? progress;
  final BorderRadius? borderRadius;

  const SkeletonProgressBar({
    super.key,
    this.width,
    this.height,
    this.progress,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 8,
      decoration: BoxDecoration(
        color: Color(0xFFE5E7EB),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Container(
            width: (width ?? 200) * (progress ?? 0.6),
            height: height ?? 8,
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: borderRadius ?? BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double? size;
  final bool hasIcon;

  const SkeletonAvatar({
    super.key,
    this.size,
    this.hasIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 50,
      height: size ?? 50,
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: hasIcon
          ? Icon(
              Icons.person,
              color: Color(0xFF9CA3AF),
              size: (size ?? 50) * 0.6,
            )
          : null,
    );
  }
}

class SkeletonChart extends StatelessWidget {
  final double? width;
  final double? height;
  final int? dataPoints;

  const SkeletonChart({
    super.key,
    this.width,
    this.height,
    this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart title
            SkeletonBox(width: 150, height: 16),
            SizedBox(height: 20),
            // Chart area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(dataPoints ?? 7, (index) {
                  return SkeletonBox(
                    width: 8,
                    height: 20 + (index * 15.0),
                    borderRadius: BorderRadius.circular(4),
                  );
                }),
              ),
            ),
            SizedBox(height: 16),
            // X-axis labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(dataPoints ?? 7, (index) {
                return SkeletonBox(width: 20, height: 12);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final List<Widget> children;
  final bool hasHeader;
  final bool hasFooter;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
    required this.children,
    this.hasHeader = false,
    this.hasFooter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader) ...[
              Row(
                children: [
                  SkeletonBox(width: 24, height: 24, borderRadius: BorderRadius.circular(12)),
                  SizedBox(width: 12),
                  SkeletonBox(width: 120, height: 18),
                  Spacer(),
                  SkeletonBox(width: 60, height: 16, borderRadius: BorderRadius.circular(8)),
                ],
              ),
              SizedBox(height: 16),
            ],
            ...children,
            if (hasFooter) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 80, height: 14),
                  SkeletonBox(width: 60, height: 14),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}









