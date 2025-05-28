import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a new document for the user in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'postCount': 0,
        'shots': [],
        'perfectFormCount': 0,
        'currentStreak': 0,
        'highestStreak': 0,
        'lastPostDate': null,
        'lastStreakUpdateDate': null,
        'dailyCounter': 0,
        'lastDailyCounterReset': FieldValue.serverTimestamp(),
      });

      return result.user;
    } catch (e) {
      print('Unexpected sign up error: $e');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<Map<String, dynamic>> incrementPostCountAndAddShot(
      Map<String, dynamic> shotData) async {
    User? user = currentUser;
    if (user != null) {
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);

      return _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          // If the user document doesn't exist, create it with initial data
          transaction.set(userRef, {
            'postCount': 1,
            'shots': [shotData],
            'perfectFormCount': shotData['similarity_score'] > 0.95 ? 1 : 0,
            'currentStreak': 1,
            'highestStreak': 1,
            'lastPostDate': FieldValue.serverTimestamp(),
            'lastStreakUpdateDate': FieldValue.serverTimestamp(),
            'dailyCounter': 1,
            'lastDailyCounterReset': FieldValue.serverTimestamp(),
          });
          return {
            'newStreak': true,
            'currentStreak': 1,
            'highestStreak': 1,
            'perfectFormCount': shotData['similarity_score'] > 0.95 ? 1 : 0,
            'dailyCounter': 1,
          };
        } else {
          // If the user document exists, update the data
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;
          int currentCount = userData['postCount'] ?? 0;
          List<dynamic> shots = userData['shots'] ?? [];
          int perfectFormCount = userData['perfectFormCount'] ?? 0;
          int currentStreak = userData['currentStreak'] ?? 0;
          int highestStreak = userData['highestStreak'] ?? 0;
          Timestamp? lastPostDate = userData['lastPostDate'] as Timestamp?;
          Timestamp? lastStreakUpdateDate =
              userData['lastStreakUpdateDate'] as Timestamp?;
          int dailyCounter = userData['dailyCounter'] ?? 0;
          Timestamp? lastDailyCounterReset =
              userData['lastDailyCounterReset'] as Timestamp?;

          shots.add(shotData);

          if (shotData['similarity_score'] > 0.95) {
            perfectFormCount++;
          }

          // Update streak
          DateTime now = DateTime.now();
          bool newStreak = false;

          if (lastStreakUpdateDate != null) {
            Duration difference = now.difference(lastStreakUpdateDate.toDate());
            if (difference.inHours >= 24) {
              if (difference.inHours <= 48) {
                currentStreak++;
                if (currentStreak > highestStreak) {
                  highestStreak = currentStreak;
                }
                newStreak = true;
              } else {
                currentStreak = 1;
                newStreak = true;
              }
              lastStreakUpdateDate = Timestamp.now();
            }
          } else {
            currentStreak = 1;
            highestStreak = 1;
            newStreak = true;
            lastStreakUpdateDate = Timestamp.now();
          }

          // Update daily counter
          if (lastDailyCounterReset != null) {
            Duration difference =
                now.difference(lastDailyCounterReset.toDate());
            if (difference.inHours >= 24) {
              // Reset daily counter if more than 24 hours have passed
              dailyCounter = 1;
              lastDailyCounterReset = Timestamp.now();
            } else {
              // Increment daily counter
              dailyCounter++;
            }
          } else {
            // First post of the day
            dailyCounter = 1;
            lastDailyCounterReset = Timestamp.now();
          }

          transaction.update(userRef, {
            'postCount': currentCount + 1,
            'shots': shots,
            'perfectFormCount': perfectFormCount,
            'currentStreak': currentStreak,
            'highestStreak': highestStreak,
            'lastPostDate': FieldValue.serverTimestamp(),
            'lastStreakUpdateDate': lastStreakUpdateDate,
            'dailyCounter': dailyCounter,
            'lastDailyCounterReset': lastDailyCounterReset,
          });

          return {
            'newStreak': newStreak,
            'currentStreak': currentStreak,
            'highestStreak': highestStreak,
            'perfectFormCount': perfectFormCount,
            'dailyCounter': dailyCounter,
          };
        }
      });
    }
    throw Exception('No authenticated user');
  }

  Future<Map<String, dynamic>> getUserStats() async {
    User? user = currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return {
          'perfectFormCount': userData['perfectFormCount'] ?? 0,
          'currentStreak': userData['currentStreak'] ?? 0,
          'highestStreak': userData['highestStreak'] ?? 0,
          'dailyCounter': userData['dailyCounter'] ?? 0,
        };
      }
    }
    return {
      'perfectFormCount': 0,
      'currentStreak': 0,
      'highestStreak': 0,
      'dailyCounter': 0,
    };
  }
}
