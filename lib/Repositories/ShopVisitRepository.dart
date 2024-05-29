
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../API/ApiServices.dart';
import '../Databases/DBHelper.dart';
import '../Models/ShopVisitModels.dart';

class ShopVisitRepository {

  DBHelper dbHelpershopvisit = DBHelper();

  Future<List<ShopVisitModel>> getShopVisit() async {
    var dbClient = await dbHelpershopvisit.db;
    List<Map> maps = await dbClient!.query('shopVisit', columns: ['id','date', 'shopName','userId', 'city' , 'bookerName' , 'brand' ,'walkthrough', 'planogram' , 'signage', 'productReviewed','feedback','longitude','latitude','address', 'body']);
    List<ShopVisitModel> shopvisit = [];

    for (int i = 0; i < maps.length; i++) {
      shopvisit.add(ShopVisitModel.fromMap(maps[i]));
    }
    return shopvisit;
  }
  Future<void> postShopVisitData() async {
    var db = await dbHelpershopvisit.db;

    final ApiServices api = ApiServices();



    try {
      final products = await db!.rawQuery('''SELECT *, 
      CASE WHEN walkthrough = 1 THEN 'True' ELSE 'False' END AS walkthrough,
      CASE WHEN planogram = 1 THEN 'True' ELSE 'False' END AS planogram,
      CASE WHEN signage = 1 THEN 'True' ELSE 'False' END AS signage,
      CASE WHEN productReviewed = 1 THEN 'True' ELSE 'False' END AS productReviewed
      FROM shopVisit
      ''');
      await db.rawQuery('VACUUM');
      if (products.isNotEmpty || products != null)  {  // Check if the table is not empty
        await db.transaction((txn) async {

          for (Map<dynamic, dynamic> i in products) {
          if (kDebugMode) {
            print("FIRST $i");
          }

          ShopVisitModel v = ShopVisitModel(
            id: i['id'].toString(),
            date: i['date'].toString(),
            userId: i['userId'].toString(),
            shopName: i['shopName'].toString(),
            bookerName: i['bookerName'].toString(),
            brand: i['brand'].toString(),
            city: i['city'].toString(),
            walkthrough: i['walkthrough'].toString(),
            planogram: i['planogram'].toString(),
            signage: i['signage'].toString(),
            productReviewed: i['productReviewed'].toString(),
            feedback: i['feedback'].toString(),
            latitude: i['latitude'].toString(),
            longitude: i['longitude'].toString(),
            address: i['address'].toString(),
            body: i['body'] != null && i['body'].toString().isNotEmpty
                ? Uint8List.fromList(base64Decode(i['body'].toString()))
                : Uint8List(0),

          );

          // Print image path before trying to create the file
          if (kDebugMode) {
            print("Image Path from Database: ${i['body']}");
          }
          if (kDebugMode) {
            print("lat:${i['latitude']}");
          }

          // Declare imageBytes outside the if block
          Uint8List imageBytes;
          final directory = await getApplicationDocumentsDirectory();
          final filePath = File('${directory.path}/captured_image.jpg');
          if (filePath.existsSync()) {
            // File exists, proceed with reading the file
            List<int> imageBytesList = await filePath.readAsBytes();
            imageBytes = Uint8List.fromList(imageBytesList);
          } else {
            if (kDebugMode) {
              print("File does not exist at the specified path: ${filePath.path}");
            }
            continue; // Skip to the next iteration if the file doesn't exist
          }
          // Print information before making the API request
          if (kDebugMode) {
            print("Making API request for shop visit ID: ${v.id}");
          }
          var result1 = await api.masterPostWithImage(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/report/post/', imageBytes,);
          var result = await api.masterPostWithImage(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/report/post/', imageBytes,);
          if (result == true && result1 == true) {
            await txn.rawQuery('DELETE FROM shopVisit WHERE id = ${i['id']}');
            if (kDebugMode) {
              print("Successfully posted data for shop visit ID: ${v.id}");
            }
          }
          else {
            if (kDebugMode) {
              print("Failed to post data for shop visit ID: ${v.id}");
            }
          }
        }
      });}
    } catch (e) {
      if (kDebugMode) {
        print("Error processing shop visit data: $e");
      }
      return;
    }
  }
  Future<String> getLastid() async {
    var dbClient = await dbHelpershopvisit.db;
    List<Map> maps = await dbClient!.query(
      'shopVisit',
      columns: ['id'],
      orderBy: 'Id DESC',
      limit: 1,
    );
    if (maps.isEmpty) {
      // Handle the case when no records are found
      return "";
    }

    // Convert the orderId to a string and return
    return maps[0]['id'].toString();
  }

    Future<int> add(ShopVisitModel shopvisitModel) async {
      var dbClient = await dbHelpershopvisit.db;
      return await dbClient!.insert('shopVisit', shopvisitModel.toMap());
    }

  // Future<void> addShopVisit(ShopVisitModel shopVisit) async {
  //   final db = await dbHelpershopvisit.db;
  //   try {
  //     // Convert image file to bytes
  //     List<int> imageBytesList = await getImageBytesFromPath(shopVisit.body);
  //     Uint8List imagePathBytes = Uint8List.fromList(imageBytesList);
  //
  //     await db?.insert(
  //       'shopVisit',
  //       {
  //         'id': shopVisit.id,
  //         'date': shopVisit.date,
  //         'shopName': shopVisit.shopName,
  //         'bookerName': shopVisit.bookerName,
  //         'brand': shopVisit.brand,
  //         'walkthrough': shopVisit.walkthrough,
  //         'planogram': shopVisit.planogram,
  //         'signage': shopVisit.signage,
  //         'productReviewed': shopVisit.productReviewed,
  //         'body': imagePathBytes, // Store image data in the 'body' column as BLOB
  //         'feedback': shopVisit.feedback,
  //       },
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   } catch (e) {
  //     print('Error adding shop visit: $e');
  //   }
  // }

  // Future<List<int>> getImageBytesFromPath(String? imagePath) async {
  //   if (imagePath != null && imagePath.isNotEmpty) {
  //     io.File imageFile = io.File(imagePath);
  //     return await imageFile.readAsBytes();
  //   }
  //   return [];
  // }

    Future<int> update(ShopVisitModel shopvisitModel) async {
      var dbClient = await dbHelpershopvisit.db;
      return await dbClient!.update('shopVisit', shopvisitModel.toMap(),
          where: 'id=?', whereArgs: [shopvisitModel.id]);
    }

    Future<int> delete(int id) async {
      var dbClient = await dbHelpershopvisit.db;
      return await dbClient!.delete('shopVisit',
          where: 'id=?', whereArgs: [id]);
    }

  }