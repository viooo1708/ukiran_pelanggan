import 'product_model.dart';

class CartItem {
  final Product product;
  int jumlah;
  String ukuran;
  String material;
  String motif;
  String catatan;

  CartItem({
    required this.product,
    required this.jumlah,
    required this.ukuran,
    required this.material,
    required this.motif,
    required this.catatan,
  });

  double get totalHarga => product.estimasiHarga * jumlah;
}