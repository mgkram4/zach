import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Page2 extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifetime Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate back to the homepage
              Navigator.of(context).pushReplacementNamed(
                  '/home'); // Adjust this route name as needed
            },
            tooltip: 'Go back to homepage',
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.amber, Colors.purple],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No user data available'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final totalShots = userData['postCount'] ?? 0;
          final perfectForms = userData['perfectFormCount'] ?? 0;
          final currentStreak = userData['currentStreak'] ?? 0;
          final highestStreak = userData['highestStreak'] ?? 0;

          // Calculate average similarity
          final shots = userData['shots'] as List<dynamic>? ?? [];
          double averageSimilarity = 0;
          if (shots.isNotEmpty) {
            double totalSimilarity = 0;
            int validShots = 0;
            for (var shot in shots) {
              final similarityScore =
                  shot['analysisResult']?['similarity_score'];
              if (similarityScore != null) {
                totalSimilarity += (similarityScore as num).toDouble();
                validShots++;
              }
            }
            averageSimilarity =
                validShots > 0 ? totalSimilarity / validShots : 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lifetime Stats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatCards(totalShots, perfectForms, averageSimilarity,
                    currentStreak, highestStreak),
                const SizedBox(height: 24),
                _buildChartCard(
                  'Shot Forms Distribution',
                  _buildPieChart(perfectForms, totalShots - perfectForms),
                ),
                const SizedBox(height: 24),
                _buildChartCard(
                  'Streak Comparison',
                  _buildBarChart(currentStreak, highestStreak),
                ),
                const SizedBox(height: 24),
                _buildChartCard(
                  'Recent Shot Similarity Trend',
                  _buildLineChart(shots.reversed.take(10).toList()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(int totalShots, int perfectForms,
      double averageSimilarity, int currentStreak, int highestStreak) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Shots', totalShots, Icons.sports_basketball),
        _buildStatCard('Perfect Forms', perfectForms, Icons.thumb_up),
        _buildStatCard(
            'Avg Similarity',
            '${(averageSimilarity * 100).toStringAsFixed(2)}%',
            Icons.equalizer),
        _buildStatCard('Current Streak', currentStreak, Icons.whatshot),
        _buildStatCard('Highest Streak', highestStreak, Icons.emoji_events),
      ],
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.amber, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.purple[800],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value != null
                  ? (value is int ? '$value' : value.toString())
                  : 'N/A',
              style: TextStyle(
                color: Colors.purple[600],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(int perfectForms, int otherForms) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: perfectForms.toDouble(),
            title: '$perfectForms',
            radius: 50,
            titleStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          PieChartSectionData(
            color: Colors.red,
            value: otherForms.toDouble(),
            title: '$otherForms',
            radius: 50,
            titleStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildBarChart(int currentStreak, int highestStreak) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (highestStreak + 1).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Current';
                    break;
                  case 1:
                    text = 'Highest';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(text,
                      style: TextStyle(
                          color: Colors.purple[600],
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: currentStreak.toDouble(),
                color: Colors.blue,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: highestStreak.toDouble(),
                color: Colors.purple,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> recentShots) {
    List<FlSpot> spots = [];
    for (int i = 0; i < recentShots.length; i++) {
      final similarityScore =
          recentShots[i]['analysisResult']?['similarity_score'];
      if (similarityScore != null) {
        spots.add(FlSpot(i.toDouble(), (similarityScore as num).toDouble()));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${(value * 100).toInt()}%',
                    style: TextStyle(color: Colors.purple[600], fontSize: 12));
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (recentShots.length - 1).toDouble(),
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: Colors.amber.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}
