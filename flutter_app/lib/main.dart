import 'dart:async';
import 'dart:io' show Platform, exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'demo_auth_gate.dart';
import 'split_tunnel_screen.dart';

const _background = Color(0xFF05050A);
const _surface = Color(0xFF100D18);
const _text = Color(0xFFF2ECFA);
const _muted = Color(0xFF9A8EAD);
const _green = Color(0xFF39E875);
const _error = Color(0xFFFF5570);

const _palettes = <List<Color>>[
  [Color(0xFFE9E9F0), Color(0xFF414149)],
  [Color(0xFF418BFF), Color(0xFFFF76C8)],
  [Color(0xFF54D7FF), Color(0xFF8A55FF)],
];

String _tr(bool english, String ru, String en) => english ? en : ru;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setBackgroundColor(_background);
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setMinimumSize(const Size(440, 700));
    await windowManager.setSize(const Size(440, 820));
    await windowManager.setAlignment(Alignment.center);
  }

  runApp(const SpiderVpnApp());
}

class SpiderVpnApp extends StatelessWidget {
  const SpiderVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spider VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _palettes.first.first,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DemoAuthGate(
        appBuilder: (_) => const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _paletteKey = 'spider_vpn_palette';

  int _tab = 0;
  int _paletteIndex = 0;
  bool _english = false;

  Color get _accent => _palettes[_paletteIndex].first;
  Color get _secondary => _palettes[_paletteIndex].last;

  @override
  void initState() {
    super.initState();
    _loadPalette();
  }

  Future<void> _loadPalette() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_paletteKey) ?? 0;
      if (mounted && value >= 0 && value < _palettes.length) {
        setState(() => _paletteIndex = value);
      }
    } catch (_) {
      // The app can still run if local preferences are unavailable.
    }
  }

  Future<void> _selectPalette(int value) async {
    if (value < 0 || value >= _palettes.length) return;

    setState(() => _paletteIndex = value);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_paletteKey, value);
    } catch (_) {
      if (mounted) {
        _showMessage(
          _tr(_english, 'Не удалось сохранить цвет темы.', 'Could not save theme color.'),
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _closeApp() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: _accent, width: 1.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                _AppHeader(
                  english: _english,
                  accent: _accent,
                  onClose: _closeApp,
                  onToggleLanguage: () {
                    setState(() => _english = !_english);
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      HomeScreen(
                        english: _english,
                        accent: _accent,
                        secondary: _secondary,
                      ),
                      ProfileScreen(
                        english: _english,
                        accent: _accent,
                        selectedPalette: _paletteIndex,
                        onPaletteChanged: _selectPalette,
                      ),
                    ],
                  ),
                ),
                _BottomNav(
                  selected: _tab,
                  english: _english,
                  accent: _accent,
                  onSelect: (value) => setState(() => _tab = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.english,
    required this.accent,
    required this.onClose,
    required this.onToggleLanguage,
  });

  final bool english;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: _tr(english, 'Закрыть приложение', 'Close app'),
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: accent),
          ),
          const Spacer(),
          const Text('🕷️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Text(
            'Spider VPN',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onToggleLanguage,
            child: Text(
              english ? 'EN | RU' : 'RU | EN',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selected,
    required this.english,
    required this.accent,
    required this.onSelect,
  });

  final int selected;
  final bool english;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 64,
      selectedIndex: selected,
      onDestinationSelected: onSelect,
      backgroundColor: _surface,
      indicatorColor: accent.withOpacity(.18),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_rounded),
          label: _tr(english, 'Главная', 'Home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_rounded),
          label: _tr(english, 'Профиль', 'Profile'),
        ),
      ],
    );
  }
}

class _Server {
  const _Server({
    required this.countryRu,
    required this.countryEn,
    required this.cityRu,
    required this.cityEn,
    required this.flag,
  });

  final String countryRu;
  final String countryEn;
  final String cityRu;
  final String cityEn;
  final String flag;

  String title(bool english) =>
      '${english ? countryEn : countryRu} · ${english ? cityEn : cityRu}';
}

const _servers = <_Server>[
  _Server(
    countryRu: 'США',
    countryEn: 'United States',
    cityRu: 'Нью-Йорк',
    cityEn: 'New York',
    flag: '🇺🇸',
  ),
  _Server(
    countryRu: 'Германия',
    countryEn: 'Germany',
    cityRu: 'Берлин',
    cityEn: 'Berlin',
    flag: '🇩🇪',
  ),
  _Server(
    countryRu: 'Нидерланды',
    countryEn: 'Netherlands',
    cityRu: 'Амстердам',
    cityEn: 'Amsterdam',
    flag: '🇳🇱',
  ),
  _Server(
    countryRu: 'Швеция',
    countryEn: 'Sweden',
    cityRu: 'Стокгольм',
    cityEn: 'Stockholm',
    flag: '🇸🇪',
  ),
  _Server(
    countryRu: 'Япония',
    countryEn: 'Japan',
    cityRu: 'Токио',
    cityEn: 'Tokyo',
    flag: '🇯🇵',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.english,
    required this.accent,
    required this.secondary,
  });

  final bool english;
  final Color accent;
  final Color secondary;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Server _server = _servers.first;
  bool _connecting = false;
  bool _connected = false;
  Timer? _timer;
  Duration _uptime = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _chooseServer() async {
    final selected = await showModalBottomSheet<_Server>(
      context: context,
      backgroundColor: _surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _tr(widget.english, 'Выберите страну', 'Choose a country'),
                style: const TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final server in _servers)
              ListTile(
                leading: Text(server.flag, style: const TextStyle(fontSize: 26)),
                title: Text(server.title(widget.english)),
                trailing: server == _server
                    ? Icon(Icons.check_circle, color: widget.accent)
                    : null,
                onTap: () => Navigator.pop(context, server),
              ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    _timer?.cancel();
    setState(() {
      _server = selected;
      _connecting = false;
      _connected = false;
      _uptime = Duration.zero;
    });
  }

  void _toggleConnection() {
    if (_connecting) {
      _timer?.cancel();
      setState(() {
        _connecting = false;
        _connected = false;
      });
      return;
    }

    if (_connected) {
      _timer?.cancel();
      setState(() {
        _connected = false;
        _uptime = Duration.zero;
      });
      return;
    }

    setState(() => _connecting = true);

    // Demo-only connection animation; this does not establish a real VPN.
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_connecting) return;
      setState(() {
        _connecting = false;
        _connected = true;
        _uptime = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _connected) {
          setState(() => _uptime += const Duration(seconds: 1));
        }
      });
    });
  }

  String get _time {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(_uptime.inHours)}:'
        '${two(_uptime.inMinutes.remainder(60))}:'
        '${two(_uptime.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _connecting
        ? _tr(widget.english, 'Подключение…', 'Connecting…')
        : _connected
            ? _tr(widget.english, 'Подключено', 'Connected')
            : _tr(widget.english, 'Не подключено', 'Not connected');

    return Column(
      children: [
        const SizedBox(height: 18),
        Material(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _chooseServer,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: widget.accent),
                  const SizedBox(width: 10),
                  Text(_server.flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _server.title(widget.english),
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _muted),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _surface,
            border: Border.all(
              color: _connected ? _green : widget.accent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.secondary.withOpacity(.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _toggleConnection,
              customBorder: const CircleBorder(),
              child: Center(
                child: _connecting
                    ? CircularProgressIndicator(color: widget.accent)
                    : Icon(
                        Icons.power_settings_new_rounded,
                        color: _connected ? _green : _text,
                        size: 48,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          status,
          style: const TextStyle(
            color: _text,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _connected
              ? _time
              : _tr(
                  widget.english,
                  'Демо-интерфейс: VPN не подключается',
                  'Demo interface: no real VPN connection',
                ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _connected ? widget.accent : _muted,
            fontSize: _connected ? 24 : 13,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.english,
    required this.accent,
    required this.selectedPalette,
    required this.onPaletteChanged,
  });

  final bool english;
  final Color accent;
  final int selectedPalette;
  final ValueChanged<int> onPaletteChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _login = 'spider_user';
  String? _gmail;
  String? _phone;

  String t(String ru, String en) => _tr(widget.english, ru, en);

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> _editField({
    required String title,
    required String label,
    required String initialValue,
    required TextInputType keyboardType,
    required String? Function(String) validate,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text(title, style: const TextStyle(color: _text)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _text),
            decoration: InputDecoration(labelText: label),
            validator: (value) => validate((value ?? '').trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Отмена', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(t('Сохранить', 'Save')),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && mounted) {
      onSave(result);
    }
  }

  Future<void> _editLogin() => _editField(
        title: t('Изменить логин', 'Change username'),
        label: t('Новый логин', 'New username'),
        initialValue: _login,
        keyboardType: TextInputType.text,
        validate: (value) => value.length >= 3
            ? null
            : t('Минимум 3 символа', 'At least 3 characters'),
        onSave: (value) {
          setState(() => _login = value);
          _message(t('Логин обновлён в демо-профиле.', 'Demo username updated.'));
        },
      );

  Future<void> _editGmail() => _editField(
        title: t('Привязать Gmail', 'Link Gmail'),
        label: t('Адрес @gmail.com', 'Gmail address'),
        initialValue: _gmail ?? '',
        keyboardType: TextInputType.emailAddress,
        validate: (value) =>
            RegExp(r'^[A-Z0-9._%+-]+@gmail\.com$', caseSensitive: false)
                    .hasMatch(value)
                ? null
                : t(
                    'Введите корректный адрес @gmail.com',
                    'Enter a valid @gmail.com address',
                  ),
        onSave: (value) {
          setState(() => _gmail = value);
          _message(t('Gmail сохранён в демо-профиле.', 'Demo Gmail saved.'));
        },
      );

  Future<void> _editPhone() => _editField(
        title: t('Привязать номер телефона', 'Link phone number'),
        label: t('Номер телефона', 'Phone number'),
        initialValue: _phone ?? '',
        keyboardType: TextInputType.phone,
        validate: (value) =>
            RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value)
                ? null
                : t('Введите корректный номер', 'Enter a valid phone number'),
        onSave: (value) {
          setState(() => _phone = value);
          _message(t('Номер сохранён в демо-профиле.', 'Demo phone number saved.'));
        },
      );

  Future<void> _showPrivacy() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t('Конфиденциальность', 'Privacy'),
                  style: const TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('Логин: $_login', 'Username: $_login'),
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                _ProfileAction(
                  icon: Icons.person_rounded,
                  title: t('Изменить логин', 'Change username'),
                  accent: widget.accent,
                  onTap: _editLogin,
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.email_rounded,
                  title: _gmail ?? t('Привязать Gmail', 'Link Gmail'),
                  accent: widget.accent,
                  onTap: _editGmail,
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.phone_rounded,
                  title: _phone ?? t('Привязать номер телефона', 'Link phone number'),
                  accent: widget.accent,
                  onTap: _editPhone,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(t('Закрыть', 'Close')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      children: [
        Text(
          t('Профиль', 'Profile'),
          style: const TextStyle(
            color: _text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _ProfileAction(
          icon: Icons.privacy_tip_outlined,
          title: t('Конфиденциальность', 'Privacy'),
          subtitle: t(
            'Логин, Gmail и номер телефона',
            'Username, Gmail and phone number',
          ),
          accent: widget.accent,
          onTap: _showPrivacy,
        ),
        const SizedBox(height: 18),
        Text(
          t('Цвет темы', 'Theme color'),
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            for (var i = 0; i < _palettes.length; i++)
              GestureDetector(
                onTap: () => widget.onPaletteChanged(i),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _palettes[i]),
                    border: Border.all(
                      color: i == widget.selectedPalette
                          ? widget.accent
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _ProfileAction(
          icon: Icons.alt_route_rounded,
          title: t(
            'Настройки сплит-туннелирования',
            'Split tunneling settings',
          ),
          accent: widget.accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SplitTunnelScreen(accent: widget.accent),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.accent,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}
