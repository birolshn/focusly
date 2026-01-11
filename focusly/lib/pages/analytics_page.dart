import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late FirebaseFirestore _firestore;
  late String _userId;
  String _selectedPeriod = 'daily'; // daily, weekly, monthly

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _userId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<Map<String, dynamic>> _getAnalyticsData() async {
    final now = DateTime.now();
    DateTime startDate;
    String period;

    if (_selectedPeriod == 'daily') {
      startDate = now.subtract(const Duration(days: 7));
      period = 'Günlük';
    } else if (_selectedPeriod == 'weekly') {
      startDate = now.subtract(const Duration(days: 56));
      period = 'Haftalık';
    } else {
      startDate = now.subtract(const Duration(days: 365));
      period = 'Aylık';
    }

    try {
      // Pomodoro verilerini al - basit sorgu, client-side filtreleme
      final pomodoroSnapshot =
          await _firestore
              .collection('pomodoro_sessions')
              .where('userId', isEqualTo: _userId)
              .get();

      // Tarih filtreleme client-side
      final filteredPomodoros = pomodoroSnapshot.docs.where((doc) {
        final completedAt = doc['completedAt'] as Timestamp?;
        if (completedAt == null) return false;
        return completedAt.toDate().isAfter(startDate) || 
               completedAt.toDate().isAtSameMomentAs(startDate);
      }).toList();

      // Tamamlanan görevleri al - basit sorgu
      final tasksSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: _userId)
              .get();

      // Client-side filtreleme: tamamlanmış ve tarih kontrolü
      final filteredTasks = tasksSnapshot.docs.where((doc) {
        final completed = doc['completed'] as bool? ?? false;
        if (!completed) return false;
        final completedAt = doc['completedAt'] as Timestamp?;
        if (completedAt == null) return false;
        return completedAt.toDate().isAfter(startDate) || 
               completedAt.toDate().isAtSameMomentAs(startDate);
      }).toList();

      int pomodoroCount = filteredPomodoros.length;
      int completedTasks = filteredTasks.length;
      int totalPomodoroDuration = filteredPomodoros.fold(
        0,
        (sum, doc) => sum + (doc['duration'] as int? ?? 25),
      );

      return {
        'pomodoroCount': pomodoroCount,
        'completedTasks': completedTasks,
        'totalDuration': totalPomodoroDuration,
        'period': period,
        'startDate': startDate,
      };
    } catch (e) {
      debugPrint('Analytics Hata: $e');
      return {
        'pomodoroCount': 0,
        'completedTasks': 0,
        'totalDuration': 0,
        'period': period,
        'startDate': startDate,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'İlerleme Analizi',
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            // Period Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPeriodButton('Günlük', 'daily'),
                  _buildPeriodButton('Haftalık', 'weekly'),
                  _buildPeriodButton('Aylık', 'monthly'),
                ],
              ),
            ),
            // Analytics Content
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getAnalyticsData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata oluştu',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    );
                  }

                  final data = snapshot.data ?? {};
                  final pomodoroCount = data['pomodoroCount'] as int? ?? 0;
                  final completedTasks = data['completedTasks'] as int? ?? 0;
                  final totalDuration = data['totalDuration'] as int? ?? 0;
                  final period = data['period'] as String? ?? 'Günlük';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Stats Cards
                        _buildStatCard(
                          'Pomodoro Oturumu',
                          pomodoroCount.toString(),
                          const Color(0xFFE94560),
                          Icons.timer,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Tamamlanan Görev',
                          completedTasks.toString(),
                          const Color(0xFF00B4D8),
                          Icons.done_all,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Toplam Çalışma Süresi',
                          '${totalDuration} dk',
                          const Color(0xFF06A77D),
                          Icons.schedule,
                        ),
                        const SizedBox(height: 24),

                        // Chart Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$period İlerleme',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Simple bar chart representation
                              _buildChartBar(
                                'Pomodoro',
                                pomodoroCount,
                                20,
                                const Color(0xFFE94560),
                              ),
                              const SizedBox(height: 16),
                              _buildChartBar(
                                'Görev Tamamlama',
                                completedTasks,
                                20,
                                const Color(0xFF00B4D8),
                              ),
                              const SizedBox(height: 16),
                              _buildChartBar(
                                'Çalışma Saatleri',
                                (totalDuration ~/ 60),
                                20,
                                const Color(0xFF06A77D),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF00B4D8)
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF00B4D8)
                    : Colors.white.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, int value, int maxValue, Color color) {
    final percentage = (value / (maxValue > 0 ? maxValue : 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
