

import 'package:flutter/foundation.dart';

import '../API/ApiServices.dart';
import '../Databases/DBHelper.dart';
import '../Models/RecoveryFormModel.dart';

class RecoveryFormRepository{

  DBHelper dbHelperRecoveryForm = DBHelper();

  Future<List<RecoveryFormModel>> getRecoveryForm() async{
    var dbClient = await dbHelperRecoveryForm.db;
    List<Map> maps = await dbClient!.query('recoveryForm',columns: ['recoveryId','date','shopName','netBalance',' userId', 'bookerName', 'city', 'brand' ]);
    List<RecoveryFormModel> recoveryform = [];
    for(int i = 0; i<maps.length; i++)
    {
      recoveryform.add(RecoveryFormModel.fromMap(maps[i]));
    }
    return recoveryform;
  }
  Future<void> postRecoveryFormTable() async {
    var db = await dbHelperRecoveryForm.db;
    final ApiServices api = ApiServices();

    try {
      final products = await db!.rawQuery('select * from recoveryForm');
      if (products.isNotEmpty || products != null)  { // Check if the table is not empty
        await db.transaction((txn) async {

        for (var i in products) {
          if (kDebugMode) {
            print("FIRST ${i.toString()}");
          }

          RecoveryFormModel v = RecoveryFormModel(
            recoveryId: i['recoveryId'].toString(),
            shopName: i['shopName'].toString(),
            date: i['date'].toString(),
            cashRecovery: i['cashRecovery'].toString(),
            netBalance: i['netBalance'].toString(),
            userId: i['userId'].toString(),
            bookerName: i['bookerName'].toString(),
            city: i['city'].toString(),
            brand: i['brand'].toString(),
          );

          var result1 = await api.masterPost(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/recoveryform/post/',);
          var result = await api.masterPost(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/recoveryform/post/',);

          if (result == true&& result1 == true){
            txn.rawQuery(
                "DELETE FROM recoveryForm WHERE recoveryId = '${i['recoveryId']}'");
          }
        }
      });}
    }catch (e) {
      if (kDebugMode) {
        print("ErrorRRRRRRRRR: $e");
      }
      return;
    }
  }
  //
  // Future<String> getLastId() async {
  //   var dbClient = await dbHelperReturnForm.db;
  //   List<Map> maps = await dbClient.query(
  //     'returnForm',
  //     columns: ['returnId'],
  //     orderBy: 'returnId DESC',
  //     limit: 1,
  //   );
  //
  //   if (maps.isEmpty) {
  //     // Handle the case when no records are found
  //     return "";
  //   }
  //
  //   // Convert the orderId to a string and return
  //   return maps[0]['returnId'].toString();
  // }


  Future<int> add(RecoveryFormModel  recoveryform) async{
    var dbClient = await dbHelperRecoveryForm.db;
    return await dbClient!.insert('recoveryForm',  recoveryform.toMap());
  }

  Future<int> update(RecoveryFormModel  recoveryform) async{
    var dbClient = await dbHelperRecoveryForm.db;
    return await dbClient!.update('recoveryForm', recoveryform.toMap(),
        where: 'recoveryForm = ?', whereArgs: [ recoveryform.recoveryId]);
  }


  Future<int> delete(int recoveryId) async{
    var dbClient = await dbHelperRecoveryForm.db;
    return await dbClient!.delete('recoveryForm',
        where: 'recoveryId = ?', whereArgs: [recoveryId]);
  }




}

