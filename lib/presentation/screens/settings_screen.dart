import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import '../../core/settings/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _mode;
  late AppLanguage _lang;

  bool _isSaving = false;

  bool get _hasChanges =>
      _mode != AppSettings.I.themeMode || _lang != AppSettings.I.language;

  @override
  void initState() {
    super.initState();
    _mode = AppSettings.I.themeMode;
    _lang = AppSettings.I.language;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await AppSettings.I.setTheme(_mode);
      await AppSettings.I.setLanguage(_lang);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppSettings.I.t('save'))),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Phoenix.rebirth(context);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppSettings.I.t;

    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          Text(
            t('theme'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(t('light')),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(t('dark')),
                icon: const Icon(Icons.dark_mode),
              ),
              
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),

          const SizedBox(height: 24),

          Text(
            t('language'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppLanguage>(
            segments: const [
              ButtonSegment(
                value: AppLanguage.tr,
                label: Text('Türkçe'),
                icon: Icon(Icons.flag),
              ),
              ButtonSegment(
                value: AppLanguage.en,
                label: Text('English'),
                icon: Icon(Icons.flag_outlined),
              ),
            ],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),

          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _hasChanges && !_isSaving ? _save : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(t('save')),
          ),
        ],
      ),
    );
  }
}
