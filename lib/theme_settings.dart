import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettingsPage extends StatefulWidget {
  final Function(bool, MaterialColor) onThemeChanged;
  const ThemeSettingsPage({super.key, required this.onThemeChanged});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  bool _isDark = false;
  MaterialColor _seed = Colors.indigo;

  final _colors = {
    'Indigo': Colors.indigo,
    'Green' : Colors.green,
    'Teal'  : Colors.teal,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    _seed   = _colors[prefs.getString('themeColor') ?? 'Indigo'] ?? Colors.indigo;
    setState(() {});
  }

  /* 22(theme_settings.dart → SharedPreferences) for saving theme settings */
  Future<void> _updateTheme({bool? dark, MaterialColor? color}) async {
    final prefs = await SharedPreferences.getInstance();
    if (dark != null) {
      _isDark = dark;
      await prefs.setBool('isDark', _isDark);
    }
    if (color != null) {
      _seed = color;
      final name = _colors.entries.firstWhere((e) => e.value == _seed).key;
      await prefs.setString('themeColor', name);
    }
    
    // Inside theme_settings.dart
    widget.onThemeChanged(_isDark, _seed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme & Dark Mode')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /* 20(theme_settings.dart → SwitchListTile) for dark‑mode toggle */
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _isDark,
              onChanged: (v) => _updateTheme(dark: v),
            ),
            const SizedBox(height: 20),
            const Text('Seed Color', style: TextStyle(fontWeight: FontWeight.bold)),
            /* 21(theme_settings.dart → ChoiceChip) for selecting seed color */
            Wrap(
              spacing: 10,
              children: _colors.entries.map((e) {
                final selected = e.value == _seed;
                return ChoiceChip(
                  label: Text(e.key),
                  selected: selected,
                  onSelected: (_) => _updateTheme(color: e.value),
                  selectedColor: e.value,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
