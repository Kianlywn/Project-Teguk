import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/providers/weather_provider.dart';

class WeatherBanner extends StatelessWidget {
  const WeatherBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weather, _) {
        if (weather.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Memuat cuaca lokasi...'),
                ],
              ),
            ),
          );
        }

        if (weather.error != null) {
          return Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.error!,
                      style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = weather.weather;
        if (data == null) return const SizedBox.shrink();

        final adjustment = weather.waterAdjustment;

        return Card(
          elevation: 0,
          color: const Color(0xFF2196F3).withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF2196F3).withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  data.isHot ? Icons.wb_sunny : Icons.cloud,
                  color: const Color(0xFF2196F3),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.cityName} · ${data.temperatureLabel}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      if (adjustment > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Cuaca panas — tambah +$adjustment ml hari ini',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
