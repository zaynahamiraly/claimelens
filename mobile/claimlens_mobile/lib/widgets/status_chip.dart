import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'VERIFIED' || 'APPROVED' || 'PAID' => Colors.green,
      'REVIEW_REQUIRED' ||
      'INFORMATION_REQUIRED' ||
      'PAYMENT_PENDING' =>
        Colors.orange,
      'PROCESSING_FAILED' || 'REJECTED' => Colors.red,
      'INFORMATION_RECEIVED' => Colors.teal,
      'PROCESSING' => Colors.blue,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? color.shade200
              : color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
