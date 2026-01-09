import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce_app/models/cart_item.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final SharedPreferences prefs;

  CartCubit(this.prefs) : super(const CartState()) {
    _loadCart();
  }

  void _loadCart() {
    final cartJson = prefs.getString('cart');
    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(cartJson);
        final items = decoded.map((json) => CartItem.fromJson(json)).toList();
        emit(CartState(items: items));
      } catch (e) {
        emit(const CartState());
      }
    }
  }

  Future<void> _saveCart() async {
    final cartJson = json.encode(state.items.map((item) => item.toJson()).toList());
    await prefs.setString('cart', cartJson);
  }

  void addItem({
    required int productId,
    required String title,
    required double price,
    required String image,
  }) {
    final existingIndex = state.items.indexWhere((item) => item.productId == productId);
    List<CartItem> updatedItems;

    if (existingIndex >= 0) {
      updatedItems = List.from(state.items);
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      updatedItems = [
        ...state.items,
        CartItem(
          productId: productId,
          title: title,
          price: price,
          image: image,
          quantity: 1,
        ),
      ];
    }

    emit(state.copyWith(items: updatedItems));
    _saveCart();
  }

  void removeItem(int productId) {
    final updatedItems = state.items
        .where((item) => item.productId != productId)
        .toList();
    
    emit(state.copyWith(items: updatedItems));
    _saveCart();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems));
    _saveCart();
  }

  void clearCart() {
    emit(const CartState());
    _saveCart();
  }

  bool isInCart(int productId) {
    return state.items.any((item) => item.productId == productId);
  }

  int getQuantity(int productId) {
    final item = state.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: 0,
        title: '',
        price: 0,
        image: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}