import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:grocery_app/consts/order_fulfillment.dart';

class OrderModel with ChangeNotifier {
  final String orderId;
  final String userId;
  final String productId;
  final String userName;

  /// Line total for this document (one cart line).
  final String price;
  final String imageUrl;
  final String quantity;
  final Timestamp orderDate;

  /// Same for every line created in one checkout batch (when present).
  final String? groupOrderId;

  /// Whole-cart total at checkout (duplicated on each line doc).
  final String totalOrderPrice;

  final String? paymentStatus;
  final String? paymentMethod;
  final Timestamp? paidAt;

  /// Set when admin confirms payment (bank / JazzCash / EasyPaisa).
  final String? paymentReceivedVia;

  final String fulfillmentStatus;
  final String shippingAddress;
  final String adminNotes;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.userName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.orderDate,
    this.groupOrderId,
    required this.totalOrderPrice,
    this.paymentStatus,
    this.paymentMethod,
    this.paidAt,
    this.paymentReceivedVia,
    this.fulfillmentStatus = FulfillmentStatuses.pending,
    this.shippingAddress = '',
    this.adminNotes = '',
  });
}
