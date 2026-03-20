import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Actividad")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('activity')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i];

              return ListTile(
                title: Text(data['action']),
                subtitle: Text(data['uid']),
              );
            },
          );
        },
      ),
    );
  }
}