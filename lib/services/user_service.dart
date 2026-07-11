import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String loginId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('loginId', isEqualTo: loginId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return AppUser.fromMap(
      querySnapshot.docs.first.data(),
    );
  }
}