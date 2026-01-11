import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MotivationPage extends StatefulWidget {
  const MotivationPage({super.key});

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage>
    with TickerProviderStateMixin {
  String motivationMessage = ""; // Başlangıç değeri eklendi
  String badge = ""; // Başlangıç değeri eklendi
  Color badgeColor = Colors.grey; // Başlangıç değeri eklendi
  int completedTasks = 0;
  int totalTasks = 0;
  String userId = "user_1";
  late AnimationController _fadeController;
  bool isLoading = true; // Yükleme durumu için

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadTaskStats();
  }

  Future<void> _loadTaskStats() async {
    setState(() {
      isLoading = true;
    });

    final tasksRef = FirebaseFirestore.instance.collection('tasks');
    final snapshot = await tasksRef.where('userId', isEqualTo: userId).get();

    int completed =
        snapshot.docs.where((doc) => doc['completed'] == true).length;
    int total = snapshot.docs.length;

    if (mounted) {
      setState(() {
        completedTasks = completed;
        totalTasks = total;
        _generateMotivation();
        isLoading = false;
      });
      _fadeController.forward(from: 0); // Animasyonu yeniden başlat
    }
  }

  void _generateMotivation() {
    final l10n = AppLocalizations.of(this.context);
    double completionRate = totalTasks == 0 ? 0 : (completedTasks / totalTasks);

    if (completionRate == 1.0 && totalTasks > 0) {
      motivationMessage = l10n.motivationMsgPerfect;
      badge = l10n.motivationPerfect;
      badgeColor = const Color(0xFFFFD700);
    } else if (completionRate >= 0.75) {
      motivationMessage = l10n.motivationMsgGreat;
      badge = l10n.motivationGreat;
      badgeColor = const Color(0xFFFF6B6B);
    } else if (completionRate >= 0.5) {
      motivationMessage = l10n.motivationMsgGood;
      badge = l10n.motivationGood;
      badgeColor = const Color(0xFF06A77D);
    } else if (completionRate > 0) {
      motivationMessage = l10n.motivationMsgStart;
      badge = l10n.motivationStart;
      badgeColor = const Color(0xFF00B4D8);
    } else {
      motivationMessage = l10n.motivationMsgReady;
      badge = l10n.motivationReady;
      badgeColor = const Color(0xFF9D84B7);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.motivationTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
          ),
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF06A77D)),
                )
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rozet
                      FadeTransition(
                        opacity: _fadeController,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [badgeColor.withOpacity(0.7), badgeColor],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          width: 120,
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  badge.split(' ')[0],
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  badge.split(' ').skip(1).join(' '),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Motivasyon mesajı
                      FadeTransition(
                        opacity: _fadeController,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF06A77D),
                                  const Color(0xFF00876F),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF06A77D,
                                  ).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  motivationMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Görev istatistikleri
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$completedTasks',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF06A77D),
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).motivationCompleted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$totalTasks',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00B4D8),
                                  ),
                                ),
                                Text(
                                  l10n.motivationTotal,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _loadTaskStats,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.motivationRefresh),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06A77D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
