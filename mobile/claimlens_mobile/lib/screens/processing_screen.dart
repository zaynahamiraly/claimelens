import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/claims_provider.dart';
import '../services/api_client.dart';
import 'extracted_info_screen.dart';
import 'claim_details_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.reference});
  final String reference;
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String? error;
  bool running = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    setState(() {
      running = true;
      error = null;
    });
    try {
      final service = context.read<ClaimsProvider>().service;
      final current = await service.details(widget.reference);
      if (current.status != 'PROCESSING') {
        await service.process(widget.reference);
      }
      var details = await service.details(widget.reference);
      final deadline = DateTime.now().add(const Duration(minutes: 10));
      while (mounted &&
          details.status == 'PROCESSING' &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        details = await service.details(widget.reference);
      }
      if (details.status == 'PROCESSING') {
        throw Exception(
            'Processing is continuing. You can return to Claims and check its progress.');
      }
      if (details.status == 'PROCESSING_FAILED') {
        throw Exception(
            'Processing did not finish. Retry, or enter the document information manually.');
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => details.status == 'UPLOADED'
              ? ExtractedInfoScreen(reference: widget.reference)
              : ClaimDetailsScreen(reference: widget.reference),
        ),
      );
    } catch (exception) {
      if (mounted) setState(() => error = readableApiError(exception));
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.reference)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (running) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Reading your documents',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Text extraction and OCR are identifying patient, provider, dates, and payable totals. Large scanned PDFs can take longer.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Icon(
                    Icons.error_outline,
                    size: 52,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Processing needs attention',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error ?? 'Processing did not finish.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _process,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExtractedInfoScreen(reference: widget.reference),
                      ),
                    ),
                    child: const Text('Enter information manually'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
