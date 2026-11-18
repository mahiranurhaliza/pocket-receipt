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
  final DateTime date;
  final double totalAmount;
  final String category;
  final String sourceOfFunds;
  final String? imagePath;
  final List<ReceiptItem> items;

  ReceiptModel({
    this.id,
    required this.storeName,
    required this.date,
    required this.totalAmount,
    required this.category,
    this.sourceOfFunds = 'Cash',
    this.imagePath,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'category': category,
      'source_of_funds': sourceOfFunds,
      'image_path': imagePath,
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map, {List<ReceiptItem> items = const []}) {
    return ReceiptModel(
      id: map['id'],
      storeName: map['store_name'],
      date: DateTime.parse(map['date']),
      totalAmount: (map['total_amount'] as num).toDouble(),
      category: map['category'] ?? 'Belanja',
      sourceOfFunds: map['source_of_funds'] ?? 'Cash',
      imagePath: map['image_path'],
      items: items,
    );
  }
}