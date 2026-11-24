import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';

class DocumentPreviewScreen extends StatefulWidget {
  const DocumentPreviewScreen(
      {super.key,
      required this.reference,
      required this.documentId,
      required this.name});
  final String reference, documentId, name;
  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  Uint8List? bytes;
  String? text, error;
  bool busy = true;
  int page = 1, pages = 1;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await workspaceApi(context).get<List<int>>(
          widget.documentId == 'receipt'
              ? '/claims/${widget.reference}/receipt/preview'
              : '/claims/${widget.reference}/documents/${widget.documentId}/preview',
          queryParameters: {'page': page},
          options: Options(responseType: ResponseType.bytes));
      if (!mounted) return;
      setState(() {
        pages =
            int.tryParse(result.headers.value('X-Document-Pages') ?? '1') ?? 1;
        final data = Uint8List.fromList(result.data!);
        if ((result.headers.value('Content-Type') ?? '').startsWith('text/')) {
          text = utf8.decode(data);
          bytes = null;
        } else {
          bytes = data;
          text = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(children: [
        if (busy) const LinearProgressIndicator(),
        Expanded(
            child: error != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(error!),
                              TextButton(
                                  onPressed: load,
                                  child: const Text('Try again'))
                            ])))
                : text != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(text!))
                    : bytes != null
                        ? InteractiveViewer(
                            minScale: .5,
                            maxScale: 6,
                            child: Center(
                                child:
                                    Image.memory(bytes!, fit: BoxFit.contain)))
                        : const SizedBox.shrink()),
        if (pages > 1)
          SafeArea(
              top: false,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    tooltip: 'Previous page',
                    onPressed: busy || page <= 1
                        ? null
                        : () {
                            page--;
                            load();
                          },
                    icon: const Icon(Icons.chevron_left)),
                Text('Page $page of $pages'),
                IconButton(
                    tooltip: 'Next page',
                    onPressed: busy || page >= pages
                        ? null
                        : () {
                            page++;
                            load();
                          },
                    icon: const Icon(Icons.chevron_right))
              ]))
      ]));
}
