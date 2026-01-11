import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';
import 'pomodoro_page.dart';
import 'todo_page.dart';
import 'motivation_page.dart';
import 'analytics_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const HomePage({super.key, this.onLanguageChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _sessionDuration = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  int _streakDays = 0;
  late SharedPreferences _prefs;
  late Timer _durationTimer;
  late String userId;
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    _initializeData();
    _startDurationTimer();
    _setupTaskListener();
  }

  Future<void> _initializeData() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSessionDuration();
    _loadStreakDays();
    _loadTaskStats();
  }

  void _loadSessionDuration() {
    final savedTime = _prefs.getInt('session_duration_today') ?? 0;
    final lastDate = _prefs.getString('last_session_date') ?? '';
    final today = DateTime.now().toString().split(' ')[0];

    if (lastDate != today) {
      // Yeni gün başladı, sürü sıfırla
      _prefs.setInt('session_duration_today', 0);
      setState(() => _sessionDuration = 0);
      _prefs.setString('last_session_date', today);
    } else {
      setState(() => _sessionDuration = savedTime);
    }
  }

  void _loadStreakDays() async {
    final lastAccessDate = _prefs.getString('last_access_date') ?? '';
    final today = DateTime.now().toString().split(' ')[0];
    final yesterday =
        DateTime.now()
            .subtract(const Duration(days: 1))
            .toString()
            .split(' ')[0];

    int streak = _prefs.getInt('streak_days') ?? 0;

    if (lastAccessDate.isEmpty) {
      // İlk gün
      streak = 1;
    } else if (lastAccessDate == yesterday) {
      // Dün açılmış, streak devam
      streak += 1;
    } else if (lastAccessDate != today) {
      // Aradan gün geçmiş, streak sıfırla
      streak = 1;
    }

    await _prefs.setInt('streak_days', streak);
    await _prefs.setString('last_access_date', today);
    setState(() => _streakDays = streak);
  }

  Future<void> _loadTaskStats() async {
    final tasksRef = FirebaseFirestore.instance.collection('tasks');
    final snapshot = await tasksRef.where('userId', isEqualTo: userId).get();

    int completed =
        snapshot.docs.where((doc) => doc['completed'] == true).length;
    int total = snapshot.docs.length;

    if (mounted) {
      setState(() {
        _completedTasks = completed;
        _totalTasks = total;
      });
    }
  }

  void _setupTaskListener() {
    FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            int completed =
                snapshot.docs.where((doc) => doc['completed'] == true).length;
            int total = snapshot.docs.length;
            setState(() {
              _completedTasks = completed;
              _totalTasks = total;
            });
          }
        });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() => _sessionDuration++);

      // Her dakika kaydet
      if (_sessionDuration % 60 == 0) {
        await _prefs.setInt('session_duration_today', _sessionDuration);
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  @override
  void dispose() {
    _durationTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Locale değişirken l10n null olabilir
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        title: Text(
          l10n.appTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          // Dil seçimi dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PopupMenuButton<String>(
              color: const Color(0xFF0F3460),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (lang) {
                widget.onLanguageChanged?.call(lang);
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'en',
                      child: Row(
                        children: [
                          Text(
                            currentLocale == 'en' ? '✓ ' : '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Text(
                            'English',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'tr',
                      child: Row(
                        children: [
                          Text(
                            currentLocale == 'tr' ? '✓ ' : '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Text(
                            'Türkçe',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
              icon: const Icon(Icons.language, color: Colors.white),
            ),
          ),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  builder:
                      (BuildContext context) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text(
                          'Hesabınızdan çıkmak istediğinize emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _authService.signOut();
                              if (mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Çıkış Yap',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Home Tab
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hoş geldin başlığı
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.homeGreeting,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                Text(
                  l10n.homeSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // İstatistik kartları
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        l10n.homeToday,
                        _formatDuration(_sessionDuration),
                        const Color(0xFFE94560),
                        Icons.timer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard(
                        l10n.homeTasks,
                        '$_completedTasks/$_totalTasks',
                        const Color(0xFF00B4D8),
                        Icons.done,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard(
                        l10n.homeStreak,
                        '$_streakDays ${currentLocale == 'tr' ? 'gün' : 'days'}',
                        const Color(0xFF06A77D),
                        Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Ana özellikler
                Text(
                  l10n.homeFeatures,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                buildCard(
                  context,
                  l10n.pomodoroTitle,
                  Icons.schedule,
                  const Color(0xFFE94560),
                  const PomodoroPage(),
                  l10n.tapToOpen,
                ),
                buildCard(
                  context,
                  l10n.todoTitle,
                  Icons.checklist,
                  const Color(0xFF00B4D8),
                  const TodoPage(),
                  l10n.tapToOpen,
                ),
                buildCard(
                  context,
                  l10n.motivationTitle,
                  Icons.lightbulb,
                  const Color(0xFF06A77D),
                  const MotivationPage(),
                  l10n.tapToOpen,
                ),

                // Alt bilgi
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: Center(
                    child: Text(
                      l10n.homeMotivation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Settings Tab - Analytics & Profile
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
              ),
            ),
            child: PageView(children: const [AnalyticsPage(), ProfilePage()]),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: const Color(0xFF0F3460),
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00B4D8),
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          indicatorColor: const Color(0xFF00B4D8),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(icon: const Icon(Icons.home), text: 'Ana Sayfa'),
            Tab(icon: const Icon(Icons.settings), text: 'Ayarlar'),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(
    BuildContext c,
    String title,
    IconData icon,
    Color color,
    Widget page,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
