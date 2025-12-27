import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double radius;

  const Skeleton({super.key, this.height, this.width, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class MovieCardSkeleton extends StatelessWidget {
  const MovieCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: Skeleton(radius: 16),
        ),
        const SizedBox(height: 8),
        const Center(child: Skeleton(height: 14, width: 100, radius: 4)),
        const SizedBox(height: 4),
        const Center(child: Skeleton(height: 14, width: 80, radius: 4)),
      ],
    );
  }
}

class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;

  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.childAspectRatio = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const MovieCardSkeleton(),
    );
  }
}

class MovieDetailSkeleton extends StatelessWidget {
  const MovieDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 500, width: double.infinity, radius: 0),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 32, width: 250, radius: 8),
                const SizedBox(height: 16),
                const Row(
                  children: [
                     Skeleton(height: 30, width: 60, radius: 16),
                     SizedBox(width: 12),
                     Skeleton(height: 30, width: 60, radius: 16),
                     SizedBox(width: 12),
                     Skeleton(height: 30, width: 80, radius: 16),
                  ],
                ),
                const SizedBox(height: 32),
                 const Skeleton(height: 50, width: double.infinity, radius: 16), // Button
                 const SizedBox(height: 32),
                 const Skeleton(height: 20, width: 100, radius: 4), // Title
                 const SizedBox(height: 12),
                 const Skeleton(height: 100, width: double.infinity, radius: 12), // Text
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
     return Padding(
       padding: const EdgeInsets.all(24),
       child: Column(
         children: const [
           SizedBox(height: 40),
           Center(child: Skeleton(height: 100, width: 100, radius: 50)),
           SizedBox(height: 24),
           Center(child: Skeleton(height: 24, width: 200, radius: 4)),
           SizedBox(height: 8),
           Center(child: Skeleton(height: 16, width: 150, radius: 4)),
           SizedBox(height: 40),
           Skeleton(height: 60, width: double.infinity, radius: 12),
           SizedBox(height: 16),
           Skeleton(height: 60, width: double.infinity, radius: 12),
         ],
       ),
     );
  }
}
