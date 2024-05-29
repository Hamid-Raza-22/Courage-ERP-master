
import 'package:order_booking_shop/Models/ProductsModel.dart';

class  RecoveryFormModel {

  dynamic? recoveryId;
  String? date;
  String? shopName;
  dynamic?cashRecovery;
  dynamic?netBalance;
  dynamic?userId;
  dynamic? bookerName;
  dynamic city;
  dynamic brand;

  RecoveryFormModel({

    this.recoveryId,
    this.date,
    this.shopName,
    this.cashRecovery,
    this.netBalance,
    this.userId,
    this.bookerName,
    this.city,
    this.brand

  });

  factory RecoveryFormModel.fromMap(Map<dynamic, dynamic> json) {
    return  RecoveryFormModel(

      recoveryId: json['recoveryId'],
      date: json['date'],
      shopName: json['shopName'],
      cashRecovery: json['cashRecovery'],
      netBalance: json['netBalance'],
      userId: json['userId'],
      bookerName: json['bookerName'],
      city: json['city'],
      brand: json['brand'],




    );
  }

  Map<String, dynamic> toMap() {
    return {

      'recoveryId': recoveryId,
      'date': date,
      'shopName': shopName,
      'cashRecovery': cashRecovery,
      'netBalance':netBalance,
      'userId': userId,
      'bookerName': bookerName,
      'city':city,
      'brand':brand

    };
  }
}
