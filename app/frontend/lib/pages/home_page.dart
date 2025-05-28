import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:testsdk/pages/daily.dart';
import 'package:testsdk/pages/page1.dart';
import 'package:testsdk/pages/page2.dart';
import 'package:testsdk/pages/post_page.dart';
import 'package:testsdk/services/auth_service.dart';
import 'package:testsdk/widgets/app_drawer.dart';

class HomePage extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = _authService.currentUser;
    String userName = user != null ? user.email!.split('@')[0] : 'Player';

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user?.uid).snapshots(),
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
          final currentStreak = userData['currentStreak'] ?? 0;
          final perfectFormCount = userData['perfectFormCount'] ?? 0;
          final dailyCounter = userData['dailyCounter'] ?? 0;

          return CustomScrollView(
            slivers: [
              _buildAppBar(userName),
              SliverToBoxAdapter(child: _buildDailyChallenge(dailyCounter)),
              SliverToBoxAdapter(
                  child: _buildQuickStats(
                      totalShots, currentStreak, perfectFormCount)),
              SliverToBoxAdapter(child: _buildFeatureCards(context)),
              SliverToBoxAdapter(
                  child: _buildRecentActivity(userData['shots'] ?? [])),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PostPage(userId: user?.uid ?? '')),
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('SharpShooter Hub',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.amber, Colors.purple],
            ),
          ),
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: Text(userName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildDailyChallenge(int dailyCounter) {
    const goalShots = 50; // Assuming the daily goal is 50 shots
    final progress = dailyCounter / goalShots;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Challenge',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Make $goalShots shots today',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.purple[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
          const SizedBox(height: 8),
          Text('$dailyCounter/$goalShots completed',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      int totalShots, int currentStreak, int perfectShotForms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('Total Shots', totalShots, Icons.sports_basketball),
          _buildStatCard(
              'Day Streak', currentStreak, Icons.local_fire_department),
          _buildStatCard('Perfect Forms', perfectShotForms, Icons.thumb_up),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      width: 110,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
                color: Colors.purple[800],
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.purple[600], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard('Post a Shot', Icons.add_a_photo, Colors.amber, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PostPage(
                        userId: '',
                      )),
            );
          }),
          _buildFeatureCard('History', Icons.history, Colors.purple, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Page1()),
            );
          }),
          _buildFeatureCard('User Stats', Icons.bar_chart, Colors.amber, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Page2()),
            );
          }),
          _buildFeatureCard(
              'Daily Challenges', Icons.emoji_events, Colors.purple, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DailyChallengesPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<dynamic> shots) {
    final recentShots = shots.reversed.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity',
              style: TextStyle(
                  color: Colors.purple[800],
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...recentShots.map((shot) {
            final analysisResult =
                shot['analysisResult'] as Map<String, dynamic>?;
            final similarityScore = analysisResult?['similarity_score'] as num?;
            final timestamp = shot['timestamp'];

            return _buildActivityItem(
              similarityScore != null
                  ? 'Shot with ${(similarityScore * 100).toStringAsFixed(2)}% similarity'
                  : 'Shot taken',
              _formatTimestamp(timestamp),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: const TextStyle(color: Colors.black87)),
                Text(time,
                    style: TextStyle(color: Colors.purple[400], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime shotTime;
    if (timestamp is Timestamp) {
      shotTime = timestamp.toDate();
    } else if (timestamp is String) {
      shotTime = DateTime.parse(timestamp);
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(shotTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
