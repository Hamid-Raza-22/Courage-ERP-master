
import 'package:flutter/foundation.dart';

import '../../API/ApiServices.dart';
import '../../Databases/DBHelper.dart';
import '../../Models/ReturnFormDetails.dart';

class ReturnFormDetailsRepository {

  DBHelper dbHelperReturnFormDetails = DBHelper();

  Future<List<ReturnFormDetailsModel>> getReturnFormDetails() async {
    var dbClient = await dbHelperReturnFormDetails.db;
    List<Map> maps = await dbClient!.query('return_form_details', columns: ['id','returnformId', 'productName', 'quantity','bookerId', 'reason']);
    List<ReturnFormDetailsModel> returnformdetails = [];
    for (int i = 0; i < maps.length; i++) {

      returnformdetails.add(ReturnFormDetailsModel.fromMap(maps[i]));
    }
    return returnformdetails;
  }
  Future<void> postReturnFormDetails() async {
    var db= await dbHelperReturnFormDetails.db;
    final ApiServices api = ApiServices();
    try {
      final products = await db!.rawQuery('select * from return_form_details');
      var count = 0;
      if (products.isNotEmpty || products != null)  {  // Check if the table is not empty
        await db.transaction((txn) async {

        for(var i in products){
          if (kDebugMode) {
            print(i.toString());
          }
          count++;
          ReturnFormDetailsModel v = ReturnFormDetailsModel(
            id: "${i['id']}".toString(),
            returnformId: i['returnFormId'].toString(),
            productName: i['productName'].toString(),
            reason: i['reason'].toString(),
            quantity: i['quantity'].toString(),
            bookerId: i['bookerId'].toString(),
          );
          final result1 = await api.masterPost(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/returnformdetail/post');
          final result = await api.masterPost(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/returnformdetail/post');
          if(result == true && result1 == true){
            txn.rawQuery('DELETE FROM return_form_details WHERE id = ${i['id']}');
          }
        }});
      }
      } catch (e) {
      if (kDebugMode) {
        print("ErrorRRRRRRRRR: $e");
      }
      return;
    }
  }
  Future<int> add(ReturnFormDetailsModel returnformdetailsModel) async {
    var dbClient = await dbHelperReturnFormDetails.db;
    return await dbClient!.insert('return_form_details', returnformdetailsModel.toMap());
  }

  Future<int> update(ReturnFormDetailsModel returnformdetailsModel) async {
    var dbClient = await dbHelperReturnFormDetails.db;
    return await dbClient!.update('return_form_details',returnformdetailsModel.toMap(),
        where: 'id = ?', whereArgs: [returnformdetailsModel.id]);
  }

  Future<int> delete(int id) async {
    var dbClient = await dbHelperReturnFormDetails.db;
    return await dbClient!.delete('return_form_details',
        where: 'id = ?', whereArgs: [id]);
  }
}