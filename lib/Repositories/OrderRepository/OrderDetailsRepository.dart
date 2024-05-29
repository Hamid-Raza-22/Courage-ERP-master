
import 'package:flutter/foundation.dart';
import 'package:order_booking_shop/API/Globals.dart';

import '../../API/ApiServices.dart';
import '../../Databases/DBHelper.dart';
import '../../Models/OrderModels/OrderDetailsModel.dart';

class OrderDetailsRepository {

  DBHelper dbHelperOrderDetails = DBHelper();

  Future<List<OrderDetailsModel>> getOrderDetails() async {
    var dbClient = await dbHelperOrderDetails.db;
    List<Map> maps = await dbClient!.query('order_details', columns: ['id','order_master_id', 'productName', 'quantity', 'price', 'amount','userId','posted']);
    List<OrderDetailsModel> orderdetails = [];
    for (int i = 0; i < maps.length; i++) {

      orderdetails.add(OrderDetailsModel.fromMap(maps[i]));
    }
    return orderdetails;
  }
  Future<void> postOrderDetails() async {
    var db = await dbHelper.db;
    final ApiServices api = ApiServices();
    try {

      final List<Map<String, dynamic>> records = await db!.query('order_details');

      // Print each record
      for (var record in records) {
        if (kDebugMode) {
          print(record.toString());
        }
      }
      // Select only the records that have not been posted yet
      final products = await db.rawQuery('SELECT * FROM order_details WHERE posted = 0');
      if (products.isNotEmpty) {
        // Check if the table is not empty
        await db.transaction((txn) async {
          for (var i in products) {
            if (kDebugMode) {
              print("FIRST ${i.toString()}");
            }

            OrderDetailsModel v = OrderDetailsModel(
              id: i['id'].toString(),
              orderMasterId: i['order_master_id'].toString(),
              productName: i['productName'].toString(),
              price: i['price'].toString(),
              quantity: i['quantity'].toString(),
              amount: i['amount'].toString(),
              userId: i['userId'].toString(),
            );
            var result1 = await api.masterPost(v.toMap(),
                'http://103.149.32.30:8080/ords/metaxperts/orderdetail/post/');
            var result = await api.masterPost(v.toMap(),
                'https://apex.oracle.com/pls/apex/metaxpertss/orderdetail/post/');
            if (result == true && result1 == true) {
              await txn.rawQuery(
                  "UPDATE order_details SET posted = 1 WHERE id = '${i['id']}'");
            }
          }
        });
      }

    } catch (e) {
      if (kDebugMode) {
        print("ErrorRRRRRRRRR: $e");
      }
      return;
    }
  }
  Future<int> add(OrderDetailsModel orderdetailsModel) async {
    var dbClient = await dbHelperOrderDetails.db;
    return await dbClient!.insert('order_details', orderdetailsModel.toMap());
  }

  Future<int> update(OrderDetailsModel orderdetailsModel) async {
    var dbClient = await dbHelperOrderDetails.db;
    return await dbClient!.update('order_details', orderdetailsModel.toMap(),
        where: 'id = ?', whereArgs: [orderdetailsModel.id]);
  }

  Future<int> delete(int id) async {
    var dbClient = await dbHelperOrderDetails.db;
    return await dbClient!.delete('order_details',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GetOrderDetailsModel>> getOrderDetailsProductNamesByOrder(String order_no) async {
    var dbClient = await dbHelperOrderDetails.db;
    List<Map> maps = await dbClient!.query(
      'orderDetailsData',
      columns: ['order_no', 'product_name'],
      where: 'order_no = ?',
      whereArgs: [selectedorderno],
    );
    List<GetOrderDetailsModel> products = [];
    for (int i = 0; i < maps.length; i++) {
      products.add(GetOrderDetailsModel.fromMap(maps[i]));
    }
    return products;
  }
}