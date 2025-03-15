import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBusiness(
      {required String name,
        required String description,
        required String ownerId,
        required String address}) async {
    try {
      // Create a new document in the 'businesses' collection
      await _firestore.collection('businesses').add({
        'name': name, // Business name
        'description': description, // Business description
        'ownerId': ownerId, // ID of the business owner (or user)
        'address': address, // Business address
        'createdAt': FieldValue.serverTimestamp(), // When the business was created
      });
      print("Business added successfully!");
    } catch (e) {
      print("Error adding business: $e");
    }
  }
}