import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moneyflow1/appearance.dart';
import 'package:moneyflow1/home.dart' show MainPage;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

Future<SharedPreferences?> _openPreferences() async {
  try {
    return await SharedPreferences.getInstance();
  } catch (_) {
    return null;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.preferences});

  final SharedPreferences? preferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.system;
  SharedPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences;
    if (_preferences case final preferences?) {
      _mode = _readMode(preferences);
    } else {
      _loadPreferences();
    }
  }

  ThemeMode _readMode(SharedPreferences preferences) {
    final saved = preferences.getString(appearancePreferenceKey);
    return ThemeMode.values.where((mode) => mode.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> _loadPreferences() async {
    final preferences = await _openPreferences();
    if (!mounted || preferences == null) return;
    setState(() {
      _preferences = preferences;
      _mode = _readMode(preferences);
    });
  }

  Future<bool> _setMode(ThemeMode mode) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      appearancePreferenceKey,
      mode.name,
    );
    if (mounted && saved) setState(() => _mode = mode);
    return saved;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Money Flow Pro',
    debugShowCheckedModeBanner: false,
    theme: moneyFlowTheme(Brightness.light),
    darkTheme: moneyFlowTheme(Brightness.dark),
    themeMode: _mode,
    builder:
        (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              Theme.of(context).brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
          child: child!,
        ),
    home: MainPage(themeMode: _mode, onThemeModeChanged: _setMode),
  );
}
