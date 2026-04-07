import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_screen.dart';

/// ProviderProfileScreen
/// Fetches provider user document, reviews and services using providerId (uid).
class ProviderProfileScreen extends StatelessWidget {
  final String providerId;

  const ProviderProfileScreen({required this.providerId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
        actions: [
          // Debug-only helper: add a test review document and show its path
          if (kDebugMode)
            IconButton(
              tooltip: 'Add test review',
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                try {
                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                  final docRef = await FirebaseFirestore.instance
                      .collection('reviews')
                      .add({
                        'providerId': providerId,
                        'userId': userId,
                        'rating': 5,
                        'comment': 'Automated test review',
                        'createdAt': Timestamp.now(),
                      });

                  // show the created document path to aid debugging
                  if (ScaffoldMessenger.maybeOf(context) != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Created review: ${docRef.path}')),
                    );
                  }
                } catch (e) {
                  if (ScaffoldMessenger.maybeOf(context) != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create test review: $e'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final userDoc = snapshot.data!;
          final user = (userDoc.data() ?? {}) as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PROFILE HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['email'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // RATING (premium look)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('providerId', isEqualTo: providerId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 5),
                          Text(
                            '0.0 Rating',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    final docs = snap.data!.docs;
                    double avg = 0;
                    if (docs.isNotEmpty) {
                      avg =
                          docs
                              .map((e) => (e['rating'] ?? 0) as num)
                              .fold<num>(0, (a, b) => a + b) /
                          docs.length;
                    }
                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 5),
                        Text(
                          '${avg.toStringAsFixed(1)} Rating',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .where('providerId', isEqualTo: providerId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final services = snap.data!.docs;
                    if (services.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text('No services yet'),
                      );

                    return Column(
                      children: services.map((s) {
                        final data = s.data() as Map<String, dynamic>? ?? {};
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['title'] ?? ''),
                              Text('Rs. ${data['price'] ?? ''}'),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingScreen(providerId: providerId),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_today, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Book Now'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
