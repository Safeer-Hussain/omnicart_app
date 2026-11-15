import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/seeded_catalog.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/delivery_address.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('omnicart.db');
    return _database!;
  }

  // Allow injecting custom database in tests
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        brand TEXT NOT NULL,
        category TEXT NOT NULL,
        price_usd REAL NOT NULL,
        original_price_usd REAL NOT NULL,
        rating REAL NOT NULL,
        review_count INTEGER NOT NULL,
        is_flash_sale INTEGER NOT NULL,
        is_express INTEGER NOT NULL,
        dark_store_stock INTEGER NOT NULL,
        aisle_location TEXT NOT NULL,
        upc_barcode TEXT NOT NULL,
        competitor_price_usd REAL NOT NULL,
        competitor_name TEXT NOT NULL,
        available_colors TEXT NOT NULL,
        available_sizes TEXT NOT NULL,
        selected_color TEXT NOT NULL,
        selected_size TEXT NOT NULL,
        specs_json TEXT NOT NULL,
        image_asset TEXT NOT NULL,
        is_wishlisted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        selected_color TEXT NOT NULL,
        selected_size TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        is_saved_for_later INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        items_json TEXT NOT NULL,
        subtotal_usd REAL NOT NULL,
        discount_usd REAL NOT NULL,
        tax_usd REAL NOT NULL,
        shipping_fee_usd REAL NOT NULL,
        total_usd REAL NOT NULL,
        promo_code TEXT,
        address_json TEXT NOT NULL,
        delivery_speed TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        courier_name TEXT NOT NULL,
        courier_phone TEXT NOT NULL,
        courier_lat REAL NOT NULL,
        courier_lng REAL NOT NULL,
        courier_progress REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        rating REAL NOT NULL,
        date TEXT NOT NULL,
        comment TEXT NOT NULL,
        is_verified INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE addresses (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        street_address TEXT NOT NULL,
        city TEXT NOT NULL,
        postal_code TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> seedInitialData() async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      final batch = db.batch();

      for (final p in SeededCatalog.initialProducts) {
        batch.insert('products', {
          'id': p.id,
          'name': p.name,
          'description': p.description,
          'brand': p.brand,
          'category': p.category,
          'price_usd': p.priceUsd,
          'original_price_usd': p.originalPriceUsd,
          'rating': p.rating,
          'review_count': p.reviewCount,
          'is_flash_sale': p.isFlashSale ? 1 : 0,
          'is_express': p.isExpressDelivery ? 1 : 0,
          'dark_store_stock': p.darkStoreStock,
          'aisle_location': p.aisleLocation,
          'upc_barcode': p.upcBarcode,
          'competitor_price_usd': p.competitorPriceUsd,
          'competitor_name': p.competitorName,
          'available_colors': jsonEncode(p.availableColors),
          'available_sizes': jsonEncode(p.availableSizes),
          'selected_color': p.selectedColor,
          'selected_size': p.selectedSize,
          'specs_json': jsonEncode(p.specs),
          'image_asset': p.imageAsset,
          'is_wishlisted': 0,
        });

        final initialReviews = SeededCatalog.initialReviewsForProduct(p.id);
        for (final r in initialReviews) {
          batch.insert('reviews', r.toMap());
        }
      }

      for (final addr in SeededCatalog.defaultAddresses) {
        batch.insert('addresses', addr.toMap());
      }

      await batch.commit(noResult: true);
    }
  }

  // --- PRODUCTS ---
  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products');
    return rows.map(_mapRowToProduct).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _mapRowToProduct(rows.first);
  }

  Future<Product?> getProductByUpc(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'upc_barcode = ?',
      whereArgs: [barcode],
    );
    if (rows.isEmpty) return null;
    return _mapRowToProduct(rows.first);
  }

  Future<void> updateWishlistStatus(String id, bool isWishlisted) async {
    final db = await database;
    await db.update(
      'products',
      {'is_wishlisted': isWishlisted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Product _mapRowToProduct(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String,
      brand: row['brand'] as String,
      category: row['category'] as String,
      priceUsd: (row['price_usd'] as num).toDouble(),
      originalPriceUsd: (row['original_price_usd'] as num).toDouble(),
      rating: (row['rating'] as num).toDouble(),
      reviewCount: (row['review_count'] as num).toInt(),
      isFlashSale: (row['is_flash_sale'] as int) == 1,
      isExpressDelivery: (row['is_express'] as int) == 1,
      darkStoreStock: (row['dark_store_stock'] as num).toInt(),
      aisleLocation: row['aisle_location'] as String,
      upcBarcode: row['upc_barcode'] as String,
      competitorPriceUsd: (row['competitor_price_usd'] as num).toDouble(),
      competitorName: row['competitor_name'] as String,
      availableColors: List<String>.from(
        jsonDecode(row['available_colors'] as String) as List,
      ),
      availableSizes: List<String>.from(
        jsonDecode(row['available_sizes'] as String) as List,
      ),
      selectedColor: row['selected_color'] as String,
      selectedSize: row['selected_size'] as String,
      specs: Map<String, String>.from(
        jsonDecode(row['specs_json'] as String) as Map,
      ),
      imageAsset: row['image_asset'] as String,
      isWishlisted: (row['is_wishlisted'] as int? ?? 0) == 1,
    );
  }

  // --- REVIEWS ---
  Future<List<Review>> getReviewsForProduct(String productId) async {
    final db = await database;
    final rows = await db.query(
      'reviews',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return rows.map((r) => Review.fromMap(r)).toList();
  }

  Future<void> insertReview(Review review) async {
    final db = await database;
    await db.insert(
      'reviews',
      review.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Increment review count on product
    await db.rawUpdate(
      '''
      UPDATE products 
      SET review_count = review_count + 1 
      WHERE id = ?
    ''',
      [review.productId],
    );
  }

  // --- CART ITEMS ---
  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final rows = await db.query('cart_items');
    final List<CartItem> items = [];
    for (final row in rows) {
      final p = await getProductById(row['product_id'] as String);
      if (p != null) {
        items.add(
          CartItem(
            id: row['id'] as String,
            product: p,
            selectedColor: row['selected_color'] as String,
            selectedSize: row['selected_size'] as String,
            quantity: (row['quantity'] as num).toInt(),
            isSavedForLater: (row['is_saved_for_later'] as int) == 1,
          ),
        );
      }
    }
    return items;
  }

  Future<void> saveCartItem(CartItem item) async {
    final db = await database;
    await db.insert('cart_items', {
      'id': item.id,
      'product_id': item.product.id,
      'selected_color': item.selectedColor,
      'selected_size': item.selectedSize,
      'quantity': item.quantity,
      'is_saved_for_later': item.isSavedForLater ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeCartItem(String id) async {
    final db = await database;
    await db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_items');
  }

  // --- ORDERS ---
  Future<List<CustomerOrder>> getOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'created_at DESC');
    return rows.map(_mapRowToOrder).toList();
  }

  Future<void> insertOrder(CustomerOrder order) async {
    final db = await database;
    final itemsList = order.items
        .map(
          (i) => {
            'id': i.id,
            'product_id': i.product.id,
            'product_name': i.product.name,
            'price_usd': i.product.priceUsd,
            'image_asset': i.product.imageAsset,
            'selected_color': i.selectedColor,
            'selected_size': i.selectedSize,
            'quantity': i.quantity,
            'aisle_location': i.product.aisleLocation,
          },
        )
        .toList();

    await db.insert('orders', {
      'id': order.id,
      'items_json': jsonEncode(itemsList),
      'subtotal_usd': order.subtotalUsd,
      'discount_usd': order.discountUsd,
      'tax_usd': order.taxUsd,
      'shipping_fee_usd': order.shippingFeeUsd,
      'total_usd': order.totalUsd,
      'promo_code': order.promoCode,
      'address_json': jsonEncode(order.deliveryAddress.toMap()),
      'delivery_speed': order.deliverySpeed,
      'payment_method': order.paymentMethod,
      'status': order.status.name,
      'courier_name': order.courierName,
      'courier_phone': order.courierPhone,
      'courier_lat': order.courierLat,
      'courier_lng': order.courierLng,
      'courier_progress': order.courierProgress,
      'created_at': order.createdAtMillis,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderFulfillmentStatus status,
    double progress,
    double lat,
    double lng,
  ) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'status': status.name,
        'courier_progress': progress,
        'courier_lat': lat,
        'courier_lng': lng,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  CustomerOrder _mapRowToOrder(Map<String, dynamic> row) {
    final rawItems = jsonDecode(row['items_json'] as String) as List;
    final items = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;
      final placeholderProduct = Product(
        id: m['product_id'] as String,
        name: m['product_name'] as String,
        description: '',
        brand: '',
        category: '',
        priceUsd: (m['price_usd'] as num).toDouble(),
        originalPriceUsd: (m['price_usd'] as num).toDouble(),
        rating: 5.0,
        reviewCount: 1,
        isFlashSale: false,
        isExpressDelivery: true,
        darkStoreStock: 10,
        aisleLocation: (m['aisle_location'] as String?) ?? 'Aisle 1',
        upcBarcode: '',
        competitorPriceUsd: 0,
        competitorName: '',
        availableColors: const [],
        availableSizes: const [],
        selectedColor: (m['selected_color'] as String?) ?? '',
        selectedSize: (m['selected_size'] as String?) ?? '',
        specs: const {},
        imageAsset:
            (m['image_asset'] as String?) ?? 'assets/images/tech_audio.png',
      );
      return CartItem(
        id: m['id'] as String,
        product: placeholderProduct,
        selectedColor: (m['selected_color'] as String?) ?? '',
        selectedSize: (m['selected_size'] as String?) ?? '',
        quantity: (m['quantity'] as num).toInt(),
      );
    }).toList();

    final addressMap =
        jsonDecode(row['address_json'] as String) as Map<String, dynamic>;
    final address = DeliveryAddress.fromMap(addressMap);

    final statusName = row['status'] as String;
    final status = OrderFulfillmentStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => OrderFulfillmentStatus.confirmed,
    );

    return CustomerOrder(
      id: row['id'] as String,
      items: items,
      subtotalUsd: (row['subtotal_usd'] as num).toDouble(),
      discountUsd: (row['discount_usd'] as num).toDouble(),
      taxUsd: (row['tax_usd'] as num).toDouble(),
      shippingFeeUsd: (row['shipping_fee_usd'] as num).toDouble(),
      totalUsd: (row['total_usd'] as num).toDouble(),
      promoCode: row['promo_code'] as String?,
      deliveryAddress: address,
      deliverySpeed: row['delivery_speed'] as String,
      paymentMethod: row['payment_method'] as String,
      status: status,
      courierName: row['courier_name'] as String,
      courierPhone: row['courier_phone'] as String,
      courierLat: (row['courier_lat'] as num).toDouble(),
      courierLng: (row['courier_lng'] as num).toDouble(),
      courierProgress: (row['courier_progress'] as num).toDouble(),
      createdAtMillis: (row['created_at'] as num).toInt(),
    );
  }

  // --- ADDRESSES ---
  Future<List<DeliveryAddress>> getAddresses() async {
    final db = await database;
    final rows = await db.query('addresses');
    return rows.map((r) => DeliveryAddress.fromMap(r)).toList();
  }

  Future<void> insertAddress(DeliveryAddress address) async {
    final db = await database;
    if (address.isDefault) {
      await db.update('addresses', {'is_default': 0});
    }
    await db.insert(
      'addresses',
      address.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
