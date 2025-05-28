import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Page1 extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Page1({super.key});

  Stream<List<Map<String, dynamic>>> _getShotHistoryStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          print('User document does not exist');
          return [];
        }
        final data = snapshot.data() as Map<String, dynamic>;
        final shots = data['shots'] as List<dynamic>? ?? [];
        print('Total shots: ${shots.length}');
        return shots
            .map((shot) {
              try {
                print('Processing shot: ${shot['timestamp']}');
                final analysisResult =
                    shot['analysisResult'] as Map<String, dynamic>;
                print('Analysis result: $analysisResult');

                if (analysisResult.containsKey('frame_results')) {
                  // This is a video analysis result
                  final frameResults =
                      analysisResult['frame_results'] as List<dynamic>;
                  final averageSimilarity =
                      analysisResult['average_similarity_score'] as double;
                  final allSuggestions = frameResults
                      .expand((frame) => (frame['suggestions'] as List<dynamic>)
                          .cast<String>())
                      .toSet()
                      .toList();

                  return {
                    'date': shot['timestamp'] ?? 'Unknown date',
                    'player': frameResults[0]['player'] ?? 'Unknown',
                    'similarity': averageSimilarity,
                    'suggestions': allSuggestions,
                    'type': 'video',
                  };
                } else {
                  // This is a picture analysis result
                  return {
                    'date': shot['timestamp'] ?? 'Unknown date',
                    'player': analysisResult['player'] ?? 'Unknown',
                    'similarity': (analysisResult['similarity_score'] as num?)
                            ?.toDouble() ??
                        0.0,
                    'suggestions':
                        List<String>.from(analysisResult['suggestions'] ?? []),
                    'type': 'picture',
                  };
                }
              } catch (e) {
                print('Error processing shot: $e');
                return null;
              }
            })
            .where((shot) => shot != null)
            .cast<Map<String, dynamic>>()
            .toList()
            .reversed
            .toList();
      });
    }
    print('No authenticated user');
    return Stream.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shot History'),
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getShotHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final historyItems = snapshot.data ?? [];

          if (historyItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No shot history available.'),
                  ElevatedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user != null) {
                        final docSnapshot = await _firestore
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        if (docSnapshot.exists) {
                          final data =
                              docSnapshot.data() as Map<String, dynamic>;
                          final shots = data['shots'] as List<dynamic>? ?? [];
                          print(
                              'Direct Firestore check: ${shots.length} shots');
                          for (var shot in shots) {
                            print(shot);
                          }
                        } else {
                          print('User document does not exist');
                        }
                      } else {
                        print('No authenticated user for direct check');
                      }
                    },
                    child: const Text('Check Firestore Directly'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final item = historyItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${item['date']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Compared with: ${item['player']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Similarity: ${(item['similarity'] * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suggestions:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      ...item['suggestions'].map<Widget>((suggestion) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right,
                                  color: Colors.purple),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
