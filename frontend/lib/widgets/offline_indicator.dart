import 'package:flutter/material.dart';

class OfflineIndicator extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onToggle;

  const OfflineIndicator({super.key, required this.isOffline, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOffline ? Colors.orange[800] : Colors.green[800],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.wifi,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isOffline ? 'OFFLINE' : 'ONLINE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineInfoDialog extends StatelessWidget {
  final Map<String, String> emergencyNumbers;

  const OfflineInfoDialog({super.key, required this.emergencyNumbers});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange),
          SizedBox(width: 8),
          Text('Offline Mode'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You are currently in offline mode. The app is showing cached data from your last online session.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Limited functionality available:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeature('📍 Cached campground locations', true),
            _buildFeature('🔥 Last known fire points', true),
            _buildFeature('⚠️ Safety alerts', true),
            _buildFeature('🔄 Real-time updates', false),
            _buildFeature('📡 Live weather data', false),
            _buildFeature('📤 Submit reports', false),
            const SizedBox(height: 16),
            const Text(
              'Emergency Numbers:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...emergencyNumbers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    SelectableText(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        ElevatedButton(
          onPressed: () {
            // Gerçek uygulamada offline moddan çıkmak için yenileme yapılacak
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attempting to reconnect...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Try to Reconnect'),
        ),
      ],
    );
  }

  Widget _buildFeature(String text, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: available ? Colors.black87 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineStorageInfo extends StatelessWidget {
  final int campgroundCount;
  final int firePointCount;
  final DateTime lastUpdate;
  final VoidCallback onClearCache;

  const OfflineStorageInfo({
    super.key,
    required this.campgroundCount,
    required this.firePointCount,
    required this.lastUpdate,
    required this.onClearCache,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline Storage Info',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Campgrounds cached:', '$campgroundCount'),
          _buildInfoRow('Fire points cached:', '$firePointCount'),
          _buildInfoRow('Last update:', _formatDate(lastUpdate)),
          const SizedBox(height: 16),
          const Text(
            'Cache will expire after 6 hours. Clear cache manually if you experience issues.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onClearCache,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Clear All Cached Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
