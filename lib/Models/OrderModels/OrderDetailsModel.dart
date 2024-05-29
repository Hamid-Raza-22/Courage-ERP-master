class OrderDetailsModel {
  dynamic? id;
  dynamic? orderMasterId;
  String? productName;
  dynamic? amount;
  dynamic? price;
  dynamic? quantity;
  dynamic? userId;


  OrderDetailsModel({
    this.id,
    this.orderMasterId,
    this.productName,
    this.amount,
    this.price,
    this.quantity,
    this.userId

  });

  factory OrderDetailsModel.fromMap(Map<dynamic, dynamic> json) {
    return OrderDetailsModel(
      id: json['id'],
      orderMasterId: json['order_master_id'],
      productName: json['productName'],
      amount: json['amount'],
      price: json['price'],
      quantity: json['quantity'],
      userId: json['userId']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_master_id':orderMasterId,
      'productName': productName,
      'amount': amount,
      'price': price,
      'quantity': quantity,
      'userId': userId
    };
  }
}

class GetOrderDetailsModel {
  dynamic? order_no;
  String? product_name;


  GetOrderDetailsModel({
    this.order_no,
    this.product_name,

  });

  factory GetOrderDetailsModel.fromMap(Map<dynamic, dynamic> json) {
    return GetOrderDetailsModel(
      order_no: json['order_no'],
      product_name: json['product_name'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_no': order_no,
      'product_name': product_name,

    };
  }
}