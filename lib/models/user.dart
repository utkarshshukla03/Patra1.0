import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String uid;
  final String photoUrl;
  final String username;
  final String? bio;
  final int? age;
  final String? gender;
  final List<String>? orientation;
  final List<String>? interests;
  final String? location;
  final List<String>? photoUrls;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.email,
    required this.uid,
    required this.photoUrl,
    required this.username,
    this.bio,
    this.age,
    this.gender,
    this.orientation,
    this.interests,
    this.location,
    this.photoUrls,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
  });

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return User(
      email: snapshot['email'] ?? '',
      uid: snapshot['uid'] ?? '',
      photoUrl: snapshot['photoUrl'] ?? '',
      username: snapshot['username'] ?? '',
      bio: snapshot['bio'],
      age: snapshot['age'],
      gender: snapshot['gender'],
      orientation: snapshot['orientation'] != null
          ? List<String>.from(snapshot['orientation'])
          : null,
      interests: snapshot['interests'] != null
          ? List<String>.from(snapshot['interests'])
          : null,
      location: snapshot['location'],
      photoUrls: snapshot['photoUrls'] != null
          ? List<String>.from(snapshot['photoUrls'])
          : null,
      dateOfBirth: snapshot['dateOfBirth'] != null
          ? (snapshot['dateOfBirth'] as Timestamp).toDate()
          : null,
      createdAt: snapshot['createdAt'] != null
          ? (snapshot['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: snapshot['updatedAt'] != null
          ? (snapshot['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "username": username,
        "uid": uid,
        "email": email,
        "photoUrl": photoUrl,
        "bio": bio,
        "age": age,
        "gender": gender,
        "orientation": orientation,
        "interests": interests,
        "location": location,
        "photoUrls": photoUrls,
        "dateOfBirth":
            dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
        "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        "updatedAt": updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  // Calculate age from date of birth
  int get calculatedAge {
    if (age != null) return age!;
    if (dateOfBirth == null) return 0;

    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  // Get primary photo URL
  String get primaryPhotoUrl {
    if (photoUrls != null && photoUrls!.isNotEmpty) {
      return photoUrls!.first;
    }
    return photoUrl;
  }
}
