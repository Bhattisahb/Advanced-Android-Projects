// ONE-TIME PRODUCT SEED — read steps below, then run:
//
//   flutter run -t lib/main_seed.dart
//
// BEFORE running:
//   Firebase Console → Firestore → Rules → temporarily allow writes on products, e.g.:
//
//     match /products/{id} {
//       allow read: if true;
//       allow write: if true;   // TEMPORARY — revert after seeding
//     }
//
// AFTER seeding succeeds → tighten rules (e.g. read true, write only admin).
//
// Stop the app when you see "Seeding finished".

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/catalog_product_maps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const _SeedApp());
}

class _SeedApp extends StatefulWidget {
  const _SeedApp();

  @override
  State<_SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<_SeedApp> {
  String _status = 'Starting…';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final col = FirebaseFirestore.instance.collection('products');
      final list = catalogFirestoreMaps();
      // Firestore batches cap at 500 ops — chunk when catalog grows.
      const chunkSize = 450;
      for (var i = 0; i < list.length; i += chunkSize) {
        final batch = FirebaseFirestore.instance.batch();
        final end = i + chunkSize > list.length ? list.length : i + chunkSize;
        for (var j = i; j < end; j++) {
          final p = list[j];
          final id = p['id']! as String;
          batch.set(col.doc(id), p);
        }
        await batch.commit();
      }

      setState(() {
        _status =
            'Seeding finished. ${list.length} products written to `products`.\n'
            'Restore strict Firestore rules, then run lib/main.dart.';
        _done = true;
      });
    } catch (e) {
      setState(() {
        _status =
            'Error: $e\n\nIf permission denied, temporarily allow writes on '
            '`products` in Firestore Rules, then run again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seed Firestore',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_done) const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(_status, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
