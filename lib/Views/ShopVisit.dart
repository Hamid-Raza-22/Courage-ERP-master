import 'dart:convert' show base64Decode;
import 'package:flutter/foundation.dart' show Key, Uint8List, kDebugMode;
import 'package:flutter/material.dart' show Align, Alignment, AppBar, Axis, BorderRadius, BorderSide, BoxDecoration, BoxFit, BuildContext, Card, Center, Checkbox, Colors, Column, Container, CrossAxisAlignment, DataCell, DataColumn, DataRow, DataTable, EdgeInsets, ElevatedButton, Expanded, FocusNode, FocusScope, Form, FormState, GestureDetector, GlobalKey, Icon, Icons, Image, InputBorder, InputDecoration, Key, ListTile, MainAxisAlignment, MaterialPageRoute, MediaQuery, Navigator, OutlineInputBorder, Padding, RoundedRectangleBorder, RouteSettings, Row, Scaffold, ScaffoldMessenger, SingleChildScrollView, SizedBox, SnackBar, Stack, State, StatefulWidget, Text, TextEditingController, TextField, TextFormField, TextInputType, TextStyle, ValueListenableBuilder, ValueNotifier, Widget, imageCache;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, LocationAccuracy, Position;
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:nanoid/async.dart';
import 'package:order_booking_shop/API/Globals.dart';
import 'package:order_booking_shop/View_Models/StockCheckItems.dart';
import 'package:order_booking_shop/Views/HomePage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/DatabaseOutputs.dart';
import '../Databases/DBHelper.dart';
import '../Models/ShopVisitModels.dart';
import '../Models/StockCheckItems.dart';
import '../View_Models/OrderViewModels/ProductsViewModel.dart';
import '../View_Models/ShopVisitViewModel.dart';
import 'FinalOrderBookingPage.dart';



class ShopImageController extends GetxController {
  final Rx<File?> _shopimageFile = Rx<File?>(null);

  File? get shopImageFile => _shopimageFile.value;

  void updateShopImageFile(File? file) {
    _shopimageFile.value = file;
  }
  Future<void> loadImageFile(String base64Image) async {
    Uint8List bytesImage = base64Decode(base64Image);
    // await Future.delayed(const Duration(seconds: 5));

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/image.jpg').writeAsBytes(bytesImage);
    // await Future.delayed(const Duration(seconds: 2));

    // Update the _shopimageFile value using the controller

    updateShopImageFile(file); // directly call the method

    update();

    if (kDebugMode) {
      print('Shop Image File: ${_shopimageFile.value}');
      print('Shop Image File: $_shopimageFile');
    }
  }
  void clearShopImageFile() {
    _shopimageFile.value = null;
  }
}


class ShopVisit extends StatefulWidget {

// Add this line

  const ShopVisit({
    Key? key,


  }) : super(key: key);

  @override
  ShopVisitState createState() => ShopVisitState();
}

class ShopVisitState extends State<ShopVisit> {
  final shopImageFileProvider = StateProvider<File?>((ref) => null);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //final productsViewModel = Get.put(ProductsViewModel());
  TextEditingController ShopNameController = TextEditingController();
  final TextEditingController _brandDropDownController = TextEditingController();
  TextEditingController BookerNameController = TextEditingController();
  TextEditingController ShopAddressController = TextEditingController();

  final ShopImageController _shopImageController = Get.put(ShopImageController());
  final Rx<File?> shopimageFile = Rx<File?>(null); // Use Rx to manage File state
  final TextEditingController _searchController = TextEditingController();
  List<DataRow> filteredRows = [];
  final shopisitViewModel = Get.put(ShopVisitViewModel());
  final stockcheckitemsViewModel = Get.put(StockCheckItemsViewModel());

  int? shopVisitId;
  int? stockcheckitemsId;
  String selectedShopOwner = '';
  String? selectedShopAddress = '';
  String? selectedOwnerContact= '';
  String selectedShopOrderNo = '';
  String? selectedShopCity='';
  List<Map<String, dynamic>> shopOwners = [];
  final Products productsController = Get.put(Products());
  DBHelper dbHelper = DBHelper();
  List<String> dropdownItems5 = [];
  List<String> dropdownItems = [];
  List<String> brandDropdownItems = [];
  String selectedItem ='';
  String? selectedDropdownValue;
  String selectedBrand = '';
  List<String> selectedProductNames = [];
  // Add an instance of ProductsViewModel
  ProductsViewModel productsViewModel = Get.put(ProductsViewModel());
  // String? latestOrderNo =  dbHelper.getLatestOrderNo(userId);
  int ShopVisitsSerialCounter = highestSerial ?? 0;
  late ValueNotifier<String> shopNameNotifier;
  // int? serialCounter;

  double currentBalance = 0.0;
  String currentUserId = '';
  String shopVisitCurruntMonth = DateFormat('MMM').format(DateTime.now());
  get shopData => null;
  // List<StockCheckItem> stockCheckItems = [StockCheckItem()];
  int serialNo = 1;
  final shopVisitViewModel = Get.put(ShopVisitViewModel());
  //final stockcheckitemsViewModel =Get.put(StockCheckItemsViewModel());
  final ImagePicker _imagePicker = ImagePicker();
  File? _imageFile;
  // File? _shopimageFile;
  bool checkboxValue1 = false;
  bool checkboxValue2 = false;
  bool checkboxValue3 = false;
  bool checkboxValue4 = false;
  String feedbackController = '';
  dynamic latitude = '';
  dynamic longitude ='';
  bool isButtonPressed = false;
  bool isButtonPressed2 = false;
  List<DataRow> rows = [];
  final FocusNode _shopNameFocusNode = FocusNode();
  // Uint8List? _imageBytes;
  void filterData(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRows = [];
      });
    } else {
      List<DataRow> tempList = [];
      String  lowerCaseQuery =query.toLowerCase();
      for (DataRow row in productsController.rows) {
        for (DataCell cell in row.cells) {
          if (cell.child is Text && (cell.child as Text).data!.toLowerCase().contains(lowerCaseQuery)) {
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
  void navigateToNewOrderBookingPage(String selectedBrandName) async {
    // Set the selected shop name without navigation
    setState(() {
      selectedItem = selectedBrandName;
    });
  }
  @override
  void initState() {

    super.initState();
    data();
    // serialCounter=(dbHelper.getLatestSerialNo(userId) as int?)!;
  shopNameNotifier = ValueNotifier<String>(selectedItem);


    //selectedDropdownValue = dropdownItems[0]; // Default value
    _fetchBrandItemsFromDatabase();
    //fetchShopData();
    fetchShopNames();
    onCreatee();
    _loadCounter();
    //  _saveCounter();
    fetchProductsNamesByBrand();
    saveCurrentLocation();
    _checkUserIdAndFetchShopNames();
    shopNameNotifier.addListener(() {
      updateShopImage();
      if (kDebugMode) {
        print('shopNameNotifier value changed to: ${shopNameNotifier.value}');
      }
    });
    shopNameNotifier.addListener(() {
      _onProductChange();
      if (kDebugMode) {
        print('State changed ');
      }});
    // Add listener to FocusNode
    _shopNameFocusNode.addListener(() {
      if (_shopNameFocusNode.hasFocus) {
        _shopImageController.clearShopImageFile();
        ShopNameController.clear();
      }
    });
   // _shopimageFile.value;
   //  _shopImageController._shopimageFile;
    // productsController.controllers.clear();
    // removeSavedValues(index);
    if (kDebugMode) {
      print(userId);
      print(highestSerial);
    }
  }
  data(){
    DBHelper dbHelper = DBHelper();
    if (kDebugMode) {
      print('data0');
    }
    dbHelper.getHighestSerialNo();
  }
  Future<void> removeSavedValues(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove itemDesc and qty from SharedPreferences
    await prefs.remove('itemDesc$index');
    await prefs.remove('qty$index');

    if (kDebugMode) {
      print('Removed itemDesc$index and qty$index from SharedPreferences');
    }
  }


  Future<void> _checkUserIdAndFetchShopNames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDesignation = prefs.getString('userDesignation');

    if (userDesignation == 'ASM' && userDesignation == 'SPO' && userDesignation == 'SOS') {
      await fetchShopNames();

    } else {
      await fetchShopNamesAll();

    }
  }

  Future<void> fetchShopNames() async {

    List<dynamic> shopNames = await dbHelper.getShopNamesForCity();
    shopOwners = (await dbHelper.getOwnersDB())!;
    setState(() {
      // Explicitly cast each element to String

      dropdownItems = shopNames.map((dynamic item) => item.toString()).toSet().toList();
    });
  }


  Future<void> fetchShopNamesAll() async {

    List<dynamic> shopNames = await dbHelper.getShopNames();
    shopOwners = (await dbHelper.getOwnersDB())!;
    setState(() {
      // Explicitly cast each element to String

      dropdownItems = shopNames.map((dynamic item) => item.toString()).toSet().toList();
    });
  }

  Future<void> saveCurrentLocation() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude  = position.latitude ;
        longitude = position.longitude ;


        if (kDebugMode) {
          print('Latitude: $latitude, Longitude: $longitude');
        }

        // Using geocoding to convert latitude and longitude to an address
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
        Placemark currentPlace = placemarks[0];

        String address1 = "${currentPlace.thoroughfare} ${currentPlace.subLocality}, ${currentPlace.locality}${currentPlace.postalCode}, ${currentPlace.country}";
        address = address1;

        if (kDebugMode) {
          print('Address is: $address1');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting location:$e');
        }
      }
    } else {
      if (kDebugMode) {
        print('Location permission is not granted');
      }
    }
  }

  _loadCounter() async {
    String currentMonth = DateFormat('MMM').format(DateTime.now());
    if (shopVisitCurruntMonth != currentMonth) {
      // Reset serial counter when the month changes
      ShopVisitsSerialCounter = 1;
      shopVisitCurruntMonth = currentMonth;
    }
    //serialCounter=highestSerial;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      //  serialCounter++;
      ShopVisitsSerialCounter = (prefs.getInt('serialCounter') ?? highestSerial?? 1) ;
      shopVisitCurruntMonth = prefs.getString('currentMonth') ?? shopVisitCurruntMonth;
      currentUserId = prefs.getString('currentUserId') ?? ''; // Add this line
    });
    if (kDebugMode) {
      print('SR:$ShopVisitsSerialCounter');
    }
  }

  _saveCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('serialCounter', ShopVisitsSerialCounter);
    await prefs.setString('currentMonth', shopVisitCurruntMonth);
    await prefs.setString('currentUserId', currentUserId); // Add this line
  }

  String generateNewOrderId( String userId) {
    String currentMonth = DateFormat('MMM').format(DateTime.now());

    if (currentUserId != userId) {
      // Reset serial counter when the userId changes
      ShopVisitsSerialCounter = highestSerial??1;
      currentUserId = userId;
    }

    if (shopVisitCurruntMonth != currentMonth) {
      // Reset serial counter when the month changes
      ShopVisitsSerialCounter = 1;
      shopVisitCurruntMonth = currentMonth;
    }
//set state
    String orderId =
        "$userId-$currentMonth-${ShopVisitsSerialCounter.toString().padLeft(3, '0')}";
    ShopVisitsSerialCounter++;
    _saveCounter(); // Save the updated counter value, current month, and userId
    return orderId;
  }


  Future<void> onCreatee() async {
    DatabaseOutputs db = DatabaseOutputs();
    await db.showShopVisit();
    await db.showStockCheckItems();

    // DatabaseOutputs outputs = DatabaseOutputs();
    //  outputs.checkFirstRun();
  }


  // Method to fetch brand items from the database.
  void _fetchBrandItemsFromDatabase() async {
    DBHelper dbHelper = DBHelper();
    List<String> brandItems = await dbHelper.getBrandItems();

    // Remove duplicates from the shopNames list
    List<String> uniqueBrandNames = brandItems.toSet().toList();

    // Set the retrieved brand items in the state.
    setState(() {
      brandDropdownItems = uniqueBrandNames;
    });
  }
  Future<void> saveImage()  async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/captured_image.jpg';

      // Compress the image76
      Uint8List? compressedImageBytes = await FlutterImageCompress.compressWithFile(
        _imageFile!.path,
        minWidth: 400,
        minHeight: 600,
        quality:40,
      );

      // Save the compressed image
      await File(filePath).writeAsBytes(compressedImageBytes!);

      if (kDebugMode) {
        print('Compressed image saved successfully at $filePath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing and saving image: $e');
      }
    }
  }


  Widget buildShopImageStack() {
    return ValueListenableBuilder<String>(
      valueListenable: shopNameNotifier,
      builder: (context, shopName, child) {
        return Obx(() => Stack(
          alignment: Alignment.center,
          children: [
            if (_shopImageController.shopImageFile != null)
              Center(
                child: Image.file(
                  _shopImageController.shopImageFile!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (_shopImageController.shopImageFile == null)
              Center(
                child: Container(
                  height: 200,
                  width: 200,
                  color: Colors.grey,
                  child: const Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),

          ],
        ));
      },
    );
  }
  Future<void> updateShopImage() async {
    for (var owner in shopOwners) {
      if (owner['shop_name'] == shopNameNotifier.value) {
        selectedShopOwner = owner['owner_name'];
        selectedOwnerContact = owner['phone_no'];
        selectedShopCity= owner['city'];
        selectedShopAddress= owner['shop_address'];
        ShopAddressController.text = selectedShopAddress ?? 'Not Address';
        String base64Image = owner['images'];
       await _shopImageController.loadImageFile(base64Image);
       if (kDebugMode) {
         print("selectedShopCity:$selectedShopCity");
       }

       await _onProductChange();
        buildShopImageStack();

      }
    }
  }
  Future<void> _onProductChange() async {
    setState(() {}); // Update UI when products change
  }
  @override
  void dispose() {
    _shopImageController.clearShopImageFile();
    ShopNameController.dispose(); // Clear the text in the shop name field

    _shopNameFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }
  @override

    Widget build(BuildContext context) {

      ShopNameController.text= selectedItem;
      BookerNameController.text= userNames;

      return ProviderScope(

          child: Scaffold(
            appBar: AppBar(
              title: const Text('Shop Visit'),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        ' Date: ${_getFormattedDate()}',
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Shop Name',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                 GestureDetector(
                  onTap: () {
                    _shopImageController.clearShopImageFile();
                    ShopNameController.clear();
                  },
                  child: SizedBox(
                      height: 30,
                      child: TypeAheadField<String>(
                        textFieldConfiguration: TextFieldConfiguration(

                          focusNode: _shopNameFocusNode, // Assign the focus node here
                          controller: TextEditingController(text: selectedItem),
                          decoration: InputDecoration(
                            enabled: false,
                            hintText: '---Select Shop---',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 6.0,horizontal: 8.0),
                          ),
                        ),
                        suggestionsCallback: (pattern) {
                          return dropdownItems
                              .where((item) => item.toLowerCase().contains(pattern.toLowerCase()))
                              .toList();
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                          );
                        },
                        onSuggestionSelected: (suggestion) async {
                          // Validate that the selected item is from the list
                          if (dropdownItems.contains(suggestion)) {
                            setState(() {
                              imageCache.clear();
                              selectedItem = suggestion;
                             // shopName = selectedItem;
                              shopNameNotifier.value = selectedItem; // Update the shop name
                            });
                            updateShopImage();

                            productsController.rows;
                            productsController.fetchProducts();
                            for (int i = 0; i < productsController.rows.length; i++) {
                              removeSavedValues(i);
                            }


                          }
                        },
                      ),
                    ),),
                    const SizedBox(height: 10.0),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Shop Address',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: TextFormField(enabled: true, readOnly: true,
                        controller: ShopAddressController,

                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 6.0,horizontal: 8.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),

                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Add the Stack widget to overlay the warning icon on top of the image
                    const Text(
                      'Shop Image',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    buildShopImageStack(),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Booker Name',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: TextFormField(enabled: false,
                        controller: BookerNameController,

                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 6.0,horizontal: 8.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),

                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Brand',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: TypeAheadFormField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                                  enabled: false, // Set enabled to false to make it read-only
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                                controller: _brandDropDownController,
                              ),
                              suggestionsCallback: (pattern) {
                                return brandDropdownItems
                                    .where((item) => item.toLowerCase().contains(pattern.toLowerCase()))
                                    .toList();
                              },
                              itemBuilder: (context, itemData) {
                                return ListTile(
                                  title: Text(itemData),
                                );
                              },
                              onSuggestionSelected: (itemData) async {
                                // Validate that the selected item is from the list
                                if (brandDropdownItems.contains(itemData)) {
                                  setState(() {
                                    _brandDropDownController.text = itemData;
                                    globalselectedbrand = itemData;
                                  });
                                  // Call the callback to pass the selected brand to FinalOrderBookingPage
                                  // widget.onBrandItemsSelected(itemData);
                                  // if (kDebugMode) {
                                  //   print('Selected Brand: $itemData');
                                  //   print(globalselectedbrand);
                                  // }

                                  productsController.fetchProducts();
                                  for (int i = 0; i < productsController.rows.length; i++) {
                                    removeSavedValues(i);
                                  }
                                  productsController.controllers.clear();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),



                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Checklist',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '1-Stock Check (Current Balance)',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 25),
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
                                  child:Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                      side: const BorderSide(
                                        color: Colors.black, // Change the color as needed
                                        width: 1.0, // Change the width as needed
                                      ),
                                    ),
                                    child: SingleChildScrollView( // Add a vertical ScrollView
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
                                          // Add vertical scroll direction
                                          //  Obx(() =>
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columns: const [
                                                DataColumn(label: Text('Product')),
                                                DataColumn(label: Text('Quantity')),
                                              ],
                                              rows: filteredRows.isNotEmpty ? filteredRows : productsController.rows,
                                            ),
                                          ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],),
                        ),

                      ],
                    ),

                    const SizedBox(height: 20),

                    Column(
                      children: [
                        buildRow('1-Performed Store Walkthrough', checkboxValue1, (bool? value) {
                          if (value != null) {
                            setState(() {
                              checkboxValue1 = value;
                              FocusScope.of(context).unfocus();
                              // checkbox= checkboxValue1;
                            });
                          }
                        }),
                        buildRow('2-Update Store Planogram', checkboxValue2, (bool? value) {
                          if (value != null) {
                            setState(() {
                              checkboxValue2 = value;
                              FocusScope.of(context).unfocus();
                              // checkbox2= checkboxValue2;
                            });
                          }
                        }),
                        buildRow('3-Shelf tags and price signage check', checkboxValue3, (bool? value) {
                          if (value != null) {
                            setState(() {
                              checkboxValue3 = value;
                              FocusScope.of(context).unfocus();
                              //    checkbox3= checkboxValue3;
                            });
                          }
                        }),
                        buildRow('4-Expiry date on product reviewed', checkboxValue4, (bool? value) {
                          if (value != null) {
                            setState(() {
                              checkboxValue4 = value;
                              FocusScope.of(context).unfocus();
                              // checkbox4= checkboxValue4;
                            });
                          }
                        }),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final image = await _imagePicker.getImage(
                                source: ImageSource.camera,
                                imageQuality: 40, // Adjust the quality (0 to 100)
                              );

                              if (image != null) {
                                setState(() {
                                  _imageFile = File(image.path);

                                  shopData?['imagePath'] = _imageFile!.path;

                                  // // Convert the image file to bytes and store it in _imageBytes
                                  // List<int> imageBytesList = _imageFile!.readAsBytesSync();
                                  // _imageBytes = Uint8List.fromList(imageBytesList);
                                });

                                // Save only the image
                                await saveImage();

                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('No image selected.'),
                                ));
                              }
                            } catch (e) {
                              if (kDebugMode) {
                                print('Error capturing image: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('+ Add Photo'),
                        ),
                        const SizedBox(height: 10),
                        // Add the Stack widget to overlay the warning icon on top of the image
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_imageFile != null)
                              Image.file(
                                _imageFile!,
                                height: 300,
                                width: 400,
                                fit: BoxFit.cover,
                              ),
                            if (_imageFile == null)
                              const Icon(
                                Icons.warning,
                                color: Colors.red,
                                size: 48,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Feedback/ Special Note'),
                        const SizedBox(height: 20.0),
                        // Feedback or Note Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10.0),

                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Feedback or Note',
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                            onChanged: (text) {
                              setState(() {
                                feedbackController = text;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: isButtonPressed
                              ? null
                              : () async {
                            setState(() {
                              isButtonPressed = true;
                            });

                            List<String> allowedBrands = ['Kit Pack', 'Belini', 'Professional'];
                            String selectedBrand = _brandDropDownController.text.trim();

                            if (!allowedBrands.contains(selectedBrand)) {
                              Fluttertoast.showToast(
                                msg: 'Please select a valid brand (Kit Pack, Belini, Professional).',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );

                              setState(() {
                                isButtonPressed = false;
                              });
                              return;
                            }
                            if (!checkboxValue1 ||
                                !checkboxValue2 ||
                                !checkboxValue3 ||
                                !checkboxValue4) {
                              Fluttertoast.showToast(
                                msg: 'Please complete all tasks before proceeding.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );

                              setState(() {
                                checkboxValue1 = false;
                                checkboxValue2 = false;
                                checkboxValue3 = false;
                                checkboxValue4 = false;
                              });

                              setState(() {
                                isButtonPressed = false;
                              });
                              return;
                            }

                            if (_imageFile == null ||
                                ShopNameController.text.isEmpty ||
                                BookerNameController.text.isEmpty ||
                                _brandDropDownController.text.isEmpty) {
                              Fluttertoast.showToast(
                                msg: 'Please fulfill all requirements before proceeding.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                              setState(() {
                                isButtonPressed = false;
                              });
                              return;
                            }

                            String imagePath =  _imageFile!.path;
                            var id = await customAlphabet('1234567890', 10);
                            List<int> imageBytesList = await File(imagePath).readAsBytes();
                            Uint8List? imageBytes = Uint8List.fromList(imageBytesList);
                            String NewOrderId = generateNewOrderId(userId.toString());
                            OrderMasterid= NewOrderId;
                            if (kDebugMode) {
                              print(OrderMasterid);
                            }


                            shopVisitViewModel.addShopVisit(ShopVisitModel(
                              id: int.parse(id),
                              shopName: ShopNameController.text,
                              userId: userId,
                              bookerName: BookerNameController.text,
                              brand:_brandDropDownController.text,
                              city:selectedShopCity,
                              date:_getFormattedDate(),
                              feedback: feedbackController,
                              walkthrough: checkboxValue1,
                              planogram: checkboxValue2,
                              signage: checkboxValue3,
                              productReviewed: checkboxValue4,
                              address: address,
                              body: imageBytes,
                              longitude: longitude,
                              latitude: latitude,
                            ));

                            String visitId =
                            await shopVisitViewModel.fetchLastShopVisitId();
                            shopVisitId = int.parse(visitId);
                            // Extract data from DataTable rows
                            // Extract data from DataTable rows with non-zero quantities


                            List<StockCheckItemsModel> stockCheckItemsList = [];
                            SharedPreferences prefs = await SharedPreferences.getInstance();

                            for (int i = 0; i < (productsController.rows).length; i++) {
                              DataRow row = (productsController.rows)[i];
                              String itemDesc = row.cells[0].child.toString();
                              String qty = productsController.controllers[i].text; // Get the value from the controller

                              // Only add the item if qty is not null or empty
                              if (int.parse(qty) != 0) {
                                stockCheckItemsList.add(
                                  StockCheckItemsModel(
                                    shopvisitId: shopVisitId,
                                    itemDesc: itemDesc,
                                    qty: qty,
                                  ),
                                );

                                // Store itemDesc and qty into SharedPreferences
                                await prefs.setString('itemDesc$i', itemDesc);
                                await prefs.setString('qty$i', qty);
                                // Print itemDesc and qty
                                if (kDebugMode) {
                                  print('itemDesc$i: $itemDesc');
                                  print('qty$i: $qty');
                                }
                              }
                            }

                            // Call the method to add stock check items to the database
                            for (var stockCheckItems in stockCheckItemsList) {
                              await stockcheckitemsViewModel.addStockCheckItems(stockCheckItems);
                            }

                            await shopisitViewModel.postShopVisit();
                            await stockcheckitemsViewModel.postStockCheckItems();


                            // Navigate to the FinalOrderBookingPage only if all validations pass
                            Map<String, dynamic> dataToPass = {
                              'shopName': ShopNameController.text,
                              'ownerName': selectedShopOwner.toString(),
                              'selectedBrandName': _brandDropDownController.text,
                              'userName': BookerNameController.text,
                              'ownerContact': selectedOwnerContact.toString()??'No Contact',
                              //  'rowDataDetails': rowDataDetails,

                            };


                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FinalOrderBookingPage(),
                                settings: RouteSettings(arguments: dataToPass),

                              ),
                            );

                            setState(() {
                              isButtonPressed = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('+ Order Booking Form'),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: isButtonPressed2
                              ? null
                              : () async {
                            setState(() {
                             // isButtonPressed2 = true;
                            });

                            if (!checkboxValue1 ||
                                !checkboxValue2 ||
                                !checkboxValue3 ||
                                !checkboxValue4) {
                              Fluttertoast.showToast(
                                msg: 'Please complete all tasks before proceeding.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );

                              setState(() {
                                checkboxValue1 = false;
                                checkboxValue2 = false;
                                checkboxValue3 = false;
                                checkboxValue4 = false;
                              });

                              setState(() {
                                isButtonPressed2 = false;
                              });
                              return;
                            }
                            List<String> allowedBrands = ['Kit Pack', 'Belini', 'Professional'];
                            String selectedBrand = _brandDropDownController.text.trim();

                            if (!allowedBrands.contains(selectedBrand)) {
                              Fluttertoast.showToast(
                                msg: 'Please select a valid brand (Kit Pack, Belini, Professional).',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );

                              setState(() {
                                isButtonPressed = false;
                              });
                              return;
                            }

                            if (_imageFile == null ||
                                ShopNameController.text.isEmpty ||
                                BookerNameController.text.isEmpty ||
                                _brandDropDownController.text.isEmpty) {
                              Fluttertoast.showToast(
                                msg: 'Please fulfill all requirements before proceeding.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                              setState(() {
                                isButtonPressed2 = false;
                              });
                              return;
                            }

                            String imagePath = _imageFile!.path;
                            var id = await customAlphabet('1234567890', 12);
                            List<int> imageBytesList = await File(imagePath).readAsBytes();
                            Uint8List? imageBytes = Uint8List.fromList(imageBytesList);

                            shopVisitViewModel.addShopVisit(ShopVisitModel(
                              id: int.parse(id),
                              shopName: ShopNameController.text,
                              userId: userId,
                              bookerName: BookerNameController.text,
                              brand: _brandDropDownController.text,
                              city:selectedShopCity,
                              date: _getFormattedDate(),
                              feedback: feedbackController,
                              walkthrough: checkboxValue1,
                              planogram: checkboxValue2,
                              signage: checkboxValue3,
                              productReviewed: checkboxValue4,
                              address: address,
                              body: imageBytes,
                              latitude: latitude,
                              longitude: longitude,
                            ));

                            String visitId =
                            await shopisitViewModel.fetchLastShopVisitId();
                            shopVisitId = int.parse(visitId);

                            List<StockCheckItemsModel> stockCheckItemsList = [];
                            SharedPreferences prefs = await SharedPreferences.getInstance();

                            for (int i = 0; i < (productsController.rows).length; i++) {
                              DataRow row = (productsController.rows)[i];
                              String itemDesc = row.cells[0].child.toString();
                              String qty = productsController.controllers[i].text; // Get the value from the controller

                              // Only add the item if qty is not null or empty
                              if (int.parse(qty) != 0) {
                                stockCheckItemsList.add(
                                  StockCheckItemsModel(
                                    shopvisitId: shopVisitId,
                                    itemDesc: itemDesc,
                                    qty: qty,
                                  ),
                                );

                                // Store itemDesc and qty into SharedPreferences
                                await prefs.setString('itemDesc$i', itemDesc);
                                await prefs.setString('qty$i', qty);
                                // Print itemDesc and qty
                                if (kDebugMode) {
                                  print('itemDesc$i: $itemDesc');
                                  print('qty$i: $qty');
                                }
                              }
                            }


                            await shopisitViewModel.postShopVisit();
                            await stockcheckitemsViewModel.postStockCheckItems();




                            // Additional validation that everything must be filled
                            if (ShopNameController.text.isNotEmpty &&
                                BookerNameController.text.isNotEmpty &&
                                _brandDropDownController.text.isNotEmpty) {
                              Navigator.pop(context);
                              // Stop the timer on the home page
                              const HomePage();
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Please fill all fields before proceeding.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                            }

                            setState(() {
                              isButtonPressed2 = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('No Order'),
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
          )
    );
  }


  Widget buildRow(String text, bool value, void Function(bool?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              checkColor: Colors.white,
              activeColor: Colors.green,
            ),
            if (!value)
              const Icon(
                Icons.warning,
                color: Colors.red,
                size: 24,
              ),
          ],
        ),
      ],
    );
  }



  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd-MMM-yyyy');
    return formatter.format(now);
  }

  void onBrandSelected(String selectedBrand) {
    setState(() {
      _brandDropDownController.text = selectedBrand;
    });
  }

  Future<void> fetchProductsNamesByBrand() async {
    String selectedBrand = globalselectedbrand;
    DBHelper dbHelper = DBHelper();
    List<dynamic> productNames = await dbHelper.getProductsNamesByBrand(selectedBrand);

    setState(() {
      // Explicitly cast each element to String
      dropdownItems5 = productNames.map((dynamic item) => item.toString()).toSet().toList();
    });
  }
}

class StockCheckItem {
  TextEditingController itemDescriptionController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  String? selectedDropdownValue;
}


class Products extends GetxController {
  final productsViewModel = ProductsViewModel();
  RxList<DataRow> rows = <DataRow>[].obs;
  List<TextEditingController> controllers = [];

  Future<void> fetchProducts() async {
    await productsViewModel.fetchProductsByBrand(globalselectedbrand);
    var products = productsViewModel.allProducts;

    // Clear existing rows and controllers before adding new ones
    rows.clear();
    controllers.clear();

    for (var product in products) {
      var controller = TextEditingController(text: '0'); // Set default value here
      controllers.add(controller);

      FocusNode focusNode = FocusNode();

      // Listener for focus changes
      focusNode.addListener(() {
        if (!focusNode.hasFocus && controller.text.isEmpty) {
          controller.text = '0'; // Restore '0' when losing focus and text is empty
        }
      });

      // Adding a text listener to handle clear on focus
      controller.addListener(() {
        if (focusNode.hasFocus && controller.text == '0') {
          controller.clear();
        }
      });

      rows.add(DataRow(cells: [
        DataCell(Text(product.product_name ?? '')),
        DataCell(TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          onTap: () {
            if (controller.text == '0') {
              controller.clear();
            }
          },
          onChanged: (value) {
            // Yaha par 0 ki value ko remove karenge agar kuch type ho
            if (value == '0') {
              controller.clear();
            }
          },
        )),
      ]));

    }
  }
}
