import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../constants.dart';

import '../../../constants.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/product.dart';
import '../../../widgets/cart_tile.dart';
import '../../../widgets/check_out_box.dart';
import '../../../widgets/product_widgets/add_to_cart.dart';
import '../../../widgets/product_widgets/appbar.dart';
import '../../../widgets/product_widgets/image_slider.dart';
import '../../../widgets/product_widgets/information.dart';
import '../../../widgets/product_widgets/product_desc.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: kcontentColor,
        centerTitle: true,
        title: const Text(
          "My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: IconButton(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            icon: const Icon(Ionicons.chevron_back),
          ),
        ),
      ),
      bottomSheet: CheckOutBox(
        items: cartItems,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) => CartTile(
          item: cartItems[index],
          onRemove: () {
            if (cartItems[index].quantity != 1) {
              setState(() {
                cartItems[index].quantity--;
              });
            }
          },
          onAdd: () {
            setState(() {
              cartItems[index].quantity++;
            });
          },
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemCount: cartItems.length,
      ),
    );
  }
}
