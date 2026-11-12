import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  void removeStrategy(int id) {
    final index = _strategies.indexWhere((strategy) => strategy.id == id);

    if (index == -1) return;

    final removedStrategy = _strategies.removeAt(index);

    _activityLog.insert(0, 'Removed strategy: ${removedStrategy.name}');

    if (_selectedStrategyId == id) {
      _selectedStrategyId = null;
    }

    notifyListeners();
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
      home: const AuthGate(),
    );
  }
}

// ============================================================
// FIREBASE AUTHENTICATION GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// ============================================================
// LOGIN AND REGISTRATION SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegistering = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isRegistering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Authentication failed.';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters.';
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart, size: 75, color: Colors.greenAccent),
              const SizedBox(height: 16),
              const Text(
                'AUTO TRADER',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isRegistering ? 'Create your account' : 'Welcome back',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : authenticate,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(isRegistering ? 'Register' : 'Login'),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isRegistering = !isRegistering;
                  });
                },
                child: Text(
                  isRegistering
                      ? 'Already have an account? Login'
                      : 'Need an account? Register',
                ),
              ),
            ],
          ),
        ),
      ),
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
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          strategy.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove strategy',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<ItemListModel>()
                                              .removeStrategy(strategy.id);
                                        },
                                      ),
                                    ],
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
// MARKET UPDATES API SCREEN
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
