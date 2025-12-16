import 'package:flutter/material.dart';
import '../models/helloao_models.dart';
import '../services/helloao_bible_api.dart';

class HelloAoTranslationSettingsScreen extends StatefulWidget {
  const HelloAoTranslationSettingsScreen({super.key});

  @override
  State<HelloAoTranslationSettingsScreen> createState() =>
      _HelloAoTranslationSettingsScreenState();
}

class _HelloAoTranslationSettingsScreenState
    extends State<HelloAoTranslationSettingsScreen> {
  final _api = HelloAoBibleApi();
  bool _loading = true;
  String? _error;
  List<HelloAoTranslation> _options = [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _api.fetchAvailableTranslations();
      final spa = all.where((t) {
        final lang = t.language?.toLowerCase() ?? '';
        final langName = t.languageName?.toLowerCase() ?? '';
        final langEn = t.languageEnglishName?.toLowerCase() ?? '';
        return lang == 'spa' ||
            langName.contains('españ') ||
            langEn.contains('spanish');
      }).toList();
      final saved = await _api.getOrSelectTranslation();
      if (!mounted) return;
      setState(() {
        _options = spa;
        _selectedId = saved;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onSelect(String id) async {
    setState(() => _selectedId = id);
    await _api.setSelectedTranslation(id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traducción de Biblia')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No se pudo cargar la lista',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final t = _options[index];
                    final subtitle = [
                      t.englishName,
                      t.languageName,
                    ].where((e) => e != null && e.isNotEmpty).join(' • ');
                    return RadioListTile<String>(
                      value: t.id,
                      groupValue: _selectedId,
                      title: Text(t.name),
                      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                      onChanged: (val) {
                        if (val != null) _onSelect(val);
                      },
                    );
                  },
                ),
    );
  }
}

