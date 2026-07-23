class Product {
  final int id;
  final String namaProduct;
  final String? jenisUkiran;
  final String? ukuran;
  final String? bahan;
  final String? motif;
  final String? deskripsi;
  final String? gambar;
  final double estimasiHarga;

  Product({
    required this.id,
    required this.namaProduct,
    this.jenisUkiran,
    this.ukuran,
    this.bahan,
    this.motif,
    this.deskripsi,
    this.gambar,
    required this.estimasiHarga,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      namaProduct: json['nama_product'] ?? '',
      jenisUkiran: json['jenis_ukiran'],
      ukuran: json['ukuran'],
      bahan: json['bahan'],
      motif: json['motif'],
      deskripsi: json['deskripsi'],
      gambar: json['gambar'],
      estimasiHarga: double.tryParse(json['estimasi_harga'].toString()) ?? 0.0,
    );
  }
}