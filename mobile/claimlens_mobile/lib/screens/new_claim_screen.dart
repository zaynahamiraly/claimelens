import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/selected_document.dart';
import '../providers/claims_provider.dart';
import '../services/api_client.dart';
import 'processing_screen.dart';
import 'claim_details_screen.dart';
import 'help_screen.dart';
import '../services/workspace_service.dart';

class NewClaimScreen extends StatefulWidget {
  const NewClaimScreen({super.key});
  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  final documents = <SelectedDocument>[];
  final picker = ImagePicker();
  bool busy = false;
  String? error;
  final member = TextEditingController(),
      policy = TextEditingController(),
      description = TextEditingController();
  DateTime? treatmentDate;
  double? progress;
  String? draftReference;
  final requestKey =
      List.generate(32, (_) => Random.secure().nextInt(16).toRadixString(16))
          .join();
  @override
  void dispose() {
    member.dispose();
    policy.dispose();
    description.dispose();
    super.dispose();
  }

  String _mime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result == null) return;
    setState(() {
      for (final file in result.files) {
        if (file.bytes != null) {
          documents.add(
            SelectedDocument(
              name: file.name,
              mimeType: _mime(file.name),
              bytes: file.bytes!,
            ),
          );
        }
      }
    });
  }

  Future<void> _pickImages(ImageSource source) async {
    final List<XFile> images;
    if (source == ImageSource.gallery) {
      images = await picker.pickMultiImage(
          imageQuality: 90, maxWidth: 2500, maxHeight: 2500);
    } else {
      final image = await picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 2500, maxHeight: 2500);
      images = image == null ? [] : [image];
    }
    final selected = <SelectedDocument>[];
    for (final image in images) {
      selected.add(
        SelectedDocument(
          name: image.name,
          mimeType: _mime(image.name),
          bytes: await image.readAsBytes(),
        ),
      );
    }
    setState(() => documents.addAll(selected));
  }

  Future<void> _submit({bool extract = true}) async {
    if (documents.isEmpty) {
      setState(() => error = 'Add at least one claim document.');
      return;
    }
    if (documents.length > 10) {
      setState(() => error = 'A claim can contain up to 10 documents.');
      return;
    }
    final oversized = documents
        .where((document) => document.bytes.length > 10 * 1024 * 1024)
        .toList();
    if (oversized.isNotEmpty) {
      setState(() => error = '${oversized.first.name} is larger than 10 MB.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final service = context.read<ClaimsProvider>().service;
      final api = workspaceApi(context);
      if (draftReference == null) {
        final claim = await service.create(documents, requestKey: requestKey,
            onSendProgress: (sent, total) {
          if (mounted) {
            setState(() => progress = total > 0 ? sent / total : null);
          }
        });
        draftReference = claim.reference;
      }
      await api.put<dynamic>('/claims/$draftReference/information', data: {
        'member_number': member.text.trim(),
        'policy_number': policy.text.trim(),
        'description': description.text.trim(),
        'treatment_date': treatmentDate?.toIso8601String().substring(0, 10)
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => extract
              ? ProcessingScreen(reference: draftReference!)
              : ClaimDetailsScreen(reference: draftReference!),
        ),
      );
    } catch (exception) {
      if (mounted) setState(() => error = readableApiError(exception));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New claim')),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
          children: [
            Text(
              'Upload every document for this claim',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add invoices, receipts, pharmacy documents, medical certificates, memos, claim forms, or other supporting evidence. OCR will propose values; you will confirm them before submission.',
            ),
            const SizedBox(height: 20),
            TextField(
                controller: member,
                decoration: const InputDecoration(
                    labelText: 'Member number (if applicable)')),
            const SizedBox(height: 14),
            TextField(
                controller: policy,
                decoration: const InputDecoration(
                    labelText: 'Policy number (if applicable)')),
            const SizedBox(height: 14),
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Treatment date'),
                subtitle: Text(treatmentDate == null
                    ? 'Choose a date'
                    : treatmentDate!.toIso8601String().substring(0, 10)),
                trailing: const Icon(Icons.chevron_right),
                onTap: busy
                    ? null
                    : () async {
                        final chosen = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDate: treatmentDate ?? DateTime.now());
                        if (chosen != null && mounted) {
                          setState(() => treatmentDate = chosen);
                        }
                      }),
            const SizedBox(height: 14),
            TextField(
                controller: description,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                    labelText: 'What is this claim for?',
                    alignLabelWithHint: true)),
            TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpScreen())),
                icon: const Icon(Icons.checklist),
                label: const Text('View document requirements')),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                  onPressed:
                      busy ? null : () => _pickImages(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera')),
              OutlinedButton.icon(
                  onPressed:
                      busy ? null : () => _pickImages(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery')),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('PDF, Word, or image files'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${documents.length} document${documents.length == 1 ? '' : 's'} selected',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (documents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No documents selected yet.'),
                ),
              ),
            ...documents.asMap().entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(
                        entry.value.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${(entry.value.bytes.length / 1024).toStringAsFixed(0)} KB',
                      ),
                      trailing: IconButton(
                        onPressed: busy
                            ? null
                            : () =>
                                setState(() => documents.removeAt(entry.key)),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : () => _submit(),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Upload and extract'),
              ),
            ),
            if (busy)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(progress == null
                        ? 'Preparing upload…'
                        : progress! < 1
                            ? 'Uploading ${(progress! * 100).round()}%'
                            : 'Saving your draft…')
                  ])),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: busy ? null : () => _submit(extract: false),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save draft for later')),
          ],
        ),
      );
}
