
import 'package:flutter/foundation.dart';

import '../../API/ApiServices.dart';
import '../../Databases/DBHelper.dart';
import '../../Models/ReturnFormModel.dart';


class ReturnFormRepository{

  DBHelper dbHelperReturnForm = DBHelper();

  Future<List<ReturnFormModel>> getReturnForm() async{
    var dbClient = await dbHelperReturnForm.db;
    List<Map> maps = await dbClient!.query('returnForm',columns: ['returnId','date','shopName', 'returnAmount','bookerId', 'bookerName', 'city', 'brand' ]);
    List<ReturnFormModel> returnform = [];
    for(int i = 0; i<maps.length; i++)
    {
      returnform.add(ReturnFormModel.fromMap(maps[i]));
    }
    return returnform;
  }
  Future<void> postReturnFormTable() async {
    var db = await dbHelperReturnForm.db;
    final ApiServices api = ApiServices();

    try {
      final products = await db!.rawQuery('select * from returnForm');
      if (products.isNotEmpty || products != null)  {  // Check if the table is not empty
        await db.transaction((txn) async {

        for (var i in products) {
          if (kDebugMode) {
            print("FIRST ${i.toString()}");
          }

          ReturnFormModel v =  ReturnFormModel(
            returnId: i['returnId'].toString(),
            shopName: i['shopName'].toString(),
            date: i['date'].toString(),
            returnAmount: i['returnAmount'].toString(),
            bookerId: i['bookerId'].toString(),
            bookerName: i['bookerName'].toString(),
            city: i['city'].toString(),
            brand: i['brand'].toString(),
          );

          bool result1 = await api.masterPost(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/returnform/post/',);
          bool result = await api.masterPost(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/returnform/post/',);

          if (result == true && result1 == true) {
            txn.rawQuery("DELETE FROM returnForm WHERE returnId = '${i['returnId']}'");

          }
        }});
      }} catch (e) {
      if (kDebugMode) {
        print("ErrorRRRRRRRRR: $e");
      }
      return;
    }
  }

  Future<String> getLastId() async {
    var dbClient = await dbHelperReturnForm.db;
    List<Map> maps = await dbClient!.query(
      'returnForm',
      columns: ['returnId'],
      orderBy: 'returnId DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      // Handle the case when no records are found
      return "";
    }

    // Convert the orderId to a string and return
    return maps[0]['returnId'].toString();
  }


  Future<int> add(ReturnFormModel returnform) async{
    var dbClient = await dbHelperReturnForm.db;
    return await dbClient!.insert('returnForm', returnform.toMap());
  }

  Future<int> update(ReturnFormModel returnform) async{
    var dbClient = await dbHelperReturnForm.db;
    return await dbClient!.update('returnForm',returnform.toMap(),
        where: 'returnId = ?', whereArgs: [returnform.returnId]);
  }


  Future<int> delete(int returnId) async{
    var dbClient = await dbHelperReturnForm.db;
    return await dbClient!.delete('returnForm',
        where: 'returnId = ?', whereArgs: [returnId]);
  }




}

