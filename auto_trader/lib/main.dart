import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ItemListModel(),
      child: const AutoTraderApp(),
    ),
  );
}

// ============================================================
// TRADING STRATEGY MODEL
// ============================================================

class TradingStrategy {
  final int id;
  final String name;
  final String description;
  bool enabled;

  TradingStrategy({
    required this.id,
    required this.name,
    required this.description,
    this.enabled = false,
  });
}

// ============================================================
// PROVIDER MODEL
// All shared strategy and activity data lives here.
// ============================================================

class ItemListModel extends ChangeNotifier {
  final List<TradingStrategy> _strategies = [
    TradingStrategy(
      id: 1,
      name: 'Trend Following',
      description: 'Follows the general direction of market prices.',
    ),
    TradingStrategy(
      id: 2,
      name: 'Breakout',
      description: 'Monitors prices moving beyond key levels.',
    ),
    TradingStrategy(
      id: 3,
      name: 'Moving Average',
      description: 'Uses moving averages to study market momentum.',
    ),
  ];

  final List<String> _activityLog = ['Auto Trader demo initialized'];

  int _nextId = 4;
  int? _selectedStrategyId;

  List<TradingStrategy> get strategies => List.unmodifiable(_strategies);

  List<String> get activityLog => List.unmodifiable(_activityLog);

  TradingStrategy? get selectedStrategy {
    for (final strategy in _strategies) {
      if (strategy.id == _selectedStrategyId) {
        return strategy;
      }
    }
    return null;
  }

  void addStrategy({required String name, required String description}) {
    final strategy = TradingStrategy(
      id: _nextId++,
      name: name,
      description: description,
    );

    _strategies.add(strategy);
    _activityLog.insert(0, 'Added strategy: ${strategy.name}');
    notifyListeners();
  }

  void selectStrategy(int id) {
    _selectedStrategyId = id;
    notifyListeners();
  }

  void toggleStrategy(int id, bool enabled) {
    for (final strategy in _strategies) {
      if (strategy.id == id) {
        strategy.enabled = enabled;
        _activityLog.insert(
          0,
          '${strategy.name} ${enabled ? 'enabled' : 'disabled'}',
        );
        notifyListeners();
        return;
      }
    }
  }
}

// ============================================================
// APP
// ============================================================

class AutoTraderApp extends StatelessWidget {
  const AutoTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101410),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// ============================================================
// DASHBOARD SCREEN
// ============================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItemListModel>();
    final strategies = model.strategies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AUTO TRADER',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Trading Activity',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back'),
                SizedBox(height: 6),
                Text(
                  'Your Trading Dashboard',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage and monitor your demo strategies.',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trading Strategies',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddStrategyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: strategies.isEmpty
                ? const Center(child: Text('No strategies yet.'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: strategies.length,
                    itemBuilder: (context, index) {
                      final strategy = strategies[index];

                      return SizedBox(
                        width: 200,
                        child: Card(
                          color: const Color(0xFF202920),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              context.read<ItemListModel>().selectStrategy(
                                strategy.id,
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StrategyDetailScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.auto_graph,
                                    color: Colors.greenAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    strategy.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    strategy.enabled ? 'Enabled' : 'Disabled',
                                    style: TextStyle(
                                      color: strategy.enabled
                                          ? Colors.greenAccent
                                          : Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Market Watchlist',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.show_chart)),
                  title: Text('NQ'),
                  subtitle: Text('Nasdaq Futures'),
                  trailing: Text('Demo'),
                ),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.show_chart)),
                  title: Text('ES'),
                  subtitle: Text('S&P 500 Futures'),
                  trailing: Text('Demo'),
                ),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.currency_bitcoin)),
                  title: Text('BTC'),
                  subtitle: Text('Bitcoin'),
                  trailing: Text('Demo'),
                ),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.monetization_on)),
                  title: Text('XAUUSD'),
                  subtitle: Text('Gold'),
                  trailing: Text('Demo'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text('View Market Updates'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketApiScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStrategyScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Strategy'),
      ),
    );
  }
}

// ============================================================
// ADD STRATEGY SCREEN
// ============================================================

class AddStrategyScreen extends StatefulWidget {
  const AddStrategyScreen({super.key});

  @override
  State<AddStrategyScreen> createState() => _AddStrategyScreenState();
}

class _AddStrategyScreenState extends State<AddStrategyScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void saveStrategy() {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and description.')),
      );
      return;
    }

    context.read<ItemListModel>().addStrategy(
      name: name,
      description: description,
    );

    // The model is updated directly; no data is returned.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Strategy')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Strategy name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveStrategy,
                icon: const Icon(Icons.save),
                label: const Text('Save Strategy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STRATEGY DETAILS SCREEN
// ============================================================

class StrategyDetailScreen extends StatelessWidget {
  const StrategyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItemListModel>();
    final strategy = model.selectedStrategy;

    if (strategy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Strategy Details')),
        body: const Center(child: Text('Strategy not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Strategy Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_graph, size: 55, color: Colors.greenAccent),
            const SizedBox(height: 20),
            Text(
              strategy.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(strategy.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable strategy'),
              subtitle: Text(strategy.enabled ? 'Enabled' : 'Disabled'),
              value: strategy.enabled,
              onChanged: (value) {
                context.read<ItemListModel>().toggleStrategy(
                  strategy.id,
                  value,
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo only. This does not place real trades.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TRADING ACTIVITY SCREEN
// ============================================================

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = context.watch<ItemListModel>().activityLog;

    return Scaffold(
      appBar: AppBar(title: const Text('Trading Activity')),
      body: activities.isEmpty
          ? const Center(child: Text('No activity yet.'))
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: Colors.greenAccent,
                  ),
                  title: Text(activities[index]),
                );
              },
            ),
    );
  }
}

// ============================================================
// API DATA MODEL
// ============================================================

class MarketPost {
  final int id;
  final String title;
  final String body;

  const MarketPost({required this.id, required this.title, required this.body});

  factory MarketPost.fromJson(Map<String, dynamic> json) {
    return MarketPost(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

// ============================================================
// API REQUEST
// ============================================================

Future<List<MarketPost>> fetchMarketPosts() async {
  final response = await http
      .get(Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=10'))
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('The server returned an error.');
  }

  final List<dynamic> jsonList = jsonDecode(response.body);

  return jsonList
      .map((item) => MarketPost.fromJson(item as Map<String, dynamic>))
      .toList();
}

// ============================================================
// API SCREEN: LOADING, ERROR, EMPTY, DATA, REFRESH
// ============================================================

class MarketApiScreen extends StatefulWidget {
  const MarketApiScreen({super.key});

  @override
  State<MarketApiScreen> createState() => _MarketApiScreenState();
}

class _MarketApiScreenState extends State<MarketApiScreen> {
  late Future<List<MarketPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = fetchMarketPosts();
  }

  Future<void> _refreshPosts() async {
    final future = fetchMarketPosts();

    setState(() {
      _postsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error message.
    }
  }

  void _tryAgain() {
    setState(() {
      _postsFuture = fetchMarketPosts();
    });
  }

  Widget _messageView({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 130),
        Icon(icon, size: 48, color: Colors.white60),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          Center(child: action),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market Updates')),
      body: FutureBuilder<List<MarketPost>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: Builder(
              builder: (context) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _messageView(
                    icon: Icons.cloud_download,
                    message: 'Loading market updates...',
                    action: const CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _messageView(
                    icon: Icons.cloud_off,
                    message: 'Could not load updates. Check your internet connection and try again.',
                    action: ElevatedButton.icon(
                      onPressed: _tryAgain,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return _messageView(
                    icon: Icons.inbox_outlined,
                    message: 'No updates available right now.',
                    action: TextButton(
                      onPressed: _tryAgain,
                      child: const Text('Try again'),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${post.id}')),
                        title: Text(
                          post.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(post.body),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
