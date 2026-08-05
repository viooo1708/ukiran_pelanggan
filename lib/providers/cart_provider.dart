import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalHarga;
    }
    return total;
  }

  void addItem(CartItem cartItem) {
    // Cek apakah item dengan produk & catatan yang sama sudah ada
    // (Opsional: bisa langsung tambah baru atau digabung)
    _items.add(cartItem);
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int newJumlah) {
    if (newJumlah > 0) {
      _items[index].jumlah = newJumlah;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}