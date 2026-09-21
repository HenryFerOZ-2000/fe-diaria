import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import 'source_link.dart';

class ContentSourceCard extends StatelessWidget {
  final ContentProvenance provenance;
  const ContentSourceCard({super.key, required this.provenance});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ExpansionTile(
      leading: const Icon(Icons.library_books_outlined),
      title: Text(provenance.kind),
      subtitle: const Text('Acerca de este texto'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(provenance.description),
        const SizedBox(height: 10),
        Text(
          provenance.reviewStatus,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          provenance.licenseStatus,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (provenance.translation != null) ...[
          const SizedBox(height: 8),
          Text(provenance.translation!),
        ],
        if (provenance.sourceUrl != null)
          TextButton.icon(
            onPressed: () => openSource(context, provenance.sourceUrl!),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(provenance.sourceTitle ?? 'Consultar fuente'),
          ),
      ],
    ),
  );
}
