import 'package:flutter/material.dart';
import 'document_preview_screen.dart';
import '../models/claim.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';

class StaffReviewScreen extends StatefulWidget {
  const StaffReviewScreen({super.key, required this.claim});
  final ClaimDetails claim;
  @override
  State<StaffReviewScreen> createState() => _StaffReviewScreenState();
}

class _StaffReviewScreenState extends State<StaffReviewScreen> {
  final key = GlobalKey<FormState>();
  late final patient = TextEditingController(text: widget.claim.patientName);
  late final provider = TextEditingController(text: widget.claim.providerName);
  late final amounts = {
    for (final d in widget.claim.documents)
      d.id: TextEditingController(
          text: (d.confirmedAmount ?? d.extractedAmount)?.toStringAsFixed(2) ??
              '')
  };
  late final currencies = {
    for (final d in widget.claim.documents)
      d.id: TextEditingController(
          text: d.confirmedCurrency ??
              d.extractedCurrency ??
              widget.claim.currency)
  };
  late final included = {
    for (final d in widget.claim.documents)
      d.id: d.includeInTotal && d.duplicateOf == null
  };
  late final fields = {
    for (final d in widget.claim.documents)
      for (final f in d.fields)
        f.id: TextEditingController(text: f.normalizedValue)
  };
  bool busy = false;
  String? error;
  @override
  void dispose() {
    patient.dispose();
    provider.dispose();
    for (final c in [
      ...amounts.values,
      ...currencies.values,
      ...fields.values
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await workspaceApi(context).post<dynamic>(
          '/claims/${widget.claim.reference}/actions/correct',
          data: {
            'patient_name': patient.text,
            'provider_name': provider.text,
            'documents': [
              for (final d in widget.claim.documents)
                {
                  'id': d.id,
                  'include': included[d.id],
                  'amount': included[d.id] == true ? amounts[d.id]!.text : null,
                  'currency': currencies[d.id]!.text.toUpperCase()
                }
            ],
            'fields': [
              for (final d in widget.claim.documents)
                for (final f in d.fields)
                  if (fields[f.id]!.text != f.normalizedValue)
                    {'id': f.id, 'value': fields[f.id]!.text}
            ]
          });
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) {
        setState(() {
          busy = false;
          error = readableApiError(exception);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Review & correct')),
      body: Form(
          key: key,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text(
                'Compare every value with the source document. Corrections are recorded in the audit trail.'),
            const SizedBox(height: 20),
            TextFormField(
                controller: patient,
                decoration: const InputDecoration(labelText: 'Patient name'),
                validator: name),
            const SizedBox(height: 16),
            TextFormField(
                controller: provider,
                decoration: const InputDecoration(labelText: 'Provider name'),
                validator: name),
            const SizedBox(height: 24),
            for (final d in widget.claim.documents)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(d.originalName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(
                                    'OCR amount: ${d.extractedCurrency ?? widget.claim.currency} ${d.extractedAmount?.toStringAsFixed(2) ?? "Not found"}'),
                                Text(
                                    'Client proposal: ${d.clientProposedCurrency ?? d.confirmedCurrency ?? widget.claim.currency} ${(d.clientProposedAmount ?? d.confirmedAmount)?.toStringAsFixed(2) ?? "Not supplied"}'),
                                if (d.clientReportedIncorrectAmount)
                                  const Text(
                                      'Client reported an incorrect OCR amount. Compare the proposal with the source document.'),
                                Text(
                                    '${friendlyLabel(d.documentType)} • ${friendlyLabel(d.extractionStatus)}'),
                                if (d.signedUrl != null)
                                  TextButton.icon(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  DocumentPreviewScreen(
                                                      reference: widget
                                                          .claim.reference,
                                                      documentId: d.id,
                                                      name: d.originalName))),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text(
                                          'Compare source document')),
                                if (d.duplicateOf != null)
                                  const Text(
                                      'Duplicate evidence is excluded from the total.'),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Include in claim total'),
                                    value: included[d.id]!,
                                    onChanged: busy || d.duplicateOf != null
                                        ? null
                                        : (v) =>
                                            setState(() => included[d.id] = v)),
                                TextFormField(
                                    controller: amounts[d.id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'Confirmed amount'),
                                    validator: (v) => included[d.id] == true &&
                                            (double.tryParse(v ?? '') == null ||
                                                double.parse(v!) <= 0)
                                        ? 'Enter a positive amount'
                                        : null),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: currencies[d.id],
                                    decoration: const InputDecoration(
                                        labelText: 'Currency (three letters)'),
                                    validator: (v) => included[d.id] == true &&
                                            !RegExp(r'^[A-Za-z]{3}$')
                                                .hasMatch(v ?? '')
                                        ? 'Enter a three-letter currency'
                                        : null),
                                if (d.fields.isNotEmpty)
                                  ExpansionTile(
                                      title: const Text('Extracted fields'),
                                      tilePadding: EdgeInsets.zero,
                                      children: [
                                        for (final f in d.fields)
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: TextFormField(
                                                  controller: fields[f.id],
                                                  decoration: InputDecoration(
                                                      labelText: friendlyLabel(
                                                          f.fieldName),
                                                      helperText:
                                                          '${(f.confidence * 100).round()}% extraction confidence'),
                                                  validator: (v) => v == null ||
                                                          v.trim().isEmpty
                                                      ? 'Enter a value'
                                                      : null))
                                      ]),
                              ])))),
            if (error != null)
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: busy ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(busy ? 'Saving…' : 'Save reviewed information')),
          ])));
  String? name(String? value) => value == null || value.trim().length < 2
      ? 'Enter at least 2 characters'
      : null;
}
