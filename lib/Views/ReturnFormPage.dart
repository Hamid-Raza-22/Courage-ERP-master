import 'dart:io' show InternetAddress, SocketException;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nanoid/async.dart';
import 'package:order_booking_shop/API/Globals.dart';
import 'package:order_booking_shop/Models/ReturnFormDetails.dart';
import 'package:order_booking_shop/View_Models/OrderViewModels/ReturnFormViewModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../API/DatabaseOutputs.dart';
import '../API/newDatabaseOutPuts.dart';
import '../Databases/DBHelper.dart';
import '../Models/ReturnFormModel.dart';
import '../View_Models/OrderViewModels/ReturnFormDetailsViewModel.dart';
import 'package:flutter/services.dart';
import 'HomePage.dart';


class ProductController extends GetxController {
  final DBHelper dbHelper = DBHelper();

  RxList<String> productNames = <String>[].obs;

  Future<void> fetchProductData(String shopName) async {
    List<String> names = await dbHelper.getOrderDetailsProductNames();
    productNames.assignAll(names);
  }
}

class TypeAheadController extends TextEditingController {
  bool isSelectionFromSuggestion = false;
}

void main() {
  runApp(const MaterialApp(
    home: ReturnFormPage(),
  ));
}

class ReturnFormPage extends StatefulWidget {
  const ReturnFormPage({super.key});

  @override
  _ReturnFormPageState createState() => _ReturnFormPageState();
}

class _ReturnFormPageState extends State<ReturnFormPage> {
  final returnformdetailsViewModel = Get.put(ReturnFormDetailsViewModel());
  final returnformViewModel = Get.put(ReturnFormViewModel());
  final TextEditingController _selectedShopController = TextEditingController();
  List<Widget> dynamicRows = [];
  bool isOrderConfirmed = false;
  List<TypeAheadController> firstTypeAheadControllers = [];
  List<TextEditingController> qtyControllers = [];
  List<TextEditingController> priceControllers = [];
  List<TextEditingController> secondTypeAheadControllers = [];
  int? returnformid;
  bool isButtonDisabled = false;
  bool isReConfirmButtonPressed = false;
  String selectedShopBrand = '';
  String selectedShopCityR = '';
  int? returnformdetailsid;
  List<String> dropdownItems = [];
  List<Map<String, dynamic>> shopOwners = [];
  List<String> dropdownItems2 = [];
  List<Map<String, dynamic>> productOwners = [];
  DBHelper dbHelper = DBHelper();
  double? amountControllerNetBalance;
  double recoveryFormCurrentBalance = 0.0;
  TextEditingController amountController = TextEditingController();
  DBHelper dbreturnform = DBHelper();
  final ProductController productController = Get.put(ProductController());
  final ProductController productController1 = Get.put(ProductController());
  // Future<void> fetchShopNamesAndTotals() async {
  //   DBHelper dbHelper = DBHelper();
  //
  //   // Calculate total debits, credits, and debits minus credits per shop
  //   Map<String, dynamic> debitsAndCredits = await dbHelper.getDebitsAndCreditsTotal();
  //   Map<String, double> debitsMinusCreditsPerShop = await dbHelper.getDebitsMinusCreditsPerShop();
  //
  //   // Extract shop names, debits, credits, and debits minus credits per shop
  //   List<String> shopNames = debitsAndCredits['debits'].keys.toList();
  //   Map<String, double> shopDebits = debitsAndCredits['debits'];
  //   Map<String, double> shopCredits = debitsAndCredits['credits'];
  //
  //   // Print or use the shop names, debits, credits, and debits minus credits per shop as needed
  //   if (kDebugMode) {
  //     print("Shop Names: $shopNames");
  //     print("Shop Debits: $shopDebits");
  //     print("Shop Credits: $shopCredits");
  //     print("Shop Debits - Credits: $debitsMinusCreditsPerShop");
  //   }
  //   // You can update the state or perform other actions with the data here
  // }

  bool isValidQuantity(String quantity) {
    try {
      int parsedQuantity = int.parse(quantity);
      return parsedQuantity >
          0; // Adjust the condition based on your requirements
    } catch (e) {
      return false; // Quantity is not a valid integer
    }
  }
  @override
  void initState() {
    super.initState();
    // Initialize with one row.
    addNewRowControllers();
    dynamicRows.add(buildTypeAheadRow(0));
    onCreatee();
    fetchShopData();
    fetchProductDataForSelectedShop(_selectedShopController.text);
    // fetchShopNamesAndTotals();
  }
  //
  Future<void> fetchNetBalanceForShop(String shopName) async {
    DBHelper dbHelper = DBHelper();
    double shopDebits = 0.0;
    double shopCredits = 0.0;

    // Fetch net balance for the selected shop
    List<Map<String, dynamic>>? netBalanceData = await dbHelper.getNetBalanceDB();
    for (var row in netBalanceData!) {
      if (row['shop_name'] == shopName) {
        shopDebits += double.parse(row['debit'] ?? '0');
        shopCredits += double.parse(row['credit'] ?? '0');
      }
    }

    // Calculate net balance (shop debits - shop credits)
    double netBalance = shopDebits - shopCredits;

    // Ensure net balance is not less than 0
    netBalance = netBalance < 0 ? 0 : netBalance;

    setState(() {
      // Update the current balance field with the calculated net balance
      // recoveryFormCurrentBalance = netBalance;
      globalnetBalance = netBalance;
      // _currentBalanceController.text = recoveryFormCurrentBalance.toString();
    });
  }


  double calculateTotalAmount() {
    double totalAmount = 0.0;

    for (int index = 0; index < qtyControllers.length; index++) {
      try {
        int qty = int.parse(qtyControllers[index].text);
        double price = double.parse(priceControllers[index].text);

        double amount = qty * price;  // Calculate amount
        totalAmount += amount;  // Accumulate the total amount

      } catch (e) {
        amountController.text = "Invalid input";  // Set a default value or handle the error
        return 0.0; // Handle the case where either qty or price is not a valid number
      }
    }

    amountController.text = totalAmount.toString(); // Set the total amount to the controller

    return totalAmount;
  }

  Future<void> netbalance() async {
    double? amount = double.tryParse(amountController.text);
    if (amount != null) {
      amountControllerNetBalance = (globalnetBalance! >= amount) ? 0.0 : 0.0;
    } else {
      if (kDebugMode) {
        print("Error: amountController.text is not a valid number.");
      }
    }
  }
  void showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Please Wait..."),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateQuantityField(String selectedProductName,
      int index) async {
    String? quantity = await fetchQuantityForProduct(selectedProductName);
    if (quantity != null) {
      setState(() {
        qtyControllers[index].text = quantity;
      });
    }
  }
  Future<void> updatePriceField(String selectedProductName,
      int index) async {
    String? price = await fetchPriceForProduct(selectedProductName);
    if (price != null) {
      setState(() {
        priceControllers[index].text = price;
      });
    }
  }
  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  void fetchProductDataForSelectedShop(String selectedShopName) async {
    await productController.fetchProductData(selectedShopName);
    setState(() {
      dropdownItems2 = productController.productNames.toList();
      // Clear the controllers and dynamic rows
      firstTypeAheadControllers.clear();
      qtyControllers.clear();
      priceControllers.clear();
      secondTypeAheadControllers.clear();
      dynamicRows.clear();
      // Re-add the initial row
      addNewRowControllers();
      dynamicRows.add(buildTypeAheadRow(0));
    });
  }
  void fetchShopData() async {
    List<String> shopNames = await dbHelper.getOrderMasterShopNames();
    shopOwners = (await dbHelper.getOrderBookingStatusDB())!;
    setState(() {
      dropdownItems = shopNames.toSet().toList();
    });
  }

  String getOrderNoForSelectedShop() {
    String selectedShopName = _selectedShopController.text;
    for (var shop in shopOwners) {
      if (shop['shop_name'] == selectedShopName) {
        return shop['order_no'];
      }
    }
    return '';
  }
  void printOrderNoForSelectedShop() {
    String orderNo = getOrderNoForSelectedShop();
    if (kDebugMode) {
      print('Order number for selected shop: $orderNo');
    }
  }

  Future<void> onCreatee() async {
    DatabaseOutputs db = DatabaseOutputs();
    await db.showOrderDetailsData();
    //await db.showOrderDispacthed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return form'),
        backgroundColor: Colors.white10,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.white10,
              child: Column(
                children: [
                  buildTypeaheadWithDateRow(),
                  buildTopSerialNoRow(),
                  ...dynamicRows,
                  buildAddRowButton(),
                  buildSubmitButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTopSerialNoRow() {
    return const Padding(
      padding: EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '      Item',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '      Qty',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              '     Reason                                                  ',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTypeaheadWithDateRow() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Date: ',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                _getCurrentDate(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10), // Add spacing between date and shop name row
          // Shop Name Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black45,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white10,
                  ),
                  child: TypeAheadField<String>(
                    suggestionsCallback: (pattern) async {
                      return dropdownItems
                          .where((option) =>
                          option.toLowerCase().contains(pattern.toLowerCase()))
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 11),
                          // Adjust maxLines and overflow properties to allow multiline text
                          maxLines: 2, // Set the maximum number of lines
                          overflow: TextOverflow.ellipsis, // Handle overflow by showing ellipsis
                        ),
                      );
                    },
                    onSuggestionSelected: (suggestion) async {
                      setState(() {
                        _selectedShopController.text = suggestion;
                        selectedorderno = getOrderNoForSelectedShop();
                        if (kDebugMode) {
                          print('order no: $selectedorderno');
                        }
                        fetchProductDataForSelectedShop(suggestion);
                        printOrderNoForSelectedShop();
                        // fetchNetBalanceForShop(suggestion);
                      });
                      for (var owner in shopOwners) {
                        if (owner['shop_name'] == suggestion) {
                          setState(() {
                            selectedShopBrand = owner['brand'];
                            selectedShopCityR= owner['city'];
                            if (kDebugMode) {
                              print(selectedShopCityR);
                            }
                          });
                        }
                      }
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selectedShopName', suggestion);
                      newDatabaseOutputs outputs = newDatabaseOutputs();
                      await outputs.updateBalanceData();
                      setState(() {
                        String balance = prefs.getString('balance') ?? 'no data';
                        // Update the current balance field with the calculated net balance
                        recoveryFormCurrentBalance = double.parse(balance);
                          globalnetBalance  = recoveryFormCurrentBalance;
                      });
                    },
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _selectedShopController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '--Select Shop--',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 3.0), // Adjust vertical padding
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 25),
            ],
          ),

        ],
      ),
    );
  }

  Widget buildTypeAheadRow(int index) {
    if (index >= firstTypeAheadControllers.length ||
        index >= qtyControllers.length ||
        index >= priceControllers.length ||
        index >= secondTypeAheadControllers.length) {
      addNewRowControllers();
    }

    TypeAheadController firstController = firstTypeAheadControllers[index];
    TextEditingController qtyController = qtyControllers[index];
    TextEditingController secondController = secondTypeAheadControllers[index];

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${index + 1}. ',
                style: const TextStyle(fontSize: 16),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                  ),
                  child: TypeAheadField<String>(
                    suggestionsCallback: (pattern) async {
                      List<String> suggestions = dropdownItems2
                          .where((option) =>
                          option.toLowerCase().contains(pattern.toLowerCase()))
                          .toList();

                      for (int i = 0; i <
                          firstTypeAheadControllers.length; i++) {
                        String selectedProduct =
                        firstTypeAheadControllers[i].text.toLowerCase();
                        suggestions.removeWhere(
                                (option) =>
                            option.toLowerCase() == selectedProduct);
                      }

                      return suggestions;
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                    onSuggestionSelected: (suggestion) async {
                      if (kDebugMode) {
                        print(suggestion);
                      }
                      SellectedproductName= suggestion;
                      setState(() {
                        firstController.text = suggestion;
                        firstController.isSelectionFromSuggestion = true;
                      });
                      await updateQuantityField(suggestion, index);
                      if (kDebugMode) {
                        print(globalnetBalance);
                      }
                      await updatePriceField(suggestion, index);
                      calculateTotalAmount();
                      await netbalance();
                    },
                    textFieldConfiguration: TextFieldConfiguration(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                      ),
                      controller: firstController,
                      style: const TextStyle(fontSize: 12),
                      maxLines: null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                height: 50,
                width: 50,
                child: TextFormField(
                  controller: qtyController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'Qty',
                    hintStyle: const TextStyle(fontSize: 12),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction(
                          (oldValue, newValue) {
                        if (newValue.text.isEmpty) {
                          return newValue;
                        }
                        if (int.tryParse(newValue.text) != null) {
                          return newValue;
                        } else {
                          return oldValue;
                        }
                      },
                    ),
                  ],
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(width: 5),
              Container(
                height: 50,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                ),
                child: TypeAheadField<String>(
                  suggestionsCallback: (pattern) async {
                    return ['Damage', 'Complaint', 'Expire', 'closed', 'Others']
                        .where((option) =>
                        option.toLowerCase().contains(pattern.toLowerCase()))
                        .toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    setState(() {
                      secondController.text = suggestion;
                    });
                  },
                  textFieldConfiguration: TextFieldConfiguration(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                    ),
                    controller: secondController,
                    style: const TextStyle(fontSize: 12),
                    maxLines: null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 17),
                onPressed: () {
                  setState(() {
                    dynamicRows.removeAt(index);
                    firstTypeAheadControllers.removeAt(index);
                    qtyControllers.removeAt(index);
                    priceControllers.removeAt(index);
                    secondTypeAheadControllers.removeAt(index);
                    for (int i = index; i < dynamicRows.length; i++) {
                      dynamicRows[i] = buildTypeAheadRow(i);
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAddRowButton() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            dynamicRows.add(buildTypeAheadRow(dynamicRows.length));
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Add Row',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }
  Widget buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: isButtonDisabled // Use isButtonDisabled to determine if the button should be disabled
            ? null // Disable the button if isReConfirmButtonPressed is true
            : () async {
          // Your existing code for handling the "Re Confirm" button press
          isOrderConfirmed = true;
          final bool isConnected = await isInternetAvailable();

          if (!isConnected) {
            Fluttertoast.showToast(
              msg: 'No Internet',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            return; // Exit the function early if internet connection is not available
          }
          calculateTotalAmount();
          double? amount = double.tryParse(amountController.text);
          // Check if all type-ahead dropdowns and text fields are filled
          bool allFieldsFilled = true;
          bool reasonSelected = true; // Add a flag to check if reasons are selected
          for (int i = 0; i < firstTypeAheadControllers.length; i++) {
            if (firstTypeAheadControllers[i].text.isEmpty ||
                secondTypeAheadControllers[i].text.isEmpty ||
                qtyControllers[i].text.isEmpty) {
              allFieldsFilled = false;
              break;
            }
            // Check if reasons are selected
            if (secondTypeAheadControllers[i].text == 'Select Reason') {
              reasonSelected = false;
              break;
            }
          }
          // Check if any reason or second controller typeahead is empty
          bool anyEmptyReason =
          secondTypeAheadControllers.any((controller) => controller.text.isEmpty);
          if (anyEmptyReason || !allFieldsFilled || !reasonSelected) {
            Fluttertoast.showToast(
              msg: 'Please fill all fields and select a reason for all items',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            return; // Exit the function early if any reason or second controller typeahead is empty
          }
          if (!isFormValid() || globalnetBalance! < amount!) {
            if (kDebugMode) {
              print('Invalid form. Please check your inputs.');
            }
            Fluttertoast.showToast(
              msg: 'Please check your inputs and Enter Quantity Lower Than The Current Balance',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            return;
          }
          // Your existing code for submission
          var id = await customAlphabet('1234567890', 5);

          await returnformViewModel.addReturnForm(ReturnFormModel(
            returnId: int.parse(id),
            shopName: _selectedShopController.text,
            date: _getCurrentDate(),
            returnAmount: amountController.text,
            bookerId: userId,
            bookerName: userNames,
            city: selectedShopCityR,
            brand: selectedShopBrand,
          ));

          String visitid = await returnformViewModel.fetchLastReturnFormId();
          returnformid = int.parse(visitid);

          for (int i = 0; i < firstTypeAheadControllers.length; i++) {
            var id = await customAlphabet('1234567890', 12);
             returnformdetailsViewModel.addReturnFormDetail(
              ReturnFormDetailsModel(
                id: int.parse(id),
                returnformId: returnformid ?? 0,
                productName: firstTypeAheadControllers[i].text,
                reason: secondTypeAheadControllers[i].text,
                quantity: qtyControllers[i].text,
                bookerId: userId,
              ),
            );
          }
          setState(() {
            isButtonDisabled = true; // Mark the button as disabled after being pressed
          });
           returnformViewModel.postReturnForm() ;
           returnformdetailsViewModel.postReturnFormDetails();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonDisabled ? Colors.grey : Colors.green, // Change the button color when disabled
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Submit',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  bool isFormValid() {
    bool isDropdownValid = dropdownItems.contains(_selectedShopController.text);
    bool isTypeAheadValid = firstTypeAheadControllers.every(
          (controller) => controller.isSelectionFromSuggestion,
    );
    bool isQtyValid = qtyControllers.every(
          (controller) => isValidQuantity(controller.text),
    );


    return _selectedShopController.text.isNotEmpty &&
        isDropdownValid &&
        isTypeAheadValid &&
        isQtyValid ;

  }


  String _getCurrentDate() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MMM-yyyy').format(now);
    return formattedDate;
  }

  void addNewRowControllers() {
    firstTypeAheadControllers.add(TypeAheadController());
    qtyControllers.add(TextEditingController());
    priceControllers.add(TextEditingController());
    secondTypeAheadControllers.add(TextEditingController());
  }

  Future<String?> fetchQuantityForProduct(String productName) async {
    try {
      final Database? db = await productController.dbHelper.db;

      if (db != null) {
        final List<Map<String, dynamic>> result = await db.query(
          'orderDetailsData',
          columns: ['quantity_booked'],
          where: 'product_name = ? AND order_no = ?',
          whereArgs: [productName,selectedorderno ],
        );
        if (result.isNotEmpty) {
          return result[0]['quantity_booked'].toString();
        } else {
          return null; // Handle the case where quantity is not found
        }
      } else {
        return null; // Handle the case where the database is null
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching quantity for product: $e");
      }
      return null;
    }
  }

  Future<String?> fetchPriceForProduct(String productName) async {
    try {
      final Database? db = await productController.dbHelper.db;

      if (db != null) {
        final List<Map<String, dynamic>> result = await db.query(
          'orderDetailsData',
          columns: ['price'],
          where: 'product_name = ? AND order_no = ?',
          whereArgs: [productName,selectedorderno ],
        );

        if (result.isNotEmpty) {
          return result[0]['price'].toString();
        } else {
          return null; // Handle the case where quantity is not found
        }
      } else {
        return null; // Handle the case where the database is null
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching price for product: $e");
      }
      return null;
    }
  }
}