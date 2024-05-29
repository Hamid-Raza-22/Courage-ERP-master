import 'dart:convert' show base64Decode, base64Encode;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:order_booking_shop/API/Globals.dart';
import 'package:order_booking_shop/Databases/DBHelper.dart';
import 'package:order_booking_shop/Models/ShopModel.dart';
import 'package:order_booking_shop/Repositories/ShopRepository.dart';
import 'package:path_provider/path_provider.dart';

import '../API/ApiServices.dart';


class ShopViewModel extends GetxController{

  var allShop = <ShopModel>[].obs;
  ShopRepository shopRepository = ShopRepository();
  DBHelper database = DBHelper();



  @override
  void onInit() {
    super.onInit();
    fetchAllShop();
  }

  fetchAllShop() async {
    var shop = await shopRepository.getShop();
    allShop.value= shop;


  }

  Future<String> fetchLastShopId() async{
    String shopvisit = await shopRepository.getLastid();
    return shopvisit;
  }

  Future<void> addShop(ShopModel shopModel) async {
    await shopRepository.add(shopModel);
    // Convert image to base64 string
    String base64Image = '';
    if (shopModel.body != null) {
      base64Image = base64Encode(shopModel.body!);
    }
    // Implementing logic to insert data into 'ownerData' table
    var dbClient = await shopRepository.dbHelper.db;
    await dbClient!.insert('ownerData', {
      'id': shopModel.id,
      'shop_name': shopModel.shopName,
      'owner_name': shopModel.ownerName,
      'phone_no': shopModel.phoneNo,
      'city': shopModel.city,
      'shop_address': shopModel.shopAddress,
      'user_id':shopModel.userId,
     // 'created_date':
      'images': base64Image
    });

    await fetchAllShop();
  }

  updateShop(ShopModel shopModel){
    shopRepository.update(shopModel);
    // fetchAllShop();

  }

  deleteShop(int id){
    shopRepository.delete(id);
    fetchAllShop();

  }
  postShop(){
    shopRepository.postShopTable();
  }

}






