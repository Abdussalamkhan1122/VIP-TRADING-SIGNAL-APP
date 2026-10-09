import 'package:flutter/material.dart';

void main() {
  runApp(const HurrairApp());
}

class HurrairApp extends StatelessWidget {
  const HurrairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hurrair VIP Trading',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20C997),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101418),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final pages = const [
    SignalsPage(title: 'Free Signals', audience: SignalAudience.free),
    SignalsPage(title: 'VIP Signals', audience: SignalAudience.vip),
    UnlockVipPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hurrair VIP Trading'),
        centerTitle: false,
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Free'),
          NavigationDestination(icon: Icon(Icons.workspace_premium), label: 'VIP'),
          NavigationDestination(icon: Icon(Icons.lock_open), label: 'Unlock'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

enum SignalAudience { free, vip }

class SignalsPage extends StatelessWidget {
  const SignalsPage({super.key, required this.title, required this.audience});

  final String title;
  final SignalAudience audience;

  @override
  Widget build(BuildContext context) {
    final isVip = audience == SignalAudience.vip;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        SignalCard(
          symbol: 'GOLD',
          direction: isVip ? 'VIP SELL' : 'SELL',
          entry: '4157-4160',
          stopLoss: '4170',
          takeProfits: const ['50 pips', '100 pips', '120 pips', '150 pips', '200 pips', '250 pips'],
          locked: isVip,
        ),
      ],
    );
  }
}

class SignalCard extends StatelessWidget {
  const SignalCard({
    super.key,
    required this.symbol,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.takeProfits,
    this.locked = false,
  });

  final String symbol;
  final String direction;
  final String entry;
  final String stopLoss;
  final List<String> takeProfits;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final accent = direction.contains('SELL') ? const Color(0xFFFF6B6B) : const Color(0xFF20C997);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('$symbol $direction', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: accent)),
                ),
                if (locked) const Icon(Icons.lock, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text('Entry: $entry'),
            Text('SL: $stopLoss'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: takeProfits.map((tp) => Chip(label: Text(tp))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class UnlockVipPage extends StatelessWidget {
  const UnlockVipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Unlock VIP', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text('Create your Exness account through the official partner link, then submit the same email for verification.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.open_in_new),
          label: const Text('Create Exness Account'),
        ),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Exness email')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {},
          child: const Text('Submit for Verification'),
        ),
      ],
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('My Account', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.verified_user),
          title: Text('Status'),
          subtitle: Text('Free user'),
        ),
        const ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Notifications'),
          subtitle: Text('Enabled after Firebase setup'),
        ),
      ],
    );
  }
}

