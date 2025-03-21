import 'package:get/get.dart';
import 'package:order_booking_shop/API/Globals.dart';
import 'package:order_booking_shop/Models/OrderModels/OrderMasterModel.dart';
import '../../Repositories/OrderRepository/OrderMasterRepository.dart';

class OrderMasterViewModel extends GetxController{

  var allOrderMaster = <OrderMasterModel>[].obs;
  var allGetOrderMaster=<GetOrderMasterModel>[].obs;
  OrderMasterRepository ordermasterRepository =OrderMasterRepository ();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    fetchAllOrderMaster();

  }

  fetchAllOrderMaster() async{
    var ordermaster = await ordermasterRepository.getShopVisit();

    allOrderMaster.value = ordermaster;
  }

  Future<void> fetchShopNames(String user_Id) async {
    try {
      String user_Id = userId;
      // Fetch products by brand from the repository
      List<GetOrderMasterModel> getordermaster = await ordermasterRepository.getShopNameOrderMasterData(user_Id);

      // Set the products in the allProducts list
      allGetOrderMaster.value = getordermaster;
    } catch (e) {
      print("Error fetching products by brand: $e");
    }
  }

  // Future<String> fetchLastOrderMasterId() async{
  //   String ordermaster = await ordermasterRepository.getLastOrderId();
  //   return ordermaster;
  // }

  addOrderMaster(OrderMasterModel ordermasterModel) async {
    ordermasterRepository.add(ordermasterModel);
    // Implementing logic to insert data into 'ownerData' table
    var dbClient = await ordermasterRepository.dbHelperOrderMaster.db;
    await dbClient!.insert('orderBookingStatusData', {
      'order_no': ordermasterModel.orderId,
      'order_date':ordermasterModel.date,
      'shop_name': ordermasterModel.shopName,
      'user_id':userId,
      'amount':ordermasterModel.total,
      'status':pending
    });
    fetchAllOrderMaster();
  }

  updateOrderMaster(OrderMasterModel ordermasterModel){
    ordermasterRepository.update(ordermasterModel);
    fetchAllOrderMaster();
  }

  deleteOrderMaster(int id){
    ordermasterRepository.delete(id);
    fetchAllOrderMaster();
  }
  postOrderMaster(){
    ordermasterRepository.postMasterTable();
  }

}