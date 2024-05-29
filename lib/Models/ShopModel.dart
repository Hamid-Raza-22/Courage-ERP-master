import 'dart:convert' show base64Decode, base64Encode;
import 'dart:typed_data' show Uint8List;

class ShopModel {
  dynamic id;
  String? shopName;
  String? city;
  String? date;
  String? shopAddress;
  String? ownerName;
  String? ownerCNIC;
  String? phoneNo;
  dynamic alternativePhoneNo;
  dynamic latitude;
  dynamic longitude;
  dynamic userId;
  Uint8List? body;

  ShopModel({
    this.id,
    this.shopName,
    this.city,
    this.date,
    this.shopAddress,
    this.ownerName,
    this.ownerCNIC,
    this.phoneNo,
    this.alternativePhoneNo,
     this.latitude,
    this.body,
     this.longitude,
    this.userId
  });

  factory ShopModel.fromMap(Map<dynamic, dynamic> json) {
    //var location = (json['location'] ?? '').split(',');
    return ShopModel(
      id: json['id'],
      shopName: json['shopName'],
      city: json['city'],
      date: json['date'],
      shopAddress: json['shopAddress'],
      ownerName: json['ownerName'],
      ownerCNIC: json['ownerCNIC'],
      phoneNo: json['phoneNo'],
      alternativePhoneNo: json['alternativePhoneNo'],
      latitude:json['latitude'],
      longitude: json['longitude'],
        userId: json['userId'],
      body: json['body'] != null && json['body'].toString().isNotEmpty
          ? Uint8List.fromList(base64Decode(json['body'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopName': shopName,
      'city': city,
      'date': date,
      'shopAddress': shopAddress,
      'ownerName': ownerName,
      'ownerCNIC': ownerCNIC,
      'phoneNo': phoneNo,
      'alternativePhoneNo': alternativePhoneNo,
      'latitude':latitude,
      'longitude':longitude,
      'userId': userId,
      'body':  body != null ? base64Encode(body!) : null
    };
  }
}
