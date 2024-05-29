import 'package:flutter/foundation.dart' show ChangeNotifier, ValueNotifier, kDebugMode;
import 'package:flutter/material.dart' show AbsorbPointer, AlertDialog, Align, Alignment, AppBar, Axis, Border, BorderRadius, BorderSide, BoxDecoration, BuildContext, Card, ChangeNotifier, Colors, Column, Container, CrossAxisAlignment, DataCell, DataColumn, DataRow, DataTable, EdgeInsets, ElevatedButton, Expanded, FocusNode, Icon, IconButton, Icons, InkWell, InputDecoration, ListTile, MainAxisSize, MaterialPageRoute, MediaQuery, ModalRoute, Navigator, OutlineInputBorder, Padding, PopScope, RoundedRectangleBorder, RouteSettings, Row, Scaffold, ScaffoldMessenger, SingleChildScrollView, Size, SizedBox, SnackBar, Stack, State, StatefulWidget, Text, TextButton, TextEditingController, TextField, TextFormField, TextInputType, TextStyle, ValueListenableBuilder, ValueNotifier, Widget, showDatePicker, showDialog;
import 'package:flutter/services.dart' show FilteringTextInputFormatter, Size, TextInputFormatter, TextInputType;
import 'package:fluttertoast/fluttertoast.dart' show Fluttertoast, Toast, ToastGravity;

import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import 'package:flutter_typeahead/flutter_typeahead.dart' show SuggestionsBoxDecoration, TextFieldConfiguration, TypeAheadFormField;
import 'package:intl/intl.dart' show DateFormat;
import 'package:order_booking_shop/API/DatabaseOutputs.dart';
import 'package:order_booking_shop/API/Globals.dart';
import 'package:order_booking_shop/Models/ProductsModel.dart';
import 'package:order_booking_shop/View_Models/OrderViewModels/OrderDetailsViewModel.dart';
import 'package:order_booking_shop/View_Models/OrderViewModels/OrderMasterViewModel.dart';
import 'package:order_booking_shop/View_Models/OrderViewModels/ProductsViewModel.dart';

import '../API/newDatabaseOutPuts.dart';
import 'HomePage.dart';
import 'OrderBooking2ndPage.dart';
import 'package:get/get.dart';
import 'dart:async' show Future;



// ...
class Productss extends ChangeNotifier {
  final productsViewModel = ProductsViewModel();
  List<DataRow> rows = [];
  List<TextEditingController> quantityControllers = [];
  final amounts = <ProductsModel, RxDouble>{};
  final Map<String, String> args = Get.arguments ?? {};
  String total = '0';
  List<RxDouble> amountValues = [];
  final ValueNotifier<double> _totalValueNotifier = ValueNotifier<double>(0.0);

  // Change fetchProducts method to return a stream of double
  ValueNotifier<double> get totalValueNotifier => _totalValueNotifier;

  Future<void> fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await productsViewModel.fetchProductsByBrand(globalselectedbrand);
    var products = productsViewModel.allProducts;

    rows.clear();
    quantityControllers.clear();
    amountValues.clear();

    for (var i = 0; i < products.length; i++) {
      var product = products[i];

      String qty = prefs.getString('qty$i') ?? '0'; // Load the saved quantity
      TextEditingController controller = TextEditingController(text: '0');
      FocusNode focusNode = FocusNode();
      quantityControllers.add(controller);

      RxDouble? amount = amounts[product];
      if (amount == null) {
        amount = RxDouble(0.0);
        amounts[product] = amount;
        amountValues.add(amount);
      }

      controller.addListener(() {
        double rate = double.parse(product.price ?? '0');
        int quantityValue = int.tryParse(controller.text) ?? 0;
        amounts[product]!.value = rate * quantityValue;
        calculateTotal();
      });

      focusNode.addListener(() {
        if (!focusNode.hasFocus && controller.text.isEmpty) {
          controller.text = '0';
        }
      });

      rows.add(DataRow(cells: [
        DataCell(Text(product.product_name ?? '')),
        DataCell(TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
          onTap: () {
            controller.clear();
          },
        )),
        DataCell(Text(product.quantity ?? qty)),
        DataCell(Text(product.price ?? '0')),
        DataCell(Obx(() => Text(amounts[product]!.value.toString()))),
      ]));
    }
  }

  clearAmounts() {
    amounts.clear(); // Clear all amounts
  }

  void calculateTotal() {
    double totalAmount = 0.0;
    for (var amount in amounts.values) {
      totalAmount += amount.value;
    }
    total = totalAmount.toString();
    _totalValueNotifier.value = totalAmount; // Update the value notifier
    notifyListeners(); // Notify listeners of total change
  }

  bool isQuantityZeroAtIndex(int index) {
    if (index < 0 || index >= quantityControllers.length) {
      throw RangeError('Index out of range');
    }
    return int.tryParse(quantityControllers[index].text) == 0;
  }
}

class FinalOrderBookingPage extends StatefulWidget {
  const FinalOrderBookingPage({super.key});

  @override
  FinalOrderBookingPageState createState() => FinalOrderBookingPageState();
}

class FinalOrderBookingPageState extends State<FinalOrderBookingPage> {
  final TextEditingController _totalController = TextEditingController();
  final ordermasterViewModel = Get.put(OrderMasterViewModel());
  final orderdetailsViewModel = Get.put(OrderDetailsViewModel());
  int? ordermasterId;
  int? orderdetailsId;
  final Productss productsController = Productss();
  final TextEditingController _ShopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneNoController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _subTotalController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  final quantityControllers = <ProductsModel, TextEditingController>{};
  final amounts = <ProductsModel, double>{};
  final String inStockValue = "In Stock";
  final TextEditingController _requiredDeliveryController = TextEditingController();
  final productsViewModel = Get.put(ProductsViewModel());
  String selectedBrand = '';
  List<RowData> rowDataList = [];
  List<String> selectedProductNames = [];
  int serialNumber = 1;
  int serialCounter = 1;
  String currentMonth = DateFormat('MMM').format(DateTime.now());
  String currentUserId = '';
  String newOrderId='';
  List<String> creditLimitOptions = [];
  String selectedCreditLimit = '';
  List<DataRow> rows = [];
  List<DataRow> filteredRows = [];
  List<Map<String, dynamic>> rowDataDetails = [];

  void filterData(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRows = [];
      });
    } else {
      List<DataRow> tempList = [];
      String lowercaseQuery = query.toLowerCase();
      for (DataRow row in productsController.rows) {
        for (DataCell cell in row.cells) {
          if (cell.child is Text &&
              (cell.child as Text).data!.toLowerCase().contains(lowercaseQuery)) {
            tempList.add(row);
            break;
          }
        }
      }
      setState(() {
        filteredRows = tempList;
      });
    }
  }

  @override
  void initState() {
    fetchAllProducts();
    super.initState();
    fetchAllProducts();
    productsController.addListener(_onProductChange);

    _searchController = TextEditingController();
    addNewRow();
    addNewRow();
   // onCreatee();

    addListenerToController(_discountController, _calculateSubTotal);
    addListenerToController(_paymentController, _calculateBalance);
    addListenerToController(_subTotalController, _calculateBalance);
  }

  void _onProductChange() {
    setState(() {}); // Update UI when products change
  }

  Future<void> fetchAllProducts() async {
    await productsController.fetchProducts();
    setState(() {
      rows = productsController.rows;
    });
  }

  @override
  void dispose() {
    _ShopNameController.dispose();
    _ownerNameController.dispose();
    _phoneNoController.dispose();
    _brandNameController.dispose();
    _totalController.dispose();
    _creditLimitController.dispose();
    _discountController.dispose();
    _subTotalController.dispose();
    _paymentController.dispose();
    _balanceController.dispose();
    _requiredDeliveryController.dispose();

    for (var rowData in rowDataList) {
      rowData.qtyController.dispose();
      rowData.rateController.dispose();
      rowData.amountController.dispose();
    }
    super.dispose();
  }

  void addListenerToController(TextEditingController controller, Function() listener) {
    controller.addListener(() {
      listener();
    });
  }

  Future<void> onCreatee() async {
    newDatabaseOutputs db = newDatabaseOutputs();
    // await db.showOrderMaster();
    // await db.showOrderDetails();
    // await db.showShopVisit();
    // await db.showStockCheckItems();
  }

  @override
  Widget build(BuildContext context) {
    final shopData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final shopName = shopData['shopName'];
    final ownerName = shopData['ownerName']??'No Name';
    final selectedBrandName = shopData['selectedBrandName'];
    final ownerContact = shopData['ownerContact']?? 'No Contact';

    _ShopNameController.text = shopName!;
    _ownerNameController.text = ownerName!;
    _brandNameController.text = selectedBrandName;
    _phoneNoController.text = ownerContact!;

    return PopScope(
      canPop: true, // When false, blocks the current route from being popped.
      onPopInvoked: (didPop) async {
        await productsController.clearAmounts();
        productsController.rows.clear();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      //  return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Booking'),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Ensure the row takes minimum space
                        children: [
                          const Text(
                            'Date:', // Add the text here
                            style: TextStyle(
                              fontSize: 15,
                              // Optionally adjust the font weight
                            ),
                          ),
                          const SizedBox(width: 5), // Add some space between the text and the date
                          Text(
                            DateFormat('dd-MMM-yyyy').format(DateTime.now()), // Add the live date here
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  buildTextFormField('Shop Name', _ShopNameController, readOnly: true),
                  const SizedBox(height: 10),
                  buildTextFormField('Owner Name', _ownerNameController, readOnly: true),
                  const SizedBox(height: 10),
                  buildTextFormField('Phone#', _phoneNoController, readOnly: true),
                  const SizedBox(height: 10),
                  buildTextFormField('Brand', _brandNameController, readOnly: true),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: SizedBox(
                                height: 400, // Set the desired height
                                width: MediaQuery.of(context).size.width * 0.9, // Set the desired width

                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (query) {
                                              filterData(query);
                                            },
                                            decoration: const InputDecoration(
                                              labelText: 'Search',
                                              hintText: 'Type to search...',
                                              prefixIcon: Icon(Icons.search),
                                            ),
                                          ),
                                        ),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            columns: const [
                                              DataColumn(label: Text('Products')),
                                              DataColumn(label: Text('Quantity')),
                                              DataColumn(label: Text('In Stock', style: TextStyle(color: Colors.black))),
                                              DataColumn(label: Text('Rate')),
                                              DataColumn(label: Text('Amount')),
                                            ],
                                            rows: filteredRows.isNotEmpty ? filteredRows : productsController.rows,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<double>(
                    valueListenable: productsController.totalValueNotifier,
                    builder: (context, value, child) {
                      _totalController.text = value.toString();
                      return buildTextFormField('Total', _totalController, readOnly: true);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Replace the Credit Limit text field with a Dropdown
                  buildDropdown('Credit Limit', _creditLimitController, creditLimitOptions, selectedCreditLimit),

                  const SizedBox(height: 10),
                  // buildTextFormField('Discount', _discountController),
                  // SizedBox(height: 10),
                  // buildTextFormField('Net Amount', _subTotalController,readOnly: true),
                  // SizedBox(height: 10),

                  buildDateField('Required Delivery', _requiredDeliveryController),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () async {
                        for (int index = 0; index < productsController.quantityControllers.length; index++) {
                          if (productsController.isQuantityZeroAtIndex(index)) {
                            break;
                          }
                        }
                        // Check if credit limit is in the list
                        if (_ShopNameController.text.isNotEmpty &&
                            _ownerNameController.text.isNotEmpty &&
                            _phoneNoController.text.isNotEmpty &&
                            _brandNameController.text.isNotEmpty &&
                            _totalController.text.isNotEmpty &&
                            _creditLimitController.text.isNotEmpty &&
                            ['7 Days','15 Days', '30 Days', 'On Cash'].contains(_creditLimitController.text) &
                            // _discountController.text.isNotEmpty &&
                            // _subTotalController.text.isNotEmpty &&
                            _requiredDeliveryController.text.isNotEmpty )
                          // Add additional checks for other required fields
                          // rowDataList.every((rowData) =>
                          // rowData.selectedProduct != null &&
                          //     rowData.qtyController.text.isNotEmpty &&
                          //     rowData.rateController.text.isNotEmpty &&
                          //     rowData.amountController.text.isNotEmpty))
                            {



                          // All required fields are filled, proceed with confirmation logic

                          // String newOrderId = generateNewOrderId(userId.toString(), currentMonth);

                          List<DataRow> rows =  productsController.rows;

                          for (int i = 0; i < rows.length; i++) {
                            DataRow row = rows[i];
                            String selectedItem = (row.cells[0].child as Text).data!;
                            String quantity = productsController.quantityControllers[i].text;

                            String rateString = (row.cells[3].child as Text).data!;
                            if (kDebugMode) {
                              print('Rate String: $rateString');
                            }


                            int totalAmount = productsController.amounts[productsController.productsViewModel.allProducts.firstWhere((product) => product.product_name == selectedItem)]!.value.toInt();

                            if (int.parse(quantity) != 0) {
                              rowDataDetails.add({
                                'selectedItem': selectedItem,
                                'quantity': quantity,
                                'rate': rateString,
                                'totalAmount': totalAmount,
                              });
                              if (kDebugMode) {
                                print('product: $selectedItem');
                                print('Rate String: $rateString ');
                                print('quatity: $quantity'); }
                            }
                          }
                          // Check if there are any non-zero quantity items
                          if (rowDataDetails.isEmpty) {
                            Fluttertoast.showToast(
                              msg: 'Please enter quantities greater than zero before proceeding.',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );

                            return;
                          }

                          Map<String, dynamic> dataToPass = {
                            'shopName': _ShopNameController.text,
                            'ownerName': _ownerNameController.text,
                            'orderId': OrderMasterid,
                            'orderDate': _getFormattedDate(),
                            'phoneNo': _phoneNoController.text,
                            'rowDataDetails': rowDataDetails,
                            'brand': _brandNameController.text,
                            'userName': userNames,
                            'date': _getFormattedDate(),
                            'total': _totalController.text,
                            'creditLimit': _creditLimitController.text,
                            // 'discount': _discountController.text,
                            // 'subTotal': _subTotalController.text,
                            'requiredDelivery': _requiredDeliveryController.text
                          };

                          // Navigate to another page after confirmation
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OrderBooking2ndPage(),
                              settings: RouteSettings(arguments: dataToPass),
                            ),
                          );

                        } else {
                          // Show a message or handle the case where some fields are empty or invalid
                          Fluttertoast.showToast(
                            msg: 'Please fill in all required fields before confirming.',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.green,

                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),

                ],

              ),
            ),

          ],
        ),
      ),
    );
  }


// Define dropdownItems as a list of valid items
  List<String> dropdownItems = ['7 Days','15 Days', '30 Days', 'On Cash'];

// Define shopOwners as a list of maps
  List<Map<String, dynamic>> shopOwners = [
    {'shop_name': 'Shop1', 'owner_name': 'Owner1', 'owner_contact': '1234567890'},
    {'shop_name': 'Shop2', 'owner_name': 'Owner2', 'owner_contact': '9876543210'},
    // Add more entries as needed
  ];

  String selectedShopOwner = ''; // Add this line to define selectedShopOwner

// Helper method to build a DropdownButton
  Widget buildDropdown(String labelText, TextEditingController controller, List<String> options, String selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black, // Set border color
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8.0), // Adjust padding as needed
              ),
            ),
            suggestionsCallback: (pattern) {
              return dropdownItems
                  .where((status) => status.toLowerCase().contains(pattern.toLowerCase()))
                  .toList();
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            onSuggestionSelected: (suggestion) {
              // Validate that the selected item is from the list
              if (dropdownItems.contains(suggestion)) {
                setState(() {
                  controller.text = suggestion;
                });

                // Additional logic based on the selected suggestion
                // For example, setting other state variables based on the selected suggestion
                for (var owner in shopOwners) {
                  if (owner['shop_name'] == suggestion) {
                    setState(() {
                      selectedShopOwner = owner['owner_name'];
                      // Additional state variable, if needed
                      // selectedOwnerContact = owner['owner_contact'];
                    });
                  }
                }
              } else {
                // If the selected item is not from the list, show an error message or handle it accordingly
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Invalid Selection'),
                      content: const Text('Please select a valid item from the list.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget buildTextFormField(String labelText, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 50,
          child: TextFormField(
            controller: controller,
            readOnly: readOnly, // Set readOnly based on the provided parameter
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
  Widget buildDateField(String labelText, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 50,
          child: InkWell(
            onTap: () {
              _selectDate(context, controller);
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
  void addNewRow() {
    // Check if the product in the first row is selected
    if (rowDataList.isNotEmpty && rowDataList[0].selectedProduct == null) {
      // Display a message or handle the validation error
      if (kDebugMode) {
        print('Please select a product in the first row before adding more rows.');
      }
      return;
    }

    setState(() {
      final newRow = RowData(
        serialNumber: serialNumber,
        qtyController: TextEditingController(),
        rateController: TextEditingController(),
        amountController: TextEditingController(),
        itemsDropdownValue: '',
        selectedProduct: null,
      );
      rowDataList.add(newRow);
      serialNumber++;
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final currentDate = DateTime.now();
      if (picked.isBefore(currentDate)) {
        // Show a message or perform an action indicating that the selected date is before today's date
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selected date must be a future date."),
          ),
        );
      } else {
        final formattedDate = DateFormat('dd-MMM-yyyy').format(picked);
        controller.text = formattedDate;
      }
    }
  }
  Widget buildRow(RowData rowData, int rowNumber) {
    rowData.qtyController.addListener(() {
      calculateAmount(rowData.qtyController, rowData.rateController,
          rowData.amountController, rowData);
    });

    rowData.rateController.addListener(() {
      calculateAmount(rowData.qtyController, rowData.rateController,
          rowData.amountController, rowData);
    });


    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const SizedBox(
            height: 5,
          ),
          Text(
            '$rowNumber.',
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
          const SizedBox(
            height: 5,
          ),
          Expanded(

            child: buildItemsTypeahead(rowData),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qty',
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 50,
                  child: TextFormField(
                    controller: rowData.qtyController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10), // Set the width here
                    ),
                    style: const TextStyle(fontSize: 11),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^0'))], // Allow backspacing over initial zeros
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a quantity.';
                      } else {
                        int? qty = int.tryParse(value);
                        if (qty == null) {
                          return 'Please enter a valid number.';
                        } else if (qty <= 0) {
                          return 'Quantity must be greater than zero.';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 5),
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0), // Add content padding
              child: buildNonEditableText('Rate', rowData.rateController),
            ),
          ),



          SizedBox(
            width: 55,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0), // Add content padding
              child: buildNonEditableText('Amount', rowData.amountController),
            ),
          ),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20,color: Colors.red),
              onPressed: () {
                deleteRow(rowData);
              },
            ),
          )],
      ),
    );
  }

  Widget buildItemsTypeahead(RowData rowData) {
    // final products = productsViewModel.allProducts;
    final rateController = rowData.rateController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item',
          style: TextStyle(fontSize: 13, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Container(
          height: 50, // Adjust the height as needed
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child:TypeAheadFormField<ProductsModel>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: TextEditingController(
                text: rowData.selectedProduct?.product_name ?? '',
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0), // Add content padding
              ),
              style: const TextStyle(fontSize: 12),
              maxLines: null,
            ),
            suggestionsCallback: (pattern) async {
              return productsViewModel.allProducts
                  .where((product) =>
                  product.product_name!
                      .toLowerCase()
                      .contains(pattern.toLowerCase()))
                  .toList();
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(
                  suggestion.product_name ?? '',
                  style: const TextStyle(fontSize: 9), // Set the desired font size
                ),
              );
            },
            onSuggestionSelected: (suggestion) {
              if (suggestion != null) {
                if (kDebugMode) {
                  print('Selected product: ${suggestion.product_name}');
                }
                setState(() {
                  rowData.selectedProduct = suggestion;
                  rowData.selectedProduct?.price ??= '';
                  rateController.text = suggestion.price ?? '';
                  calculateAmount(
                    rowData.qtyController,
                    rowData.rateController,
                    rowData.amountController,
                    rowData,
                  );
                });
              }
            },
            // Customize the appearance of the suggestion box
            suggestionsBoxDecoration: SuggestionsBoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              color: Colors.white, // Set the background color of the suggestion box
            ),
            // Show suggestions immediately on focus
            getImmediateSuggestions: true,
            // Automatically flip the suggestion box direction based on available space
            autoFlipDirection: true,
          ),


        ),



      ],
    );
  }

  Widget buildNonEditableText(String labelText, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0), // Add content padding
          child: SizedBox(
            height: 50,
            child: TextFormField(
              controller: controller,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              style: const TextStyle(fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }

  void deleteRow(RowData rowData) {
    setState(() {
      rowDataList.remove(rowData);
    });
  }


  void _calculateSubTotal() {
    String? totalValue = _totalController.text;
    String? discountValue = _discountController.text;

    if (totalValue != null && discountValue != null) {
      try {
        int totalAmount = int.tryParse(totalValue) ?? 0;
        int discount = int.tryParse(discountValue) ?? 0;
        int subTotal = totalAmount - discount;

        setState(() {
          _subTotalController.text = subTotal.toString();
        });
      } catch (e) {
        // Handle parsing errors if needed
      }
    }
  }

  void _calculateBalance() {
    String? subTotalValue = _subTotalController.text;
    String? paymentValue = _paymentController.text;

    if (subTotalValue != null && paymentValue != null) {
      try {
        int subTotal = int.tryParse(subTotalValue) ?? 0;
        int payment = int.tryParse(paymentValue) ?? 0;
        int balance = subTotal - payment;

        setState(() {
          _balanceController.text = balance.toString();
        });
      } catch (e) {
        // Handle parsing errors if needed
      }
    }
  }

  void calculateAmount(TextEditingController qtyController,
      TextEditingController rateController,
      TextEditingController amountController,
      RowData rowData) {
    String? qty = qtyController.text;
    String? rate = rateController.text;

    if (qty != null && rate != null) {
      try {
        int qtyValue = int.tryParse(qty) ?? 0;
        int rateValue = int.tryParse(rate) ?? 0;
        int amount = qtyValue * rateValue;
        amountController.text = amount.toString();
        // After calculating individual amounts, recalculate the total
        //_calculateTotal();
        _calculateSubTotal();
        _calculateBalance();
      } catch (e) {
        amountController.text = '';
      }
    } else {
      amountController.text = '';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd-MMM-yyyy');
    return formatter.format(now);
  }


//   String getCurrentTimeInPakistan() {
//     // Initialize the time zone data
//     tz.initializeTimeZones();
//
//     // Get the location for Asia/Karachi
//     final Location pakistanTimeZone = getLocation('Asia/Karachi');
//
//     // Create a DateTime object representing the current date and time in UTC
//     DateTime nowUtc = DateTime.now().toUtc();
//
//     // Convert the UTC time to the Pakistan time zone
//     TZDateTime nowPakistan = TZDateTime.from(nowUtc, pakistanTimeZone);
//
//     // Format the date and time using the desired format
//     String formattedDateTime = DateFormat('dd-MMM-yyyy [HH:mm a]').format(nowPakistan);
//
//     return formattedDateTime;
//   }
}
class RowData {
  final int serialNumber;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController amountController;
  String itemsDropdownValue;
  ProductsModel? selectedProduct;
  RowData({
  required this.serialNumber,
  required this.qtyController,
  required this.rateController,
  required this.amountController,
  required this.itemsDropdownValue,
  required this.selectedProduct,
  });
}