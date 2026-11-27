class ReceiptItem {
  final String name;
  final int quantity;
  final double price; // Harga satuan produk

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;

  ReceiptItem copyWith({
    String? name,
    int? quantity,
    double? price,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap({int? receiptId}) {
    return {
      'receipt_id': ?receiptId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: (map['name'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReceiptModel {
  final int? id;
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final String category;
  final String sourceOfFunds;
  final String? imagePath;
  final String note;
  final List<ReceiptItem> items;

  const ReceiptModel({
    this.id,
    required this.storeName,
    required this.date,
    required this.totalAmount,
    this.category = 'Food & Beverages',
    this.sourceOfFunds = 'Cash',
    this.imagePath,
    this.note = '',
    this.items = const [],
  });

  ReceiptModel copyWith({
    int? id,
    String? storeName,
    DateTime? date,
    double? totalAmount,
    String? category,
    String? sourceOfFunds,
    String? imagePath,
    String? note,
    List<ReceiptItem>? items,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      sourceOfFunds: sourceOfFunds ?? this.sourceOfFunds,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'store_name': storeName,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'category': category,
      'source_of_funds': sourceOfFunds,
      'image_path': imagePath,
      'note': note,
    };
  }

  factory ReceiptModel.fromMap(
    Map<String, dynamic> map, {
    List<ReceiptItem> items = const [],
  }) {
    return ReceiptModel(
      id: (map['id'] as num?)?.toInt(),
      storeName: (map['store_name'] ?? 'Merchant').toString(),
      date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      category: (map['category'] ?? 'Food & Beverages').toString(),
      sourceOfFunds: (map['source_of_funds'] ?? 'Cash').toString(),
      imagePath: map['image_path']?.toString(),
      note: (map['note'] ?? '').toString(),
      items: items,
    );
  }
}