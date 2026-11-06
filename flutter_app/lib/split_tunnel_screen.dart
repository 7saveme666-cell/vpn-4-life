import 'package:flutter/material.dart';

const _splitBg = Color(0xFF1A1A1D);
const _splitCard = Color(0xFF2C2C2F);
const _splitYellow = Color(0xFFE9D100);

class SplitTunnelScreen extends StatefulWidget {
  const SplitTunnelScreen({super.key});

  @override
  State<SplitTunnelScreen> createState() => _SplitTunnelScreenState();
}

class _SplitTunnelScreenState extends State<SplitTunnelScreen> {
  bool _enabled = true;
  bool _domainsTab = true;
  String _routingMode = 'В обход туннеля';
  final List<String> _domains = ['Российские сайты'];
  final List<String> _apps = [];

  Future<void> _chooseRoutingMode() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _splitCard,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ['В обход туннеля', 'В туннель'])
              ListTile(
                title: Text(mode, style: const TextStyle(color: Colors.white)),
                trailing: mode == _routingMode
                    ? const Icon(Icons.check, color: _splitYellow)
                    : null,
                onTap: () => Navigator.pop(context, mode),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _routingMode = selected);
    }
  }

  Future<void> _addEntry() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _splitCard,
        title: Text(
          _domainsTab ? 'Добавить домен' : 'Добавить приложение',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: _domainsTab ? 'Например, example.com' : 'Название приложения',
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          onSubmitted: (text) => Navigator.pop(context, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _splitYellow),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Добавить', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value.isEmpty || !mounted) return;
    setState(() => (_domainsTab ? _domains : _apps).add(value));
  }

  @override
  Widget build(BuildContext context) {
    final listItems = _domainsTab ? _domains : _apps;

    return Scaffold(
      backgroundColor: _splitBg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  ),
                  const Expanded(
                    child: Text(
                      'Сплит-туннель',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Switch(
                      value: _enabled,
                      activeTrackColor: _splitYellow,
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.white24,
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Material(
                color: const Color(0xFF2E2E31),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _chooseRoutingMode,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Выбранное в списке',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _routingMode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _tabButton('Домены', true),
                _tabButton('Приложения', false),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final entry in listItems)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        title: Text(
                          entry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => setState(() => listItems.remove(entry)),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _splitYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _addEntry,
                  child: const Text(
                    'Добавить',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, bool domainsTab) {
    final selected = _domainsTab == domainsTab;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _domainsTab = domainsTab),
        child: Column(
          children: [
            SizedBox(
              height: 42,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              height: 3,
              width: 120,
              decoration: BoxDecoration(
                color: selected ? _splitYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
