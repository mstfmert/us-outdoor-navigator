import 'package:flutter/material.dart';

class SafetyBarWidget extends StatefulWidget {
  final bool isWarningActive;
  final String warningMessage;
  final VoidCallback? onTap;

  const SafetyBarWidget({
    super.key,
    required this.isWarningActive,
    this.warningMessage = 'EVACUATION WARNING',
    this.onTap,
  });

  @override
  State<SafetyBarWidget> createState() => _SafetyBarWidgetState();
}

class _SafetyBarWidgetState extends State<SafetyBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isWarningActive) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red[900]!.withOpacity(_opacityAnimation.value),
                  Colors.red[700]!.withOpacity(_opacityAnimation.value),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.warningMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SafetyStatusIndicator extends StatelessWidget {
  final String status; // SAFE, DANGER, UNKNOWN
  final String message;

  const SafetyStatusIndicator({
    super.key,
    required this.status,
    required this.message,
  });

  Color get statusColor {
    switch (status) {
      case 'SAFE':
        return Colors.green;
      case 'DANGER':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'SAFE':
        return Icons.check_circle;
      case 'DANGER':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety Status: ${status.toUpperCase()}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}