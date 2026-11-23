import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';

class InformationResponseScreen extends StatefulWidget {
  const InformationResponseScreen(
      {super.key, required this.reference, required this.request});
  final String reference;
  final Map<String, dynamic> request;
  @override
  State<InformationResponseScreen> createState() =>
      _InformationResponseScreenState();
}

class _InformationResponseScreenState extends State<InformationResponseScreen> {
  final response = TextEditingController();
  final List<PlatformFile> files = [];
  bool busy = false;
  String? error;
  @override
  void dispose() {
    response.dispose();
    super.dispose();
  }

  Future<void> attach() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
          withData: true);
      if (result != null && mounted) {
        setState(() {
          files.addAll(result.files);
        });
      }
    } catch (exception) {
      if (mounted) setState(() => error = readableApiError(exception));
    }
  }

  Future<void> submit() async {
    final api = workspaceApi(context);
    if (response.text.trim().isEmpty && files.isEmpty) {
      setState(
          () => error = 'Enter your response or attach supporting documents.');
      return;
    }
    if (files.length > 10 || files.any((f) => f.size > 10 * 1024 * 1024)) {
      setState(() => error = 'Attach up to 10 documents, each under 10 MB.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final multipart = FormData.fromMap(
          {'response_text': response.text, 'background': true});
      for (final file in files) {
        final mime = switch (file.extension?.toLowerCase()) {
          'pdf' => 'application/pdf',
          'docx' =>
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'png' => 'image/png',
          _ => 'image/jpeg'
        };
        final part = file.bytes != null
            ? MultipartFile.fromBytes(file.bytes!,
                filename: file.name, contentType: DioMediaType.parse(mime))
            : await MultipartFile.fromFile(file.path!,
                filename: file.name, contentType: DioMediaType.parse(mime));
        multipart.files.add(MapEntry('files', part));
      }
      await api.post<dynamic>(
          '/claims/${widget.reference}/information/${widget.request['id']}/respond',
          data: multipart,
          options: Options(receiveTimeout: const Duration(minutes: 5)));
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
      appBar: AppBar(title: const Text('Provide information')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.request['reason'] as String,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(widget.request['questions'] as String),
        if ((widget.request['required_documents'] ?? '') != '')
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  'Requested documents: ${widget.request['required_documents']}')),
        const SizedBox(height: 20),
        TextField(
            controller: response,
            enabled: !busy,
            maxLines: 6,
            maxLength: 4000,
            decoration: const InputDecoration(
                labelText: 'Your response', alignLabelWithHint: true)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
            onPressed: busy ? null : attach,
            icon: const Icon(Icons.attach_file),
            label: const Text('Attach supporting documents')),
        for (final file in files)
          ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(file.name),
              subtitle: Text('${(file.size / 1024).round()} KB'),
              trailing: IconButton(
                  tooltip: 'Remove attachment',
                  onPressed:
                      busy ? null : () => setState(() => files.remove(file)),
                  icon: const Icon(Icons.close))),
        if (error != null)
          Text(error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: busy ? null : submit,
            icon: const Icon(Icons.send_outlined),
            label: Text(busy ? 'Submitting & processing…' : 'Submit response')),
      ]));
}
