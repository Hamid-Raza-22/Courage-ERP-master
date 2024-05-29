
import 'package:flutter/foundation.dart';
import 'package:order_booking_shop/API/Globals.dart';

import 'package:order_booking_shop/Models/OrderModels/OrderMasterModel.dart';

import '../../API/ApiServices.dart';
import '../../Databases/DBHelper.dart';

class OrderMasterRepository{

  DBHelper dbHelperOrderMaster = DBHelper();

  Future<List<OrderMasterModel>> getShopVisit() async{
    var dbClient = await dbHelperOrderMaster.db;
    List<Map> maps = await dbClient!.query('orderMaster',columns: ['orderId','date','shopName','ownerName','phoneNo','brand','userId','userName','total','creditLimit','requiredDelivery','shopCity','posted']);
    List<OrderMasterModel> ordermaster = [];
    for(int i = 0; i<maps.length; i++)
    {
      ordermaster.add(OrderMasterModel.fromMap(maps[i]));
    }

    return ordermaster;
  }
  Future<void> postMasterTable() async {
    var db = await dbHelper.db;
    final ApiServices api = ApiServices();

    try {
      final List<Map<String, dynamic>> records = await db!.query('orderMaster');

      // Print each record
      for (var record in records) {
        if (kDebugMode) {
          print(record.toString());
        }
      }
      // Select only the records that have not been posted yet
      final products = await db.rawQuery('SELECT * FROM orderMaster WHERE posted = 0');
      if (products.isNotEmpty) {  // Check if the table is not empty
        await db.transaction((txn) async {

          for (var i in products) {
          if (kDebugMode) {
            print("FIRST ${i.toString()}");
          }

          OrderMasterModel v = OrderMasterModel(
              orderId: i['orderId'].toString(),
              shopName: i['shopName'].toString(),
              ownerName: i['ownerName'].toString(),
              phoneNo: i['phoneNo'].toString(),
              brand: i['brand'].toString(),
              date: i['date'].toString(),
              userId: i['userId'].toString(),
              userName: i['userName'].toString(),
              shopCity: i['shopCity'].toString(),
              total: i['total'].toString(),
              // subTotal: i['subTotal'].toString(),
              // discount: i['discount'].toString(),
              creditLimit: i['creditLimit'].toString(),
              requiredDelivery: i['requiredDelivery'].toString()
          );

          var result1 = await api.masterPost(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/ordermaster/post/',);
          var result = await api.masterPost(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/ordermaster/post/',);

          if (result == true && result1 == true) {
            await txn.rawQuery("UPDATE orderMaster SET posted = 1 WHERE orderId = '${i['orderId']}'");

          }
        }});
      }
      }catch (e) {
      if (kDebugMode) {
        print("ErrorRRRRRRRRR: $e");
      }
      return;
    }
  }
  //
  // Future<String> getLastOrderId() async {
  //   var dbClient = await dbHelperOrderMaster.db;
  //   List<Map> maps = await dbClient.query(
  //     'orderMaster',
  //     columns: ['orderId'],
  //     orderBy: 'Id DESC',
  //     limit: 1,
  //   );
  //
  //   if (maps.isEmpty) {
  //     // Handle the case when no records are found
  //     return "";
  //   }
  //
  //   // Convert the orderId to a string and return
  //   return maps[0]['orderId'].toString();
  // }


  Future<int> add(OrderMasterModel ordermaster) async{
    var dbClient = await dbHelperOrderMaster.db;
    return await dbClient!.insert('orderMaster', ordermaster.toMap());
  }

  Future<int> update(OrderMasterModel ordermaster) async{
    var dbClient = await dbHelperOrderMaster.db;
    return await dbClient!.update('orderMaster', ordermaster.toMap(),
        where: 'orderId = ?', whereArgs: [ordermaster.orderId]);
  }


  Future<int> delete(int orderId) async{
    var dbClient = await dbHelperOrderMaster.db;
    return await dbClient!.delete('orderMaster',
        where: 'orderId = ?', whereArgs: [orderId]);
  }


  Future<List<GetOrderMasterModel>> getShopNameOrderMasterData(String user_id) async {
    var dbClient = await dbHelperOrderMaster.db;
    List<Map> maps = await dbClient!.query(
      'orderMasterData',
      columns: ['order_no', 'shop_name', 'user_Id'],
      where: 'user_Id = ?',
      whereArgs: [userId],
    );
    List<GetOrderMasterModel> getordermaster = [];
    for (int i = 0; i < maps.length; i++) {
      getordermaster.add(GetOrderMasterModel.fromMap(maps[i]));
    }
    return getordermaster;
  }
}
