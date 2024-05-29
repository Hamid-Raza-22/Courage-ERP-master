

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../API/ApiServices.dart';
import '../Databases/DBHelper.dart';
import '../Models/AttendanceModel.dart';
import '../location00.dart';

class AttendanceRepository {

  DBHelper dbHelper = DBHelper();

  Future<List<AttendanceModel>> getAttendance() async {
    var dbClient = await dbHelper.db;
    List<Map> maps = await dbClient!.query('attendance', columns: ['id', 'date' , 'timeIn' , 'userId' , 'latIn' , 'lngIn','bookerName','city','designation' ]);
    List<AttendanceModel> attendance = [];

    for (int i = 0; i < maps.length; i++) {
      attendance.add(AttendanceModel.fromMap(maps[i]));
    }
    return attendance;
  }
  Future<void> postAttendanceTable() async {
    var db = await dbHelper.db;
    final ApiServices api = ApiServices();

    try {
      final products = await db!.rawQuery('select * from attendance');

      if (products.isNotEmpty) {
        await db.transaction((txn) async {
          for (var i in products) {
            if (kDebugMode) {
              print("Posting attendance for ${i['id']}");
            }

            AttendanceModel v = AttendanceModel(
              id: i['id'].toString(),
              date: i['date'].toString(),
              userId: i['userId'].toString(),
              timeIn: i['timeIn'].toString(),
              latIn: i['latIn'].toString(),
              lngIn: i['lngIn'].toString(),
              bookerName: i['bookerName'].toString(),
              city: i['city'].toString(),
              designation: i['designation'].toString(),
            );

            var result = await api.masterPost(
              v.toMap(),
              'http://103.149.32.30:8080/ords/metaxperts/attendance/post/',

            );

            var result1 = await api.masterPost(
              v.toMap(),
              'https://apex.oracle.com/pls/apex/metaxpertss/attendance/post/',
            );

            if (result == true && result1 == true) {
              if (kDebugMode) {
                print('successfully post');
              }
              await txn.rawDelete(
                  "DELETE FROM attendance WHERE id = '${i['id']}'");
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
  // Future<List<AttendanceModel>> getShopName() async {
  //   var dbClient = await dbHelper.db;
  //   List<Map> maps = await dbClient!.query('shop', columns: ['id', 'shopName']);
  //   List<AttendanceModel> shop = [];
  //
  //   for (int i = 0; i < maps.length; i++) {
  //     shop.add(AttendanceModel.fromMap(maps[i]));
  //   }
  //   return shop;
  // }

  //
  // Future<String> getLastid() async {
  //   var dbClient = await dbHelper.db;
  //   List<Map> maps = await dbClient!.query(
  //     'shop',
  //     columns: ['id'],
  //     orderBy: 'Id DESC',
  //     limit: 1,
  //   );
  //   if (maps.isEmpty) {
  //     // Handle the case when no records are found
  //     return "";
  //   }
  //
  //   // Convert the orderId to a string and return
  //   return maps[0]['id'].toString();
  // }


  Future<List<AttendanceOutModel>> getAttendanceOut() async {
    var dbClient = await dbHelper.db;
    List<Map> maps = await dbClient!.query('attendanceOut', columns: ['id', 'date' , 'timeOut' ,'totalTime', 'userId' , 'latOut', 'lngOut','totalDistance', 'posted']);
    List<AttendanceOutModel> attendanceout = [];

    for (int i = 0; i < maps.length; i++) {
      attendanceout.add(AttendanceOutModel.fromMap(maps[i]));
    }
    return attendanceout;
  }
  Future<void> postAttendanceOutTable() async {
    var db = await dbHelper.db;

    final ApiServices api = ApiServices();
    try {
      final products = await db!.rawQuery('select * from attendanceOut');

      if (products.isNotEmpty || products != null) {  // Check if the table is not empty
        await db.transaction((txn) async {
        for (var i in products) {
          if (kDebugMode) {
            print("FIRST ${i.toString()}");
          }

          AttendanceOutModel v = AttendanceOutModel(
              id: i['id'].toString(),
              date: i['date'].toString(),
              userId: i['userId'].toString(),
              timeOut: i['timeOut'].toString(),
              totalTime: i['totalTime'].toString(),
              latOut: i['latOut'].toString(),
              lngOut: i['lngOut'].toString(),
              totalDistance:i['totalDistance'].toString()
          );
           var result1 = await api.masterPost(v.toMap(), 'http://103.149.32.30:8080/ords/metaxperts/attendanceout/post/');
        //  var result1 = await api.masterPost(v.toMap(), 'https://webhook.site/3f874f5d-2d23-493b-a3a0-855f77ded7fb');
          var result = await api.masterPost(v.toMap(), 'https://apex.oracle.com/pls/apex/metaxpertss/attendanceout/post/',);

          if (result == true && result1 == true) {
            if (kDebugMode) {
              print('successfully post');
            }
            await txn.rawDelete("DELETE FROM attendanceOut WHERE id = '${i['id']}'");
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
  Future<int> addOut(AttendanceOutModel attendanceoutModel) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.insert('attendanceOut' , attendanceoutModel.toMap());
  }

  Future<int> add(AttendanceModel attendanceModel) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.insert('attendance' , attendanceModel.toMap());
  }

  Future<int> update(AttendanceModel attendanceModel) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.update('attendance', attendanceModel.toMap(),
        where: 'id= ?', whereArgs: [attendanceModel.id] );
  }

  Future<int> delete(int id) async{
    var dbClient = await dbHelper.db;
    return await dbClient!.delete('attendance',
        where: 'id=?', whereArgs: [id] );
  }


}



