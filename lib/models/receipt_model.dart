import 'dart:convert';

class ReceiptItem {
  final String name;
  final int quantity;
  final double price;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  factory ReceiptItem.fromMap(Map<String, dynamic> map) => ReceiptItem(
        name: map['name'] ?? '',
        quantity: map['quantity'] ?? 1,
        price: (map['price'] ?? 0).toDouble(),
      );
}

class ReceiptModel {
  final int? id;
  final String storeName;
  final String category; // Contoh: Makanan, Transportasi, Belanja, Tagihan
  final DateTime date;
  final double totalAmount;
  final String? imagePath;
  final List<ReceiptItem> items;

  ReceiptModel({
    this.id,
    required this.storeName,
    required this.category,
    required this.date,
    required this.totalAmount,
    this.imagePath,
    this.items = const [],
  });

  // Mengubah objek ke format Map untuk disimpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'category': category,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'items': jsonEncode(items.map((e) => e.toMap()).toList()),
    };
  }

  // Mengubah data dari SQLite kembali menjadi objek ReceiptModel
  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decodedItems =
        map['items'] != null ? jsonDecode(map['items']) : [];

    return ReceiptModel(
      id: map['id'],
      storeName: map['storeName'] ?? 'Tanpa Nama',
      category: map['category'] ?? 'Lainnya',
      date: DateTime.parse(map['date']),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      imagePath: map['imagePath'],
      items: decodedItems.map((e) => ReceiptItem.fromMap(e)).toList(),
    );
  }
}