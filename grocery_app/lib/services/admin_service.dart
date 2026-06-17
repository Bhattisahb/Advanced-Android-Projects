import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  const AdminService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<bool> isCurrentUserAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;

    final doc = await firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    return data?['isAdmin'] == true;
  }
}
