import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<AppSettings> getSettings() async {
    final uri = Uri.parse('$backendBaseUrl/api/settings');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Settings request failed: ${response.statusCode}');
    }

    return AppSettings.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<TradingSignal>> getSignals(SignalAudience audience, {String? vipEmail}) async {
    final query = {
      'audience': audience.apiValue,
      if (audience == SignalAudience.vip && vipEmail != null) 'email': vipEmail,
    };
    final uri = Uri.parse('$backendBaseUrl/api/signals').replace(queryParameters: query);
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

  Future<String> getVipStatus(String email) async {
    final uri = Uri.parse('$backendBaseUrl/api/vip/status?email=${Uri.encodeQueryComponent(email)}');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('VIP status request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['status']?.toString() ?? 'not_submitted';
  }
}

class AppSettings {
  const AppSettings({required this.exnessPartnerLink});

  final String exnessPartnerLink;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      exnessPartnerLink: json['exnessPartnerLink']?.toString() ?? 'https://one.exnessonelink.com/a/i2cmzyptz3',
    );
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
    required this.createdAt,
  });

  final String id;
  final String audience;
  final String symbol;
  final String direction;
  final String? entry;
  final String? stopLoss;
  final List<String> takeProfits;
  final String status;
  final DateTime? createdAt;

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
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }

  bool get isNew {
    final timestamp = createdAt;
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp).inMinutes < 60;
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
    futureSignals = widget.audience == SignalAudience.free
        ? api.getSignals(widget.audience)
        : Future.value([]);
  }

  void refresh() {
    setState(() {
      futureSignals = api.getSignals(widget.audience);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audience == SignalAudience.vip) {
      return VipSignalsPage(title: widget.title);
    }

    return SignalsList(
      title: widget.title,
      futureSignals: futureSignals,
      onRefresh: refresh,
    );
  }
}

class VipSignalsPage extends StatefulWidget {
  const VipSignalsPage({super.key, required this.title});

  final String title;

  @override
  State<VipSignalsPage> createState() => _VipSignalsPageState();
}

class _VipSignalsPageState extends State<VipSignalsPage> {
  final api = const ApiClient();
  Future<String>? statusFuture;
  Future<List<TradingSignal>>? signalsFuture;
  String? email;

  @override
  void initState() {
    super.initState();
    statusFuture = loadStatus();
  }

  Future<String> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('vipEmail');
    email = savedEmail;
    if (savedEmail == null || savedEmail.isEmpty) return 'not_submitted';

    final status = await api.getVipStatus(savedEmail);
    if (status == 'approved') {
      signalsFuture = api.getSignals(SignalAudience.vip, vipEmail: savedEmail);
    } else {
      signalsFuture = null;
    }
    return status;
  }

  void refresh() {
    setState(() {
      statusFuture = loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final status = snapshot.data ?? 'not_submitted';
        if (status != 'approved') {
          return LockedVipView(email: email, status: status, onRefresh: refresh);
        }

        return SignalsList(
          title: widget.title,
          futureSignals: signalsFuture ?? Future.value([]),
          onRefresh: refresh,
        );
      },
    );
  }
}

class SignalsList extends StatelessWidget {
  const SignalsList({
    super.key,
    required this.title,
    required this.futureSignals,
    required this.onRefresh,
  });

  final String title;
  final Future<List<TradingSignal>> futureSignals;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<TradingSignal>>(
        future: futureSignals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString(), onRetry: onRefresh);
          }

          final signals = snapshot.data ?? [];
          if (signals.isEmpty) {
            return EmptyState(title: title, onRefresh: onRefresh);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(title: title, onRefresh: onRefresh),
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
            InfoRow(icon: Icons.access_time, label: 'Time', value: formatSignalTime(signal.createdAt)),
            const SizedBox(height: 12),
            if (signal.isNew)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Chip(
                  avatar: Icon(Icons.fiber_new, size: 16),
                  label: Text('New signal'),
                ),
              ),
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

String formatSignalTime(DateTime? timestamp) {
  if (timestamp == null) return '-';
  final now = DateTime.now();
  final age = now.difference(timestamp);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inMinutes < 60) return '${age.inMinutes} min ago';
  if (age.inHours < 24) return '${age.inHours} hr ago';

  final day = timestamp.day.toString().padLeft(2, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$day/$month/${timestamp.year} $hour:$minute';
}

class LockedVipView extends StatelessWidget {
  const LockedVipView({super.key, required this.email, required this.status, required this.onRefresh});

  final String? email;
  final String status;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(title: 'VIP Locked', onRefresh: onRefresh),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock, size: 36),
                const SizedBox(height: 12),
                Text('VIP access is not active', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(statusMessage(status, email)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open the Unlock tab below to request VIP access.')),
                    );
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Text('How to Unlock'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String statusMessage(String status, String? email) {
    if (status == 'pending') return '$email is pending admin verification.';
    if (status == 'rejected') return '$email was not approved. Please register through the official partner link and submit again.';
    return 'Create an Exness account through the official partner link, submit your email, and wait for admin approval.';
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
  late Future<AppSettings> settingsFuture;
  bool loading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    settingsFuture = api.getSettings();
    loadSavedEmail();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('vipEmail');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }
  }

  Future<void> openPartnerLink(String link) async {
    final uri = Uri.parse(link);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      setState(() => message = 'Could not open partner link.');
    }
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vipEmail', email);
      setState(() {
        message = 'Request submitted. Admin will verify your Exness affiliation.';
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
        FutureBuilder<AppSettings>(
          future: settingsFuture,
          builder: (context, snapshot) {
            final link = snapshot.data?.exnessPartnerLink ?? 'https://one.exnessonelink.com/a/i2cmzyptz3';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Create your Exness account through the official partner link.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => openPartnerLink(link),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Partner Link'),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(link),
                    const SizedBox(height: 12),
                    const Text('2. Submit the same email here for manual VIP verification.'),
                  ],
                ),
              ),
            );
          },
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

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final api = const ApiClient();
  String? email;
  String status = 'not_submitted';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAccount();
  }

  Future<void> loadAccount() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('vipEmail');
    var nextStatus = 'not_submitted';
    if (savedEmail != null && savedEmail.isNotEmpty) {
      try {
        nextStatus = await api.getVipStatus(savedEmail);
      } catch (_) {
        nextStatus = 'unknown';
      }
    }
    setState(() {
      email = savedEmail;
      status = nextStatus;
      loading = false;
    });
  }

  Future<void> clearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vipEmail');
    await loadAccount();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = switch (status) {
      'approved' => 'VIP approved',
      'pending' => 'Pending admin verification',
      'rejected' => 'Rejected - register through the official link and resubmit',
      'unknown' => 'Could not check status',
      _ => 'Free user',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(title: 'My Account', onRefresh: loadAccount),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Submitted email'),
          subtitle: Text(email?.isNotEmpty == true ? email! : 'No email submitted yet'),
        ),
        ListTile(
          leading: loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.verified_user),
          title: const Text('VIP status'),
          subtitle: Text(statusText),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('Backend'),
          subtitle: Text(backendBaseUrl),
        ),
        const ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Notifications'),
          subtitle: Text('Firebase push notifications coming next'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: email == null ? null : clearEmail,
          icon: const Icon(Icons.logout),
          label: const Text('Clear Submitted Email'),
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
