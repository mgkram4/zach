import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DailyChallengesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  const DailyChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
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
          final dailyCounter = userData['dailyCounter'] ?? 0;
          final perfectFormCount = userData['perfectFormCount'] ?? 0;
          final currentStreak = userData['currentStreak'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDailyChallenge(dailyCounter),
              const SizedBox(height: 20),
              _buildChallenge(
                'Perfect Form Master',
                'Achieve 10 perfect shots today',
                perfectFormCount,
                10,
                Icons.stars,
              ),
              const SizedBox(height: 20),
              _buildChallenge(
                'Consistency King',
                'Practice 7 days in a row',
                currentStreak,
                7,
                Icons.calendar_today,
              ),
              const SizedBox(height: 20),
              _buildChallenge(
                'Volume Shooter',
                'Take 100 shots today',
                dailyCounter,
                100,
                Icons.sports_basketball,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyChallenge(int dailyCounter) {
    const goalShots = 50;
    final progress = dailyCounter / goalShots;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Shot Challenge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make $goalShots shots today',
              style: TextStyle(fontSize: 16, color: Colors.purple[600]),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.purple[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: 8),
            Text(
              '$dailyCounter/$goalShots completed',
              style: TextStyle(color: Colors.purple[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallenge(
      String title, String description, int current, int goal, IconData icon) {
    final progress = current / goal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.purple[600]),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.purple[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: 8),
            Text(
              '$current/$goal completed',
              style: TextStyle(color: Colors.purple[400]),
            ),
          ],
        ),
      ),
    );
  }
}
