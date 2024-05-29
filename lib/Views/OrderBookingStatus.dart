import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart' show AlertDialog, Align, Alignment, AppBar, Axis, BorderRadius, BorderSide, BoxConstraints, BuildContext, Card, Center, CircularProgressIndicator, Color, Colors, Column, ConnectionState, Container, CrossAxisAlignment, DataCell, DataColumn, DataRow, DataTable, DefaultTextStyle, EdgeInsets, ElevatedButton, Expanded, FontWeight, FutureBuilder, GestureDetector, Icon, Icons, InputDecoration, LayoutBuilder, ListTile, ListView, MainAxisAlignment, Navigator, OutlineInputBorder, RichText, RoundedRectangleBorder, Row, Scaffold, SingleChildScrollView, SizedBox, State, StatefulWidget, Text, TextButton, TextEditingController, TextFormField, TextSpan, TextStyle, Widget, WidgetState, WidgetStateProperty, showDatePicker, showDialog;
import 'package:flutter_typeahead/flutter_typeahead.dart' show TextFieldConfiguration, TypeAheadFormField;
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:sqflite/sqflite.dart' show Database;
import '../API/DatabaseOutputs.dart' show DatabaseOutputs;
import '../Databases/DBHelper.dart' show DBHelper;
import 'HomePage.dart';



class OrderBookingStatus extends StatefulWidget {
  const OrderBookingStatus({super.key});

  @override
  OrderBookingStatusState createState() => OrderBookingStatusState();
}

class OrderBookingStatusState extends State<OrderBookingStatus> {
  TextEditingController shopController = TextEditingController();
  TextEditingController orderController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController totalAmountController = TextEditingController();
  List<String> dropdownItems = [];
  String selectedItem = '';
  String selectedOrderNo = '';
  List<String> dropdownItems2 = [];
  String selectedShopOwner = '';
  String selectedOwnerContact = '';
  List<Map<String, dynamic>> shopOwners = [];
  DBHelper dbHelper = DBHelper();
  DBHelper dbHelper1 = DBHelper();
  //DBOrderMasterGet dbHelper1 = DBOrderMasterGet();

  String selectedOrderNoFilter = '';
  String selectedShopFilter = '';
  String selectedStatusFilter = '';

  Future<void> _selectDate(
      BuildContext context, TextEditingController dateController) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      String formattedDate = DateFormat('dd-MMM-yyyy').format(pickedDate);
      dateController.text = formattedDate;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchShopData();
    fetchOrderNumbers();
    onCreatee();
  }
  // Future<void> onCreatee() async {
  //
  //   DatabaseOutputs outputs = DatabaseOutputs();
  //   outputs.checkFirstRun();
  // }

  Future<void> onCreatee() async {
    DatabaseOutputs db = DatabaseOutputs();
    await db.showOrderDispacthed();
    await db.showOrderMaster();
   // await db.showOrderDetailsData();
    await db.showOrderDetails();

    // DatabaseOutputs outputs = DatabaseOutputs();
    // outputs.checkFirstRun();

  }

  void clearFilters() {
    setState(() {
      selectedShopFilter = '';
      selectedOrderNoFilter = '';
      selectedStatusFilter = '';
      shopController.clear();
      orderController.clear();
      statusController.clear();
      startDateController.clear();
      endDateController.clear();
      selectedOrderNo = ''; // Clear the selected order number
      selectedItem = ''; // Clear the selected shop
    });
  }

  // void fetchOrderNumbers() async {
  //   List<Map<String, dynamic>> orderNumbers =
  //       await dbHelper.getOrderBookingStatusDB() ?? [];
  //   setState(() {
  //     dropdownItems2 =
  //         orderNumbers.map((map) => map['order_no'].toString()).toSet().toList();
  //   });
  // }


  void fetchOrderNumbers() async {
    List<String> orderNo = await dbHelper1.getOrderMasterOrderNo();
    shopOwners = (await dbHelper1.getOrderMasterDB())!;

    // Remove duplicates from the shopNames list
    List<String> uniqueShopNames = orderNo.toSet().toList();

    setState(() {
      dropdownItems2 = uniqueShopNames;
    });
  }


  //
  void fetchShopData() async {
    List<String> shopNames = await dbHelper.getOrderMasterShopNames2();
    shopOwners = (await dbHelper.getOrderMasterDB())!;

    setState(() {
      dropdownItems = shopNames.toSet().toList();
    });
  }
  Future<List<Map<String, dynamic>>> fetchOrderBookingStatusData() async {
    //List<Map<String, dynamic>> data = await dbHelper.getOrderMasterDB() ?? [];
    List<Map<String, dynamic>> data = await dbHelper.getOrderBookingStatusDB()?? [];


    // Apply the filters
    if (selectedOrderNoFilter.isNotEmpty) {
      data = data.where((row) => row['order_no'] == selectedOrderNoFilter).toList();
    }
// Filter by date range
    if (startDateController.text.isNotEmpty && endDateController.text.isNotEmpty) {
      DateTime startDate = DateFormat('dd-MMM-yyyy').parse(startDateController.text);
      DateTime endDate = DateFormat('dd-MMM-yyyy').parse(endDateController.text);

      data = data.where((row) {
        DateTime orderDate = DateFormat('dd-MMM-yyyy').parse(row['order_date']);
        return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }


    if (selectedShopFilter.isNotEmpty) {
      data = data.where((row) => row['shop_name'] == selectedShopFilter).toList();
    }

    if (selectedStatusFilter.isNotEmpty) {
      // Check if the status filter is "All", if not, filter by status
      data = data.where((row) => row['status'] == selectedStatusFilter).toList();
    }

    // Check if shop field is empty, reset shop filter
    if (selectedShopFilter.isEmpty) {
      selectedShopFilter = '';
    }

    // Check if status field is empty, reset status filter
    if (statusController.text.isEmpty) {
      selectedStatusFilter = '';
    }

    // Check if order field is empty, reset order filter
    if (selectedOrderNoFilter.isEmpty) {
      selectedOrderNoFilter = '';
    }

    return data;
  }

// List<int> selectedIndexes = [];  // Add this line at the beginning of your widget


  Future<List<DataRow>> buildDataRows(List<Map<String, dynamic>> data) async {
    data = data.reversed.toList();
    Set<String> uniqueOrderNumbers = <String>{}; // Set to keep track of unique order numbers
    List<DataRow> rows = [];

    await Future.forEach(data, (map) async {
      final Database? db = await DBHelper().db;
      List<Map<String, dynamic>> statusRows = await db!.query('orderBookingStatusData', where: 'order_no = ?', whereArgs: [map['order_no']]);
      String status = statusRows.isNotEmpty ? statusRows.first['status'] : 'N/A';


      // Check if the current order_no is unique
      if (!uniqueOrderNumbers.contains(map['order_no'])) {
        uniqueOrderNumbers.add(map['order_no']);
        rows.add(
          DataRow(
            color: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (status == 'DISPATCHED') return Colors.greenAccent; // Set the color to green if the status is 'DISPATCHED'
              if (status == 'PENDING') return Colors.transparent;
              if (status == 'N/A') return Colors.yellowAccent;
              return Colors.transparent; // Use the default color for other statuses
            }),
            cells: [
              DataCell(Text(map['order_no'].toString())),
              DataCell(Text(map['order_date'].toString())),
              DataCell(Text(map['shop_name'].toString())),
              DataCell(Text(map['amount'].toString())),
              DataCell(
                status == 'N/A'
                    ? const Icon(Icons.sync, color: Colors.green) // Sync logo for 'N/A' status
                    : Text(status), // Use the status variable here
              ), // Use the status variable here
              DataCell(
                GestureDetector(
                  onTap: () async {
                    final Database? db = await DBHelper().db;
                    List<Map<String, dynamic>> queryRows = await db!.query('orderDetailsData', where: 'order_no = ?', whereArgs: [map['order_no']]);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Order Details'),
                          content: ListView.builder(
                            itemCount: queryRows.length,
                            itemBuilder: (context, index) {
                              return RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    const TextSpan(text: 'Sr. No: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${index + 1}\n'), // Add serial number here
                                    const TextSpan(text: 'Product Name: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${queryRows[index]['product_name']}\n'),
                                    const TextSpan(text: 'Quantity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${queryRows[index]['quantity_booked']}\n'),
                                    const TextSpan(text: 'Unit Price: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${queryRows[index]['price']}\n'),
                                  ],
                                ),
                              );
                            },
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                // Get.to(const HomePage());
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text(
                    'Order Details',
                    style: TextStyle(
                      color: Colors.blue, //decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });

    return rows;
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text('Order Booking Status'),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double screenWidth = constraints.maxWidth;

            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        const Text(
                          'Shop: ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 50,
                                width: screenWidth * 0.4,
                                padding: const EdgeInsets.all(8.0),
                                child: TypeAheadFormField(
                                  textFieldConfiguration: TextFieldConfiguration(
                                      controller: TextEditingController(text: selectedItem),
                                      decoration: const InputDecoration(
                                        hintText: 'Select Shop',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.all(10),
                                      ), style: const TextStyle(fontSize: 12)
                                  ),
                                  suggestionsCallback: (pattern) {
                                    return dropdownItems
                                        .where((item) =>
                                        item.toLowerCase().contains(pattern.toLowerCase()))
                                        .toList();
                                  },  itemBuilder: (context, suggestion) {
                                  return ListTile(
                                    title: Text(
                                      suggestion,
                                      style: const TextStyle(fontSize: 10), // Adjust the font size here
                                    ),
                                  );
                                },
                                  onSuggestionSelected: (suggestion) {
                                    setState(() {
                                      selectedItem = suggestion;
                                      selectedOrderNoFilter = ''; // Clear the order number filter
                                      selectedShopFilter = suggestion; // Update the shop filter
                                      if (kDebugMode) {
                                        print('Selected Shop: $selectedItem');
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Order:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 50,
                                width: screenWidth * 0.4,
                                padding: const EdgeInsets.all(8.0),
                                child: TypeAheadFormField(
                                  textFieldConfiguration: TextFieldConfiguration(
                                      controller: TextEditingController(text: selectedOrderNo),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.all(10),
                                      ),style: const TextStyle(fontSize: 12)
                                  ),
                                  suggestionsCallback: (pattern) {
                                    return dropdownItems2
                                        .where((order) =>
                                        order.toLowerCase().contains(pattern.toLowerCase()))
                                        .toList();
                                  },  itemBuilder: (context, suggestion) {
                                  return ListTile(
                                    title: Text(
                                      suggestion,
                                      style: const TextStyle(fontSize: 10), // Adjust the font size here
                                    ),
                                  );
                                },
                                  onSuggestionSelected: (suggestion) {
                                    setState(() {
                                      selectedOrderNo = suggestion;
                                      selectedOrderNoFilter = suggestion; // Update the filter
                                    });
                                  },
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                        return 'Please enter digits only';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        const Text(
                          'Date Range:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 50,
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: startDateController,
                                  onTap: () async {
                                    await _selectDate(
                                        context, startDateController);
                                  },
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontFamily: 'YourFontFamily',
                                  ),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'to',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: endDateController,
                              onTap: () async {
                                await _selectDate(context, endDateController);
                              },
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: 'YourFontFamily',
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 50,
                                width: screenWidth * 0.4,
                                padding: const EdgeInsets.all(8.0),
                                child: TypeAheadFormField(
                                  textFieldConfiguration: TextFieldConfiguration(
                                    controller: statusController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(10),
                                    ),
                                  ),
                                  suggestionsCallback: (pattern) {
                                    return ['DISPATCHED', 'RESCHEDULE', 'CANCELED', 'PENDING']
                                        .where((status) =>
                                        status.toLowerCase().contains(
                                            pattern.toLowerCase()))
                                        .toList();
                                  },
                                  itemBuilder: (context, suggestion) {
                                    return ListTile(
                                      title: Text(suggestion),
                                    );
                                  },
                                  onSuggestionSelected: (suggestion) {
                                    setState(() {
                                      statusController.text = suggestion;
                                      selectedStatusFilter = suggestion; // Update the status filter
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ), Container(
                          margin: const EdgeInsets.all(9.0), // Adjust the margin as needed
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () {
                              clearFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              elevation: 8.0,
                            ),
                            child: Container(
                              height: 30.0,
                              width: 70.0,
                              alignment: Alignment.center,
                              child: const Text('Clear Filters', style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ),
                        )



                      ],

                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0.0,
                      margin: const EdgeInsets.all(5.0),
                      child: SizedBox(
                        height: 420.0, // Set the desired height for the card
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchOrderBookingStatusData(),
            builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
            } else {
            return FutureBuilder<List<DataRow>>(
            future: buildDataRows(snapshot.data ?? []),
            builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
            } else {
            return DataTable(
            columns: const [
            DataColumn(label: Text('Order No')),
            DataColumn(label: Text('Order Date')),
            DataColumn(label: Text('Shop Name')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Details')),
            ],
            rows: snapshot.data!,
            );
            }
            },
            );
            }
            },
            ),
            ),

                        ),
                      ),
                    ),

                    // SizedBox(height: 50),
                    // Align(
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.end,
                    //     children: [
                    //       Text(
                    //         'Total Amount',
                    //         style: TextStyle(fontSize: 16, color: Colors.black),
                    //       ),
                    //       SizedBox(width: 10),
                    //       Container(
                    //         height: 30,
                    //         width: 170,
                    //         child: TextFormField(
                    //           enabled: false,
                    //           controller: totalAmountController,
                    //           decoration: InputDecoration(
                    //             border: OutlineInputBorder(
                    //               borderRadius: BorderRadius.circular(5.0),
                    //             ),
                    //           ),
                    //           textAlign: TextAlign.right,
                    //           validator: (value) {
                    //             if (value!.isEmpty) {
                    //               return 'Please enter some text';
                    //             }
                    //             return null;
                    //           },
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 10
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                          elevation: 8.0,
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

    );
    }
}