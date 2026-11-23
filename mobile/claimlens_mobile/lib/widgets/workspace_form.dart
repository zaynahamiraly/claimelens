import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';

class FormEntry {
  const FormEntry(this.keyName, this.label,
      {this.value = '',
      this.options,
      this.required = true,
      this.secret = false,
      this.lines = 1,
      this.numeric = false});
  final String keyName, label, value;
  final Map<String, String>? options;
  final bool required, secret, numeric;
  final int lines;
}

Future<bool?> workspaceForm(BuildContext context,
        {required String title,
        required List<FormEntry> fields,
        required Future<void> Function(Map<String, String>) submit,
        String button = 'Save changes',
        String? explanation}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WorkspaceForm(
          title: title,
          fields: fields,
          submit: submit,
          button: button,
          explanation: explanation),
    );

class _WorkspaceForm extends StatefulWidget {
  const _WorkspaceForm(
      {required this.title,
      required this.fields,
      required this.submit,
      required this.button,
      this.explanation});
  final String title, button;
  final String? explanation;
  final List<FormEntry> fields;
  final Future<void> Function(Map<String, String>) submit;
  @override
  State<_WorkspaceForm> createState() => _WorkspaceFormState();
}

class _WorkspaceFormState extends State<_WorkspaceForm> {
  final key = GlobalKey<FormState>();
  late final values = {
    for (final field in widget.fields) field.keyName: field.value
  };
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: SingleChildScrollView(
            child: Form(
                key: key,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.title,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (widget.explanation != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(widget.explanation!)),
                      const SizedBox(height: 20),
                      for (final field in widget.fields)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: field.options != null
                                ? DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue:
                                        field.options!.containsKey(field.value)
                                            ? field.value
                                            : null,
                                    decoration:
                                        InputDecoration(labelText: field.label),
                                    items: field.options!.entries
                                        .map((entry) => DropdownMenuItem(
                                            value: entry.key,
                                            child: Text(entry.value,
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: busy
                                        ? null
                                        : (v) =>
                                            values[field.keyName] = v ?? '',
                                    validator: (v) =>
                                        field.required && (v == null || v.isEmpty)
                                            ? 'Choose ${field.label.toLowerCase()}'
                                            : null)
                                : TextFormField(
                                    initialValue: field.value,
                                    enabled: !busy,
                                    obscureText: field.secret,
                                    maxLines: field.secret ? 1 : field.lines,
                                    keyboardType: field.numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
                                    decoration: InputDecoration(labelText: field.label),
                                    onChanged: (v) => values[field.keyName] = v,
                                    validator: (v) => field.required && (v == null || v.trim().isEmpty) ? 'Enter ${field.label.toLowerCase()}' : null)),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  if (!key.currentState!.validate()) return;
                                  setState(() {
                                    busy = true;
                                    error = null;
                                  });
                                  try {
                                    await widget.submit(values);
                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  } catch (exception) {
                                    if (mounted) {
                                      setState(() {
                                        busy = false;
                                        error = readableApiError(exception);
                                      });
                                    }
                                  }
                                },
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.button)),
                      TextButton(
                          onPressed: busy ? null : () => Navigator.pop(context),
                          child: const Text('Cancel')),
                    ]))),
      );
}

Map<String, String> labelOptions(Iterable<String> values) =>
    {for (final value in values) value: friendlyLabel(value)};
