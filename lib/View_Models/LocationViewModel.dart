import 'package:get/get.dart';

import '../Models/LocationModel.dart';
import '../Repositories/LocationRepository.dart';
import '../Tracker/trac.dart';


class LocationViewModel extends GetxController{

  var allLocation = <LocationModel>[].obs;
  LocationRepository locationRepository = LocationRepository();



  @override
  void onInit() {
    super.onInit();
    fetchAllLocation();
  }


  fetchAllLocation() async {
    var location = await locationRepository.getLocation();
    allLocation.value= location;

  }


  addLocation(LocationModel locationModel){
    locationRepository.add(locationModel);
    fetchAllLocation();
    //var dummy=fetchAllShop();
    // print (dummy);

  }

  putAttendance(LocationModel locationModel){
    locationRepository.update(locationModel);
    fetchAllLocation();

  }
  deleteAttendance(int id){
    locationRepository.delete(id);
    fetchAllLocation();
  }
  postLocation(){
    locationRepository.postlocationdata();
  }

}






