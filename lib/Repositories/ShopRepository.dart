import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:order_booking_shop/Databases/DBHelper.dart';

import 'package:order_booking_shop/Models/ShopModel.dart';
import 'package:path_provider/path_provider.dart';

import '../API/ApiServices.dart';


class ShopRepository {

  DBHelper dbHelper = DBHelper();

  Future<List<ShopModel>> getShop() async {
    var dbClient = await dbHelper.db;
    List<Map> maps = await dbClient!.query('shop', columns: ['id', 'shopName' , 'city' ,'date', 'shopAddress' , 'ownerName' , 'ownerCNIC' , 'phoneNo' , 'alternativePhoneNo', 'latitude', 'longitude','userId','posted','body']);
    List<ShopModel> shop = [];

    for (int i = 0; i < maps.length; i++) {
      shop.add(ShopModel.fromMap(maps[i]));
    }
    return shop;
  }
  Future<void> postShopTable() async {
    var dbClient = await dbHelper.db;
    //final Database db = await initDatabase();
    final ApiServices api = ApiServices();

    try {
      final List<Map<String, dynamic>> records = await dbClient!.query('shop');

      // Print each record
      for (var record in records) {
        if (kDebugMode) {
          print(record.toString());
        }
      }
      // Select only the records that have not been posted yet
      final products = await dbClient.rawQuery('SELECT * FROM shop WHERE posted = 0');
      if (products.isNotEmpty) {
        await dbClient.transaction((txn) async {
// Check if the table is not empty
        for (var i in products) {
          if (kDebugMode) {
            print("FIRST ${i.toString()}");
          }


          ShopModel v = ShopModel(
            id: "${i['id']}",
            shopName: i['shopName'].toString(),
            city: i['city'].toString(),
            date: i['date'].toString(),
            shopAddress: i['shopAddress'].toString(),
            ownerName: i['ownerName'].toString(),
            ownerCNIC: i['ownerCNIC'].toString(),
            phoneNo: i['phoneNo'].toString(),
            alternativePhoneNo: i['alternativePhoneNo'].toString(),
            latitude: i['latitude'].toString(),
            longitude: i['longitude'].toString(),
            userId: i['userId'].toString(),
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
          https://apex.oracle.com/pls/apex/metaa/addshop/post/
          http://103.149.32.30:8080/ords/metaxperts/addshop/post/
          var result1 = await api.masterPostWithImage(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/addshops/post/', imageBytes,);
          var result = await api.masterPostWithImage(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/addshops/post/', imageBytes,);
          if (result == true && result1 == true) {
            await txn.rawQuery('DELETE FROM shop WHERE id = ${i['id']}');
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
  Future<int> add(ShopModel shopModel) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.insert('shop' , shopModel.toMap());
  }

  Future<int> update(ShopModel shopModel) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.update('shop', shopModel.toMap(),
        where: 'id=?', whereArgs: [shopModel.id] );
  }

  Future<int> delete(int id) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.delete('shop',
        where: 'id=?', whereArgs: [id] );
  }
  Future<List<ShopModel>> getShopNames() async {
    var dbClient = await dbHelper.db;
    List<Map> maps = await dbClient!.query('shop', columns: ['shopName']);

    // Extracting shop names from the list of maps
    List<ShopModel> shopNames = maps.map((map) => map['shopName'].toString()).cast<ShopModel>().toList();

    return shopNames;
  }
  Future<List<ShopModel>> getShopName() async {
    var dbClient = await dbHelper.db;
    List<Map> maps = await dbClient!.query('shop', columns: ['shopName']);
    List<ShopModel> shop = [];

    for (int i = 0; i < maps.length; i++) {
      shop.add(ShopModel.fromMap(maps[i]));
    }
    return shop;
  }
  Future<String> getLastid() async {
    var dbClient = await dbHelper.db;
    List<Map> maps = await dbClient!.query(
      'shop',
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

}



