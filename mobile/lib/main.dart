import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://hurrair-vip-trading-backend.onrender.com',
);

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
        cardTheme: const CardThemeData(
          color: Color(0xFF151B20),
          margin: EdgeInsets.only(bottom: 12),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
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

enum SignalAudience {
  free('free'),
  vip('vip');

  const SignalAudience(this.apiValue);
  final String apiValue;
}

class ApiClient {
  const ApiClient();

  Future<List<TradingSignal>> getSignals(SignalAudience audience) async {
    final uri = Uri.parse('$backendBaseUrl/api/signals?audience=${audience.apiValue}');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Signals request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final signals = body['signals'] as List<dynamic>;
    return signals
        .map((item) => TradingSignal.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> requestVip({required String email, String displayName = ''}) async {
    final uri = Uri.parse('$backendBaseUrl/api/vip/request');
    final response = await http.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': email, 'displayName': displayName}),
    );

    if (response.statusCode != 201) {
      throw Exception('VIP request failed: ${response.statusCode}');
    }
  }
}

class TradingSignal {
  const TradingSignal({
    required this.id,
    required this.audience,
    required this.symbol,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.takeProfits,
    required this.status,
  });

  final String id;
  final String audience;
  final String symbol;
  final String direction;
  final String? entry;
  final String? stopLoss;
  final List<String> takeProfits;
  final String status;

  factory TradingSignal.fromJson(Map<String, dynamic> json) {
    final tps = (json['takeProfits'] as List<dynamic>? ?? [])
        .map((item) {
          final tp = item as Map<String, dynamic>;
          final value = tp['value']?.toString() ?? '';
          final unit = tp['unit']?.toString() ?? '';
          return unit.isEmpty ? value : '$value $unit';
        })
        .where((value) => value.trim().isNotEmpty)
        .toList();

    return TradingSignal(
      id: json['id']?.toString() ?? '',
      audience: json['audience']?.toString() ?? 'free',
      symbol: json['symbol']?.toString() ?? 'UNKNOWN',
      direction: json['direction']?.toString() ?? '',
      entry: json['entry']?.toString(),
      stopLoss: json['stopLoss']?.toString(),
      takeProfits: tps,
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class SignalsPage extends StatefulWidget {
  const SignalsPage({super.key, required this.title, required this.audience});

  final String title;
  final SignalAudience audience;

  @override
  State<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends State<SignalsPage> {
  final api = const ApiClient();
  late Future<List<TradingSignal>> futureSignals;

  @override
  void initState() {
    super.initState();
    futureSignals = api.getSignals(widget.audience);
  }

  void refresh() {
    setState(() {
      futureSignals = api.getSignals(widget.audience);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: FutureBuilder<List<TradingSignal>>(
        future: futureSignals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString(), onRetry: refresh);
          }

          final signals = snapshot.data ?? [];
          if (signals.isEmpty) {
            return EmptyState(title: widget.title, onRefresh: refresh);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(title: widget.title, onRefresh: refresh),
              const SizedBox(height: 12),
              ...signals.map((signal) => SignalCard(signal: signal)),
            ],
          );
        },
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.onRefresh});

  final String title;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class SignalCard extends StatelessWidget {
  const SignalCard({super.key, required this.signal});

  final TradingSignal signal;

  @override
  Widget build(BuildContext context) {
    final accent = signal.direction == 'SELL' ? const Color(0xFFFF6B6B) : const Color(0xFF20C997);
    final isVip = signal.audience == 'vip';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${signal.symbol} ${signal.direction}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: accent),
                  ),
                ),
                Chip(
                  avatar: Icon(isVip ? Icons.workspace_premium : Icons.lock_open, size: 16),
                  label: Text(isVip ? 'VIP' : 'Free'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.login, label: 'Entry', value: signal.entry ?? '-'),
            InfoRow(icon: Icons.shield, label: 'SL', value: signal.stopLoss ?? '-'),
            InfoRow(icon: Icons.schedule, label: 'Status', value: signal.status),
            const SizedBox(height: 12),
            if (signal.takeProfits.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: signal.takeProfits
                    .asMap()
                    .entries
                    .map((entry) => Chip(label: Text('TP${entry.key + 1}: ${entry.value}')))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class UnlockVipPage extends StatefulWidget {
  const UnlockVipPage({super.key});

  @override
  State<UnlockVipPage> createState() => _UnlockVipPageState();
}

class _UnlockVipPageState extends State<UnlockVipPage> {
  final api = const ApiClient();
  final emailController = TextEditingController();
  bool loading = false;
  String? message;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => message = 'Enter the email used for your Exness account.');
      return;
    }

    setState(() {
      loading = true;
      message = null;
    });

    try {
      await api.requestVip(email: email);
      setState(() {
        message = 'Request submitted. Admin will verify your Exness affiliation.';
        emailController.clear();
      });
    } catch (_) {
      setState(() => message = 'Could not submit request. Please try again.');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Unlock VIP', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Create your Exness account through the official partner link.'),
                SizedBox(height: 8),
                SelectableText('https://one.exnessonelink.com/a/i2cmzyptz3'),
                SizedBox(height: 8),
                Text('2. Submit the same email here for manual VIP verification.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Exness email'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading ? null : submit,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Submit for Verification'),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!),
        ],
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
          subtitle: Text('Free user - login and VIP status sync coming next'),
        ),
        const ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Notifications'),
          subtitle: Text('Firebase push notifications coming next'),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('Backend'),
          subtitle: Text(backendBaseUrl),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.onRefresh});

  final String title;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(title: title, onRefresh: onRefresh),
        const SizedBox(height: 80),
        const Icon(Icons.show_chart, size: 48),
        const SizedBox(height: 12),
        const Center(child: Text('No signals yet')),
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
