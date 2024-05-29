import 'dart:io' show File;
import 'package:flutter/foundation.dart' show Uint8List, kDebugMode;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart' show Align, Alignment, BorderRadius, BuildContext, Colors, Column, CrossAxisAlignment, DropdownButton, DropdownMenuItem, EdgeInsets, ElevatedButton, Expanded, InputDecoration, MainAxisAlignment, MaterialPageRoute, ModalRoute, Navigator, OutlineInputBorder, Padding, RoundedRectangleBorder, Row, Scaffold, SingleChildScrollView, Size, SizedBox, State, StatefulWidget, Text, TextAlign, TextEditingController, TextFormField, TextStyle, Widget, WillPopScope;
import 'package:flutter/services.dart' show Size, TextAlign, Uint8List, rootBundle;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nanoid/nanoid.dart';
import 'package:order_booking_shop/API/Globals.dart';
import 'package:order_booking_shop/Views/HomePage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart' show Share;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/pdf.dart' show PdfColors;
import '../API/DatabaseOutputs.dart';
import '../Databases/DBHelper.dart';
import '../Models/OrderModels/OrderDetailsModel.dart';
import '../Models/OrderModels/OrderMasterModel.dart';
import '../View_Models/OrderViewModels/OrderDetailsViewModel.dart';
import '../View_Models/OrderViewModels/OrderMasterViewModel.dart';
import 'FinalOrderBookingPage.dart';


class OrderBooking2ndPage extends StatefulWidget {
  const OrderBooking2ndPage({super.key});

  @override
  OrderBooking2ndPageState createState() => OrderBooking2ndPageState();
}

class OrderBooking2ndPageState extends State<OrderBooking2ndPage> {
  final Productss productsController = Get.put(Productss());
  List<Map<String, dynamic>> rowDataDetails = [];
  bool isDataSavedInApex = true;
  bool isReConfirmButtonPressed = false;
  bool isOrderConfirmed = false;
  final ordermasterViewModel = Get.put(OrderMasterViewModel());
  final orderdetailsViewModel = Get.put(OrderDetailsViewModel());
  String currentUserId = '';
  int serialCounter = 1;
  String currentMonth = DateFormat('MMM').format(DateTime.now());
  final TextEditingController orderIDController = TextEditingController();
  String currentOrderId = '';
  DBHelper dbmaster = DBHelper();
  @override
  void initState() {
    super.initState();
    onCreatee();
  }


  Future<void> onCreatee() async {
    DatabaseOutputs db = DatabaseOutputs();
    await db.showOrderMaster();
    await db.showOrderDetails();
    await db.showShopVisit();
    await db.showStockCheckItems();
  }
  @override
  void dispose() {
    // Clear the data
    rowDataDetails.clear();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    if (kDebugMode) {
      print(orderMasterid);
    }
    final data =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // final orderId = data['orderId'];
    final orderDate = data['orderDate'];
    final user_name = data ['userName'];
    final shopName = data ['shopName'];
    final creditLimit = data['creditLimit'];
    // final discount = data['discount'];
    // final subTotal = data['subTotal'];
    final brand = data ['brand'];
    final ownerName= data['ownerName'];
    final phoneNo= data['phoneNo'];
    //  final total = data ['total'];
    final date = data ['date'];

    final requiredDelivery = data['requiredDelivery'];
    rowDataDetails = data['rowDataDetails'] as List<Map<String, dynamic>>;
    if (kDebugMode) {
      print(creditLimit);
    }
    // print(discount);
    // print(subTotal);
    if (kDebugMode) {
      print(requiredDelivery);
    }
    //orderMasterid= orderId;

    final selectedItems = <String>[];
    final quantities = <String>[];
    final rates = <String>[];
    final totalAmounts = <int>[];

    for (final rowData in rowDataDetails) {
      final selectedItem = rowData['selectedItem'] as String;
      final quantity = rowData['quantity'] as String;
      final rate = rowData['rate'] as String;
      final totalAmount = rowData['totalAmount'] as int;

      selectedItems.add(selectedItem);
      quantities.add(quantity);
      rates.add(rate);
      totalAmounts.add(totalAmount);
      // print('Rates: $rates');
    }

    final totalAmount =
    totalAmounts.fold<int>(0, (sum, amount) => sum + amount);

    return Scaffold(
        body:  WillPopScope(
          onWillPop: () async {
            // Check if the order is confirmed
            if (isOrderConfirmed) {
              // Order is confirmed, prevent going back
              return false;
            } else {

              return true;
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildSizedBox(30),
                  buildText('Order#'),
                  buildTextFormField(30, OrderMasterid, readOnly: true),
                  buildSizedBox(10),
                  buildText('Booker Name'),
                  buildTextFormField(30, user_name, readOnly: true),
                  buildSizedBox(10),
                  buildText('Order Date'),
                  buildTextFormField(30, orderDate.toString(), readOnly: true),
                  buildSizedBox(20),
                  buildHeading('Order Summary', 15),
                  buildSizedBox(10),
                  buildRow([
                    buildExpandedColumn('Description', 50, readOnly: true),
                    buildSizedBox(10),
                    buildExpandedColumn('Qty', 20, readOnly: true),
                    buildSizedBox(10),
                    buildExpandedColumn('Amount', 20, readOnly: true),
                  ]),
                  for (int i = 0; i < selectedItems.length; i++)
                    buildRow([
                      buildExpandedColumn(selectedItems[i], 50, readOnly: true),
                      buildSizedBox(10),
                      buildExpandedColumn(quantities[i].toString(), 20,
                          readOnly: true),
                      buildSizedBox(10),
                      buildExpandedColumn(totalAmounts[i].toString(), 20,
                          readOnly: true),
                    ]),
                  buildSizedBox(10),
                  buildRow([
                    buildText('Total                      '),
                    buildSizedBox(10),
                    buildExpandedColumn(totalAmount.toString(), 10, readOnly: true),
                  ]),
                  buildSizedBox(10),

                  buildRow([
                    buildText('Credit limit            '),
                    buildSizedBox(10),
                    buildExpandedColumn(creditLimit, 10, readOnly: true),
                  ]),

                  buildSizedBox(10),
                  buildRow([
                    buildText('Required Delivery '),
                    buildSizedBox(10),
                    buildExpandedColumn(requiredDelivery.toString(), 10,
                        readOnly: true, controller: TextEditingController()),
                  ]),buildSizedBox(10),
                  Column(
                    children: [
                      buildSizedBox(10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            child: ElevatedButton(
                              onPressed: isReConfirmButtonPressed
                                  ? null // Disable the button if isReConfirmButtonPressed is true
                                  : () async {

                                // Your existing code for handling the "Re Confirm" button press
                                isOrderConfirmed = true;

                                await ordermasterViewModel.addOrderMaster(OrderMasterModel(
                                  orderId: OrderMasterid,
                                  shopName: shopName,
                                  ownerName: ownerName,
                                  phoneNo: phoneNo,
                                  brand: brand,
                                  date: date,
                                  userId: userId.toString(),
                                  userName: userNames.toString(),
                                  total: totalAmount,
                                  creditLimit: creditLimit,
                                  shopCity: selectedShopCity,
                                  requiredDelivery: requiredDelivery,
                                ));
                                 await saveRowDataDetailsToDatabase(rowDataDetails);

                                Fluttertoast.showToast(
                                  msg: "Order confirmed!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                                setState(() {
                                  isReConfirmButtonPressed = true; // Mark the button as pressed
                                });


                                  await ordermasterViewModel.postOrderMaster();
                                await  orderdetailsViewModel.postOrderDetails();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green, // Set the color of the button
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8), // Optional: Set border radius
                                ),
                              ),
                              child: const Text('Re Confirm'),
                            ),
                          ),
                        ],
                      ),

                      buildSizedBox(20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () {
                                if (isOrderConfirmed) {
                                  // Order is confirmed, generate and share the PDF
                                  generateAndSharePDF(orderMasterid, user_name, shopName, orderDate, selectedItems, quantities, rates, totalAmounts, totalAmount, creditLimit, requiredDelivery);

                                } else {
                                  // Order is not confirmed, show a toast message
                                  Fluttertoast.showToast(
                                    msg: "Please confirm the order before sharing the PDF.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(

                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                // Set the background color of the button
                                // Set the background color of the button
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8), // Optional: Set border radius
                                ),
                              ),
                              child: const Text('PDF '),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),

                  Column(children: [
                    buildSizedBox(10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isOrderConfirmed) {
                              await productsController.clearAmounts();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            } else {
                              // Order is not confirmed, show a toast message
                              Fluttertoast.showToast(
                                msg: "Please confirm the order before Closing.",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Set the background color of the button
                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Optional: Set border radius
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ),

                  ]
                  ),
                ],
              ),
            ),
          ),
        ));
  }


  // New method to save rowDataDetails to the order details database
  Future<void> saveRowDataDetailsToDatabase(List<Map<String, dynamic>> rowDataDetails) async {
    // final orderdetailsViewModel = Get.put(OrderDetailsViewModel());

    for (var rowData in rowDataDetails) {
      var id = customAlphabet('1234567890', 5);
      orderdetailsViewModel.addOrderDetail(OrderDetailsModel(
        id: double.parse(id),
        orderMasterId: OrderMasterid,
        productName: rowData['selectedItem'],
        quantity: rowData['quantity'],
        price: rowData['rate'],
        amount:  rowData['totalAmount'],
        userId: userId,
        // Populate other fields based on your data model
      ));
    }
  }

  Widget buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
      ),
    );
  }

  Widget buildTextFormField(double height, String text,
      {bool readOnly = false, TextEditingController? controller}) {
    return SizedBox(
      height: height,
      child: TextFormField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Adjust the horizontal padding as needed
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        maxLines: 1,
        style: const TextStyle(fontSize: 15),
        initialValue: text,
        readOnly: readOnly,
      ),
    );
  }

  Widget buildSizedBox(double height) {
    return SizedBox(height: height);
  }

  Widget buildHeading(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget buildExpandedColumn(String text, double width,
      {bool readOnly = false, TextEditingController? controller}) {
    return Expanded(
      flex: width != null ? width.toInt() : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Text != null)
            buildTextFormField(30, text,
                readOnly: readOnly, controller: controller),
        ],
      ),
    );
  }

  Widget buildRow(List<Widget> children) {
    return Row(
      children: children,
    );
  }

  Widget buildDropdownRow(String labelText, double width, List<String> options,
      {String? value, void Function(String?)? onChanged}) {
    return Row(
      children: [
        buildText(labelText),
        buildSizedBox(10),
        buildExpandedColumn(
          DropdownButton<String>(
            value: value,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
          ).toString(),
          width,
        ),
      ],
    );
  }


  int calculateTotalQuantity(List<String> quantities) {
    return quantities.fold<int>(0, (sum, quantity) => sum + int.parse(quantity));
  }

  Future<void> generateAndSharePDF(dynamic orderId, dynamic user_name, dynamic shopName,
      dynamic order_date, List<dynamic> selectedItems, List<dynamic> quantities, List<dynamic> rates,
      List<dynamic> totalAmounts, dynamic totalAmount, dynamic creditLimit,
      dynamic requiredDelivery) async {
    final pdf = pw.Document();
    final image = pw.Image(pw.MemoryImage(Uint8List.fromList((await rootBundle.load('assets/images/p1.png')).buffer.asUint8List())));
    final totalQuantity = calculateTotalQuantity(quantities.cast<String>());

    const itemsPerPage = 10; // Adjust this value based on your requirement

    // Add content to the PDF document
    for (var startIndex = 0; startIndex < selectedItems.length; startIndex += itemsPerPage) {
      final endIndex = (startIndex + itemsPerPage < selectedItems.length) ? startIndex + itemsPerPage : selectedItems.length;
      final itemsSubset = selectedItems.sublist(startIndex, endIndex);
      final quantitiesSubset = quantities.sublist(startIndex, endIndex);
      final ratesSubset = rates.sublist(startIndex, endIndex);
      final totalAmountsSubset = totalAmounts.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: pw.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header (Omitted for brevity)
                // Page Content
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: -60),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Container(
                            child: image,
                            height: 150,
                            width: 150,
                          ),
                          pw.Text('Courage ERP', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                        ],
                      ),
                    ],
                  ),
                ),


                pw.SizedBox(height: 20),
                // Order#, Date, Booker
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Text('Order#: $OrderMasterid', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Booker Name: $user_name', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Shop Name: $shopName', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Date: $order_date', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Req. Delivery: $requiredDelivery', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Credit Limit: $creditLimit', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.SizedBox(height: 30),
                    // Invoice Heading
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Text('Invoice', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      ],
                    ),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        // Order Summary
                        pw.Text('Order Summary..', style: const pw.TextStyle(fontSize: 15)),
                        pw.SizedBox(height: 20),
                      ],
                    ),
                    pw.SizedBox(height: 30),
                    // Table
                    pw.Table(
                      border: pw.TableBorder.symmetric(),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(4),
                        2: const pw.FlexColumnWidth(1),
                        3: const pw.FlexColumnWidth(1),
                        4: const pw.FlexColumnWidth(2),
                        5: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text('S.N.', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Descr. of Goods', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Qty.', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Unit', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Price', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Amount(Rs.)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        for (var i = 0; i < itemsSubset.length; i++)
                          pw.TableRow(
                            children: [
                              pw.Text((i + startIndex + 1).toString()),
                              pw.Text(itemsSubset[i]),
                              pw.Text(quantitiesSubset[i].toString()),
                              pw.Text(('PCS').toString()),
                              pw.Text(ratesSubset[i].toString()),
                              pw.Text(totalAmountsSubset[i].toString()),
                            ],
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    // Total
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Total: $totalAmount', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            // pw.Text('Discount: ', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                            // pw.Text(discount.toString(), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          height: 1,
                          color: PdfColors.grey,
                          margin: const pw.EdgeInsets.symmetric(vertical: 5),
                        ),
                        pw.SizedBox(height: 20),
                        // Total Quantity
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total: $totalQuantity PCS', style: const pw.TextStyle(fontSize: 15)),
                            // pw.Text('Net Amount: ${subTotal.toString()}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          height: 1,
                          color: PdfColors.grey,
                          margin: const pw.EdgeInsets.symmetric(vertical: 5),
                        ),
                        pw.SizedBox(height: 10),
                        // pw.Row(
                        //   mainAxisAlignment: pw.MainAxisAlignment.end,
                        //   children: [
                        //     pw.Text('Credit Limit: ', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        //     pw.Text(creditLimit.toString(), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        //   ],
                        // ),
                      ],
                    ),
                    // Footer
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 30),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Developed by MetaXperts', style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      );
    }

    // Get the directory for temporary files
    final directory = await getTemporaryDirectory();

    // Create a temporary file in the directory
    final output = File('${directory.path}/$userNames-$OrderMasterid.pdf');
    await output.writeAsBytes(await pdf.save());

    // Share the PDF
    await Share.shareFiles([output.path], text: 'PDFDocument');
  }


  Widget buildElevatedButton(String txt, [Function()? onPressed]) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          minimumSize: const Size(200, 50),
        ),
        child: Text(txt),
        );
    }
}