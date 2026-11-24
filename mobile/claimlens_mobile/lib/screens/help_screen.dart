import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/workspace_service.dart';
import '../widgets/workspace_form.dart';
import 'workspace_screens.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkspaceData(
      title: 'Help & requirements',
      path: '/settings',
      render: (context, raw, reload) {
        final data = Map<String, dynamic>.from(raw as Map);
        return [
          Text('Before you submit',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
              'Add clear, complete documents. Check the patient, provider and payable amounts against the source before submitting. OCR can make mistakes.'),
          const SizedBox(height: 20),
          ...List<String>.from(data['required_documents'] as List).map(
              (label) => Card(
                  child: ListTile(
                      leading: const Icon(Icons.checklist),
                      title: Text(label)))),
          const SizedBox(height: 16),
          const Text(
              'Supported files: PDF, Word (.docx), JPEG and PNG. Up to 10 documents, each under 10 MB. Avoid duplicate receipts and password-protected PDFs.'),
          const SizedBox(height: 20),
          if (data['require_member_number'] == true)
            const Text('Your member number is required.'),
          if (data['require_policy_number'] == true)
            const Text('Your policy number is required.'),
          Text(
              'Accepted currencies: ${(data['allowed_currencies'] as List).join(', ')}'),
          const SizedBox(height: 24),
          Text('Your information',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(data['privacy_notice'] as String),
          if ((data['support_email'] ?? '') != '')
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SelectableText('Support: ${data['support_email']}')),
          if (context.read<AuthProvider>().user!.isAdmin)
            Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton.icon(
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Configure requirements'),
                    onPressed: () async {
                      final saved = await workspaceForm(context,
                          title: 'Claim requirements',
                          explanation:
                              'These are submission requirements. Coverage and approval decisions still require an authorized reviewer.',
                          fields: [
                            FormEntry('required_documents',
                                'Document checklist (one per line)',
                                value: (data['required_documents'] as List)
                                    .join('\n'),
                                lines: 5),
                            FormEntry('allowed_currencies',
                                'Accepted currencies (comma separated)',
                                value: (data['allowed_currencies'] as List)
                                    .join(', ')),
                            FormEntry('require_member_number', 'Member number',
                                value: '${data['require_member_number']}',
                                options: const {
                                  'true': 'Required',
                                  'false': 'Optional'
                                }),
                            FormEntry('require_policy_number', 'Policy number',
                                value: '${data['require_policy_number']}',
                                options: const {
                                  'true': 'Required',
                                  'false': 'Optional'
                                }),
                            FormEntry(
                                'maximum_appeals', 'Maximum appeals per claim',
                                value: '${data['maximum_appeals']}',
                                options: const {
                                  '0': 'No appeals',
                                  '1': 'One appeal',
                                  '2': 'Two appeals',
                                  '3': 'Three appeals'
                                }),
                            FormEntry('support_email', 'Support email',
                                value: data['support_email'] as String,
                                required: false),
                            FormEntry('privacy_notice', 'Privacy notice',
                                value: data['privacy_notice'] as String,
                                lines: 6)
                          ], submit: (values) async {
                        await workspaceApi(context)
                            .put<dynamic>('/settings', data: {
                          ...values,
                          'required_documents': values['required_documents']!
                              .split('\n')
                              .map((v) => v.trim())
                              .where((v) => v.isNotEmpty)
                              .toList(),
                          'allowed_currencies': values['allowed_currencies']!
                              .split(',')
                              .map((v) => v.trim())
                              .toList(),
                          'require_member_number':
                              values['require_member_number'] == 'true',
                          'require_policy_number':
                              values['require_policy_number'] == 'true',
                          'maximum_appeals':
                              int.parse(values['maximum_appeals']!)
                        });
                      });
                      if (saved == true) await reload();
                    })),
        ];
      });
}
