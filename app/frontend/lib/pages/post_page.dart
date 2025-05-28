import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testsdk/services/StorageService.dart';
import 'package:testsdk/services/auth_service.dart';
import 'package:video_player/video_player.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key, required String userId});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> players = [
    {'name': 'Anthony Edwards', 'image': 'images/players/edwards/edwards1.png'},
    {'name': 'Lebron', 'image': 'images/players/lebron/lebron1.png'},
  ];

  String? selectedPlayer;
  File? mediaFile;
  bool isVideo = false;
  VideoPlayerController? _videoController;
  Map<String, dynamic>? analysisResult;
  int perfectFormCount = 0;
  int currentStreak = 0;
  int highestStreak = 0;
  int dailyCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    Map<String, dynamic> stats = await _authService.getUserStats();
    setState(() {
      perfectFormCount = stats['perfectFormCount'] ?? 0;
      currentStreak = stats['currentStreak'] ?? 0;
      highestStreak = stats['highestStreak'] ?? 0;
      dailyCounter = stats['dailyCounter'] ?? 0;
    });
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      XFile? pickedFile;
      if (isVideo) {
        pickedFile = await _picker.pickVideo(source: source);
      } else {
        pickedFile = await _picker.pickImage(source: source);
      }

      if (pickedFile != null) {
        setState(() {
          mediaFile = File(pickedFile!.path);
          this.isVideo = isVideo;
          analysisResult = null; // Clear previous results
        });

        if (isVideo) {
          _videoController = VideoPlayerController.file(mediaFile!)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      }
    } catch (e) {
      print("Error picking media: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  Future<void> _analyzeAndStoreShot() async {
    if (selectedPlayer == null || mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a player and a media file')),
      );
      return;
    }

    try {
      print(
          "Analyzing ${isVideo ? 'video' : 'image'} for player: $selectedPlayer");
      final result = await _storageService.analyzeAndStoreShot(
          mediaFile!, selectedPlayer!, isVideo);

      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }

      double similarityScore = result['average_similarity_score'] ??
          result['similarity_score'] ??
          0.0;

      Map<String, dynamic> shotData = {
        'player': selectedPlayer,
        'timestamp': DateTime.now().toIso8601String(),
        'analysisResult': result,
        'similarity_score': similarityScore,
      };

      final updateResult =
          await _authService.incrementPostCountAndAddShot(shotData);

      setState(() {
        analysisResult = result;
        perfectFormCount = updateResult['perfectFormCount'] ?? perfectFormCount;
        currentStreak = updateResult['currentStreak'] ?? currentStreak;
        highestStreak = updateResult['highestStreak'] ?? highestStreak;
        dailyCounter = updateResult['dailyCounter'] ?? dailyCounter;
      });

      String message = 'Shot analyzed and stored successfully. ';
      if (similarityScore > 0.95) {
        message +=
            'Perfect form! Your perfect form count is now $perfectFormCount. ';
      }
      if (updateResult['newStreak'] == true) {
        message += 'Streak updated! ';
      }
      message +=
          'Current streak: $currentStreak, Highest streak: $highestStreak, Daily shots: $dailyCounter';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.purple,
        ),
      );
    } catch (e) {
      print("Error analyzing and storing ${isVideo ? 'video' : 'image'}: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Shot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/home');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildPlayerSelection(),
            const SizedBox(height: 20),
            _buildMediaPreview(),
            const SizedBox(height: 20),
            _buildMediaButtons(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _analyzeAndStoreShot,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Analyze and Post Shot'),
            ),
            const SizedBox(height: 20),
            if (analysisResult != null) _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      color: Colors.purple[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stats',
                style: TextStyle(
                    color: Colors.purple[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Perfect Form Count: $perfectFormCount',
                style: TextStyle(color: Colors.purple[700])),
            Text('Current Streak: $currentStreak',
                style: TextStyle(color: Colors.purple[700])),
            Text('Highest Streak: $highestStreak',
                style: TextStyle(color: Colors.purple[700])),
            Text('Daily Shots: $dailyCounter',
                style: TextStyle(color: Colors.purple[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelection() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedPlayer,
              hint: const Text('Select a player'),
              isExpanded: true,
              items: players.map((player) {
                return DropdownMenuItem<String>(
                  value: player['name'],
                  child: Text(player['name'] ?? ''),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPlayer = newValue;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (selectedPlayer != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                players.firstWhere(
                    (player) => player['name'] == selectedPlayer)['image'],
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: SizedBox(
        height: 200,
        child: mediaFile != null
            ? isVideo
                ? _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.amber))
                : Image.file(mediaFile!, fit: BoxFit.cover)
            : Center(
                child: Text('No media selected',
                    style: TextStyle(color: Colors.purple[300]))),
      ),
    );
  }

  Widget _buildMediaButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickMedia(ImageSource.gallery),
          icon: const Icon(Icons.photo),
          label: const Text('Photo'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
          icon: const Icon(Icons.videocam),
          label: const Text('Video'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisResult() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis Result',
                style: TextStyle(
                    color: Colors.purple[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
                'Similarity Score: ${((analysisResult!['average_similarity_score'] ?? analysisResult!['similarity_score'] ?? 0.0) * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                    color: Colors.purple[700], fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Angle Differences:',
                style: TextStyle(
                    color: Colors.purple[700], fontWeight: FontWeight.bold)),
            ...(analysisResult!['angle_differences'] as Map<String, dynamic>? ??
                    {})
                .entries
                .map((entry) => Text(
                    '${entry.key}: ${entry.value.toStringAsFixed(2)} degrees',
                    style: TextStyle(color: Colors.purple[600]))),
            const SizedBox(height: 10),
            Text('Suggestions:',
                style: TextStyle(
                    color: Colors.purple[700], fontWeight: FontWeight.bold)),
            ...(analysisResult!['suggestions'] as List<dynamic>? ?? []).map(
                (suggestion) => Text('• $suggestion',
                    style: TextStyle(color: Colors.purple[600]))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
