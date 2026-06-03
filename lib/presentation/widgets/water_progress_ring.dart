import 'package:flutter/material.dart';

class WaterProgressRing extends StatelessWidget {
  final double progress;
  final int totalMl;
  final int targetMl;
  final bool isLoading;

  const WaterProgressRing({
    super.key,
    required this.progress,
    required this.totalMl,
    required this.targetMl,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: isLoading ? null : clamped,
              strokeWidth: 14,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop, color: Color(0xFF2196F3), size: 28),
              const SizedBox(height: 4),
              Text(
                '$totalMl',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'dari $targetMl ml',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '${(clamped * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
