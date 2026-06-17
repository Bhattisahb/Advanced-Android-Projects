import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/orders_model.dart';
import 'package:provider/provider.dart';

import '../../providers/products_provider.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';
import 'order_detail_screen.dart';

class OrderWidget extends StatefulWidget {
  const OrderWidget({Key? key}) : super(key: key);

  @override
  State<OrderWidget> createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  late String orderDateToShow;

  @override
  void didChangeDependencies() {
    final ordersModel = Provider.of<OrderModel>(context);
    var orderDate = ordersModel.orderDate.toDate();
    orderDateToShow = '${orderDate.day}/${orderDate.month}/${orderDate.year}';
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final ordersModel = Provider.of<OrderModel>(context);
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productProvider = Provider.of<ProductsProvider>(context);
    final product = productProvider.findProdByIdOrNull(ordersModel.productId);
    final title = product?.title ?? ordersModel.productId;
    final imageUrl = product?.imageUrl ?? ordersModel.imageUrl;
    return ListTile(
      subtitle: Text(
          'Line total: ${formatPkr(double.tryParse(ordersModel.price) ?? 0)}'),
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailScreen(order: ordersModel),
          ),
        );
      },
      leading: FancyShimmerImage(
        width: size.width * 0.2,
        imageUrl: imageUrl,
        boxFit: BoxFit.fill,
      ),
      title: TextWidget(
          text: '$title  x${ordersModel.quantity}', color: color, textSize: 18),
      trailing: TextWidget(text: orderDateToShow, color: color, textSize: 18),
    );
  }
}
