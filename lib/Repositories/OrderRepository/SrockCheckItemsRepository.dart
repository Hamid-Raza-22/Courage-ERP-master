
import 'package:flutter/foundation.dart';
import 'package:order_booking_shop/Databases/DBHelper.dart';

import '../../API/ApiServices.dart';
import '../../Models/StockCheckItems.dart';

class StockCheckItemsRepository {

  DBHelper dbHelperStockCheckItems = DBHelper();

  Future<List<StockCheckItemsModel>> getStockCheckItems() async {
    var dbClient = await dbHelperStockCheckItems.db;
    List<Map> maps = await dbClient!.query('Stock_Check_Items', columns: ['id','shopvisitId', 'itemDesc', 'qty' ]);
    List<StockCheckItemsModel> stockcheckitems = [];
    for (int i = 0; i < maps.length; i++) {

      stockcheckitems.add(StockCheckItemsModel.fromMap(maps[i]));
    }
    return stockcheckitems;
  }
  Future<void> postStockCheckItems() async {
    var db= await dbHelperStockCheckItems.db;

    final ApiServices api = ApiServices();
    try {
      final products = await db!.rawQuery('select * from Stock_Check_Items');
      var count = 0;
      if (products.isNotEmpty || products != null)  {  // Check if the table is not empty
        await db.transaction((txn) async {

        for(var i in products){
          if (kDebugMode) {
            print(i.toString());
          }
          count++;
          StockCheckItemsModel v =StockCheckItemsModel(
            id: "${i['id']}${i['shopvisitId']}".toString(),
            shopvisitId: i['shopvisitId'].toString(),
            itemDesc: i['itemDesc'].toString(),
            qty: i['qty'].toString(),
          );
          var result1 = await api.masterPost(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/shopvisit/post/');
          var result = await api.masterPost(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/shopvisit/post/');
          if(result == true && result1 == true){
            txn.rawQuery('DELETE FROM Stock_Check_Items WHERE id = ${i['id']}');
          }
        }});
      } }catch (e) {
      if (kDebugMode) {
        print("ErrorRRRRRRRRR: $e");
      }
      return;
    }
  }

  // Future<void> addStockCheckItems(StockCheckItemsModel stockCheckItemsList) async {
  //   final db = await dbHelperStockCheckItems.db;
  //   for (var stockCheckItems in stockCheckItemsList) {
  //     await db?.insert('Stock_Check_Items',stockCheckItems.toMap());
  //   }
  // }

  Future<int> add(StockCheckItemsModel stockcheckitemsModel) async {
    var dbClient = await dbHelperStockCheckItems.db;
    return await dbClient!.insert('Stock_Check_Items', stockcheckitemsModel.toMap());
  }

  Future<int> update(StockCheckItemsModel stockcheckitemsModel) async {
    var dbClient = await dbHelperStockCheckItems.db;
    return await dbClient!.update('Stock_Check_Items', stockcheckitemsModel.toMap(),
        where: 'id = ?', whereArgs: [stockcheckitemsModel.id]);
  }

  Future<int> delete(int id) async {
    var dbClient = await dbHelperStockCheckItems.db;
    return await dbClient!.delete('Stock_Check_Items',
        where: 'id = ?', whereArgs: [id]);
  }
}