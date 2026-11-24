import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/claim.dart';
import '../screens/claim_details_screen.dart';
import 'status_chip.dart';

class ClaimCard extends StatelessWidget {
  const ClaimCard({super.key, required this.claim});
  final ClaimSummary claim;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClaimDetailsScreen(reference: claim.reference),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      claim.reference,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    StatusChip(status: claim.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  claim.patientName.isEmpty
                      ? 'Patient awaiting confirmation'
                      : claim.patientName,
                ),
                Text(
                  claim.providerName.isEmpty
                      ? 'Provider awaiting confirmation'
                      : claim.providerName,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.claimedAmount == null
                          ? 'Amount pending'
                          : '${claim.currency} ${claim.claimedAmount!.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: Text(
                        DateFormat('dd MMM yyyy')
                            .format(claim.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      )),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18)
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
