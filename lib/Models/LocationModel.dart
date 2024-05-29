import 'dart:convert';
import 'dart:typed_data';

class LocationModel {
  dynamic? id;
  String? date;
  String? fileName;
  String? userId;
  Uint8List? body;
  dynamic? userName;
  dynamic? totalDistance;


  LocationModel({
    this.id,
    this.date,
    this.fileName,
    this.userId,
    this.body,
    this.userName,
    this.totalDistance
  });

  factory LocationModel.fromMap(Map<dynamic, dynamic> json) {

    return LocationModel(
        id: json['id'],
        date : json['date'],
      fileName: json['fileName'],
        userId: json['userId'],
        userName: json['userName'],
        totalDistance: json['totalDistance'],
      body: json['body'] != null && json['body'].toString().isNotEmpty
          ? Uint8List.fromList(base64Decode(json['body'].toString()))
          : null,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'fileName': fileName,
      'userId': userId,
      'userName':userName,
      'totalDistance': totalDistance,
      'body':  body != null ? base64Encode(body!) : null,
    };
  }
}