import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/discount.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ecommerce.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE Users (
        UserID INTEGER PRIMARY KEY AUTOINCREMENT,
        FirstName TEXT NOT NULL,
        MiddleName TEXT,
        LastName TEXT NOT NULL,
        Password TEXT NOT NULL,
        Email TEXT UNIQUE NOT NULL,
        Gender TEXT,
        DateOfBirth TEXT,
        DateJoined TEXT NOT NULL,
        UserType TEXT NOT NULL CHECK(UserType IN ('Customer', 'Admin')),
        PhoneNumber TEXT,
        ProfilePicture TEXT
      )
    ''');

    // Create Addresses table
    await db.execute('''
      CREATE TABLE Addresses (
        AddressID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER NOT NULL,
        AddressType TEXT NOT NULL CHECK(AddressType IN ('Home', 'Work', 'Other')),
        Country TEXT NOT NULL,
        City TEXT NOT NULL,
        Province TEXT NOT NULL,
        District TEXT,
        Street TEXT NOT NULL,
        BuildingNumber TEXT,
        ApartmentNumber TEXT,
        PostalCode TEXT,
        IsDefault INTEGER DEFAULT 0,
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
      )
    ''');

    // Create Products table
    await db.execute('''
      CREATE TABLE Products (
        ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT NOT NULL,
        Description TEXT,
        Price REAL NOT NULL CHECK(Price > 0),
        Amount INTEGER NOT NULL CHECK(Amount >= 0),
        Category TEXT NOT NULL,
        Size TEXT,
        Color TEXT,
        SupplierID INTEGER,
        FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
      )
    ''');

    // Create Orders table
    await db.execute('''
      CREATE TABLE Orders (
        OrderID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER NOT NULL,
        OrderDate TEXT NOT NULL,
        TotalAmount REAL NOT NULL CHECK(TotalAmount >= 0),
        Status TEXT NOT NULL CHECK(Status IN ('Pending', 'Shipped', 'Delivered')),
        PaymentMethod TEXT NOT NULL,
        DiscountCode TEXT,
        DiscountAmount REAL DEFAULT 0,
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
      )
    ''');

    // Create OrderProducts table
    await db.execute('''
      CREATE TABLE OrderProducts (
        OrderID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity INTEGER NOT NULL CHECK(Quantity > 0),
        PriceAtTime REAL NOT NULL,
        PRIMARY KEY (OrderID, ProductID),
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
      )
    ''');

    // Create Carts table
    await db.execute('''
      CREATE TABLE Carts (
        CartID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER NOT NULL UNIQUE,
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
      )
    ''');

    // Create CartProducts table
    await db.execute('''
      CREATE TABLE CartProducts (
        CartID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity INTEGER NOT NULL CHECK(Quantity > 0),
        PRIMARY KEY (CartID, ProductID),
        FOREIGN KEY (CartID) REFERENCES Carts(CartID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
      )
    ''');

    // Create Suppliers table
    await db.execute('''
      CREATE TABLE Suppliers (
        SupplierID INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT NOT NULL,
        ContactNumber TEXT,
        Address TEXT
      )
    ''');

    // Create Discounts table
    await db.execute('''
      CREATE TABLE Discounts (
        DiscountID INTEGER PRIMARY KEY AUTOINCREMENT,
        Code TEXT UNIQUE NOT NULL,
        Percentage REAL NOT NULL CHECK(Percentage > 0 AND Percentage <= 100),
        ExpirationDate TEXT NOT NULL,
        ProductID INTEGER,
        Category TEXT,
        MinOrderAmount REAL,
        MaxUses INTEGER,
        UsesCount INTEGER DEFAULT 0,
        IsActive INTEGER DEFAULT 1,
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
      )
    ''');

    // Create Reviews table
    await db.execute('''
      CREATE TABLE Reviews (
        ReviewID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        ReviewDate TEXT NOT NULL,
        Rating INTEGER NOT NULL CHECK(Rating >= 1 AND Rating <= 5),
        Comment TEXT,
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
      )
    ''');

    // Create ShippingFees table
    await db.execute('''
      CREATE TABLE ShippingFees (
        Country TEXT NOT NULL,
        City TEXT NOT NULL,
        ShippingFee REAL NOT NULL CHECK(ShippingFee >= 0),
        PRIMARY KEY (Country, City)
      )
    ''');

    // Create TaxRates table
    await db.execute('''
      CREATE TABLE TaxRates (
        Country TEXT NOT NULL,
        City TEXT NOT NULL,
        Tax REAL NOT NULL CHECK(Tax >= 0),
        PRIMARY KEY (Country, City)
      )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Insert sample users
    await db.insert('Users', {
      'FirstName': 'Admin',
      'MiddleName': '',
      'LastName': 'User',
      'Password': 'admin123',
      'Email': 'admin@example.com',
      'Gender': 'Male',
      'DateOfBirth': '1990-01-01',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Admin',
      'PhoneNumber': '+1234567890',
    });

    await db.insert('Users', {
      'FirstName': 'John',
      'MiddleName': 'William',
      'LastName': 'Doe',
      'Password': 'password123',
      'Email': 'john@example.com',
      'Gender': 'Male',
      'DateOfBirth': '1995-05-15',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Customer',
      'PhoneNumber': '+1987654321',
    });

    await db.insert('Users', {
      'FirstName': 'Jane',
      'MiddleName': 'Elizabeth',
      'LastName': 'Smith',
      'Password': 'password123',
      'Email': 'jane@example.com',
      'Gender': 'Female',
      'DateOfBirth': '1992-08-20',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Customer',
      'PhoneNumber': '+1654321890',
    });

    await db.insert('Users', {
      'FirstName': 'Mike',
      'MiddleName': '',
      'LastName': 'Johnson',
      'Password': 'password123',
      'Email': 'mike@example.com',
      'Gender': 'Male',
      'DateOfBirth': '1988-11-30',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Customer',
      'PhoneNumber': '+1543219876',
    });

    await db.insert('Users', {
      'FirstName': 'Sarah',
      'MiddleName': 'Elizabeth',
      'LastName': 'Wilson',
      'Password': 'password123',
      'Email': 'sarah@example.com',
      'Gender': 'Female',
      'DateOfBirth': '1993-04-12',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Customer',
      'PhoneNumber': '+1432198765',
    });

    // Insert sample addresses
    await db.insert('Addresses', {
      'UserID': 2,
      'AddressType': 'Home',
      'Country': 'USA',
      'City': 'New York',
      'Province': 'NY',
      'District': 'Manhattan',
      'Street': '123 Main Street',
      'BuildingNumber': '45',
      'ApartmentNumber': '3B',
      'PostalCode': '10001',
      'IsDefault': 1,
    });

    await db.insert('Addresses', {
      'UserID': 3,
      'AddressType': 'Home',
      'Country': 'USA',
      'City': 'Los Angeles',
      'Province': 'CA',
      'District': 'Downtown',
      'Street': '456 Oak Avenue',
      'BuildingNumber': '12',
      'ApartmentNumber': '7A',
      'PostalCode': '90012',
      'IsDefault': 1,
    });

    // Insert sample suppliers
    await db.insert('Suppliers', {
      'Name': 'Tech Supplies Inc.',
      'ContactNumber': '+1234567890',
      'Address': '123 Tech Street, Silicon Valley',
    });

    await db.insert('Suppliers', {
      'Name': 'Fashion World Ltd.',
      'ContactNumber': '+0987654321',
      'Address': '456 Fashion Avenue, New York',
    });

    await db.insert('Suppliers', {
      'Name': 'Home Essentials Co.',
      'ContactNumber': '+1122334455',
      'Address': '789 Home Lane, Chicago',
    });

    // Insert sample products
    await db.insert('Products', {
      'Name': 'Smartphone X',
      'Description': 'Latest smartphone with amazing features',
      'Price': 999.99,
      'Amount': 50,
      'Category': 'Electronics',
      'Size': '6.1 inches',
      'Color': 'Black',
      'SupplierID': 1,
    });

    await db.insert('Products', {
      'Name': 'Laptop Pro',
      'Description': 'High-performance laptop for professionals',
      'Price': 1499.99,
      'Amount': 30,
      'Category': 'Electronics',
      'Size': '15.6 inches',
      'Color': 'Silver',
      'SupplierID': 1,
    });

    await db.insert('Products', {
      'Name': 'Designer Dress',
      'Description': 'Elegant evening dress',
      'Price': 299.99,
      'Amount': 20,
      'Category': 'Fashion',
      'Size': 'M',
      'Color': 'Red',
      'SupplierID': 2,
    });

    await db.insert('Products', {
      'Name': 'Coffee Maker',
      'Description': 'Automatic coffee maker with timer',
      'Price': 89.99,
      'Amount': 40,
      'Category': 'Home',
      'Size': 'Standard',
      'Color': 'Black',
      'SupplierID': 3,
    });

    await db.insert('Products', {
      'Name': 'Wireless Headphones',
      'Description': 'Noise-cancelling wireless headphones',
      'Price': 199.99,
      'Amount': 25,
      'Category': 'Electronics',
      'Size': 'One Size',
      'Color': 'White',
      'SupplierID': 1,
    });

    await db.insert('Products', {
      'Name': 'Running Shoes',
      'Description': 'Lightweight running shoes',
      'Price': 129.99,
      'Amount': 35,
      'Category': 'Sports',
      'Size': '10',
      'Color': 'Blue',
      'SupplierID': 2,
    });

    await db.insert('Products', {
      'Name': 'Smart Watch',
      'Description': 'Fitness tracker with heart rate monitor',
      'Price': 249.99,
      'Amount': 15,
      'Category': 'Electronics',
      'Size': 'One Size',
      'Color': 'Black',
      'SupplierID': 1,
    });

    await db.insert('Products', {
      'Name': 'Winter Jacket',
      'Description': 'Warm winter jacket with hood',
      'Price': 199.99,
      'Amount': 20,
      'Category': 'Fashion',
      'Size': 'L',
      'Color': 'Navy',
      'SupplierID': 2,
    });

    await db.insert('Products', {
      'Name': 'Air Fryer',
      'Description': 'Digital air fryer with multiple cooking functions',
      'Price': 129.99,
      'Amount': 30,
      'Category': 'Home',
      'Size': 'Standard',
      'Color': 'Silver',
      'SupplierID': 3,
    });

    // Insert sample orders
    final order1 = await db.insert('Orders', {
      'UserID': 2,
      'OrderDate': DateTime.now().toIso8601String(),
      'TotalAmount': 0.0,
      'Status': 'Pending',
      'PaymentMethod': 'Credit Card',
    });

    // Get product price for order1
    final product1 = await db.query(
      'Products',
      where: 'ProductID = ?',
      whereArgs: [1],
    );
    final product3 = await db.query(
      'Products',
      where: 'ProductID = ?',
      whereArgs: [3],
    );

    await db.insert('OrderProducts', {
      'OrderID': order1,
      'ProductID': 1,
      'Quantity': 1,
      'PriceAtTime': product1.first['Price'] as double,
    });

    await db.insert('OrderProducts', {
      'OrderID': order1,
      'ProductID': 3,
      'Quantity': 2,
      'PriceAtTime': product3.first['Price'] as double,
    });

    final order2 = await db.insert('Orders', {
      'UserID': 3,
      'OrderDate': DateTime.now().toIso8601String(),
      'TotalAmount': 0.0,
      'Status': 'Shipped',
      'PaymentMethod': 'PayPal',
    });

    // Get product price for order2
    final product2 = await db.query(
      'Products',
      where: 'ProductID = ?',
      whereArgs: [2],
    );
    final product5 = await db.query(
      'Products',
      where: 'ProductID = ?',
      whereArgs: [5],
    );

    await db.insert('OrderProducts', {
      'OrderID': order2,
      'ProductID': 2,
      'Quantity': 1,
      'PriceAtTime': product2.first['Price'] as double,
    });

    await db.insert('OrderProducts', {
      'OrderID': order2,
      'ProductID': 5,
      'Quantity': 1,
      'PriceAtTime': product5.first['Price'] as double,
    });

    // Insert sample reviews
    await db.insert('Reviews', {
      'UserID': 2,
      'ProductID': 1,
      'ReviewDate': DateTime.now().toIso8601String(),
      'Rating': 5,
      'Comment': 'Amazing phone! The camera quality is outstanding.',
    });

    await db.insert('Reviews', {
      'UserID': 3,
      'ProductID': 1,
      'ReviewDate': DateTime.now().toIso8601String(),
      'Rating': 4,
      'Comment': 'Great phone but a bit expensive.',
    });

    await db.insert('Reviews', {
      'UserID': 2,
      'ProductID': 2,
      'ReviewDate': DateTime.now().toIso8601String(),
      'Rating': 5,
      'Comment': 'Perfect for my work needs.',
    });

    // Insert sample discounts
    await db.insert('Discounts', {
      'Code': 'WELCOME10',
      'Percentage': 10.0,
      'ExpirationDate':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'ProductID': 1,
      'Category': null,
      'MinOrderAmount': 50.0,
      'MaxUses': 100,
      'UsesCount': 0,
      'IsActive': 1,
    });

    await db.insert('Discounts', {
      'Code': 'ELECTRONICS15',
      'Percentage': 15.0,
      'ExpirationDate':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'ProductID': null,
      'Category': 'Electronics',
      'MinOrderAmount': 100.0,
      'MaxUses': 50,
      'UsesCount': 0,
      'IsActive': 1,
    });

    // Insert sample shipping fees
    await db.insert('ShippingFees', {
      'Country': 'USA',
      'City': 'New York',
      'ShippingFee': 10.00,
    });

    await db.insert('ShippingFees', {
      'Country': 'USA',
      'City': 'Los Angeles',
      'ShippingFee': 12.00,
    });

    // Insert sample tax rates
    await db.insert('TaxRates', {
      'Country': 'USA',
      'City': 'New York',
      'Tax': 8.875,
    });

    await db.insert('TaxRates', {
      'Country': 'USA',
      'City': 'Los Angeles',
      'Tax': 9.5,
    });
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    Database db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String where,
    List<dynamic> whereArgs,
  ) async {
    Database db = await database;
    return await db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    Database db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<double> calculateOrderTotal(
    int orderId,
    String country,
    String city,
  ) async {
    Database db = await database;

    // Get base total from OrderProducts
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(op.Quantity * p.Price), 0) as subtotal
      FROM OrderProducts op
      JOIN Products p ON op.ProductID = p.ProductID
      WHERE op.OrderID = ?
    ''',
      [orderId],
    );

    double subtotal = result.first['subtotal'] as double;

    // Get tax rate
    final taxResult = await db.query(
      'TaxRates',
      where: 'Country = ? AND City = ?',
      whereArgs: [country, city],
    );
    double taxRate =
        taxResult.isNotEmpty ? taxResult.first['Tax'] as double : 0.0;

    // Get shipping fee
    final shippingResult = await db.query(
      'ShippingFees',
      where: 'Country = ? AND City = ?',
      whereArgs: [country, city],
    );
    double shippingFee =
        shippingResult.isNotEmpty
            ? shippingResult.first['ShippingFee'] as double
            : 0.0;

    // Calculate total with tax and shipping
    double taxAmount = subtotal * (taxRate / 100);
    return subtotal + taxAmount + shippingFee;
  }

  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    Database db = await database;
    return await db.rawQuery(
      '''
      SELECT r.*, u.Name as UserName
      FROM Reviews r
      JOIN Users u ON r.UserID = u.UserID
      WHERE r.ProductID = ?
      ORDER BY r.ReviewDate DESC
    ''',
      [productId],
    );
  }

  Future<double?> getProductDiscount(int productId, String category) async {
    Database db = await database;

    // Check for product-specific discount
    final productDiscount = await db.query(
      'Discounts',
      where: 'ProductID = ? AND ExpiryDate > date("now")',
      whereArgs: [productId],
    );

    if (productDiscount.isNotEmpty) {
      return productDiscount.first['Percentage'] as double;
    }

    // Check for category discount
    final categoryDiscount = await db.query(
      'Discounts',
      where: 'Category = ? AND ExpiryDate > date("now")',
      whereArgs: [category],
    );

    if (categoryDiscount.isNotEmpty) {
      return categoryDiscount.first['Percentage'] as double;
    }

    return null;
  }

  Future<void> updateOrderTotal(
    int orderId,
    String country,
    String city,
  ) async {
    double total = await calculateOrderTotal(orderId, country, city);
    await update('Orders', {'TotalAmount': total}, 'OrderID = ?', [orderId]);
  }

  Future<List<Discount>> getDiscounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Discounts');
    return List.generate(maps.length, (i) => Discount.fromMap(maps[i]));
  }

  Future<Discount?> getDiscountByCode(String code) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Discounts',
      where: 'Code = ? AND IsActive = 1',
      whereArgs: [code],
    );
    if (maps.isEmpty) return null;
    return Discount.fromMap(maps.first);
  }

  Future<int> insertDiscount(Discount discount) async {
    final db = await database;
    return await db.insert('Discounts', discount.toMap());
  }

  Future<int> updateDiscount(Discount discount) async {
    final db = await database;
    return await db.update(
      'Discounts',
      discount.toMap(),
      where: 'DiscountID = ?',
      whereArgs: [discount.id],
    );
  }

  Future<int> deleteDiscount(int id) async {
    final db = await database;
    return await db.delete(
      'Discounts',
      where: 'DiscountID = ?',
      whereArgs: [id],
    );
  }

  Future<bool> validateDiscount(
    String code,
    int? productId,
    String? category,
    double orderAmount,
  ) async {
    final discount = await getDiscountByCode(code);
    if (discount == null) return false;

    // Check expiration
    if (discount.expirationDate.isBefore(DateTime.now())) return false;

    // Check if max uses reached
    if (discount.maxUses != null && discount.usesCount >= discount.maxUses!)
      return false;

    // Check product or category restrictions
    if (discount.productId != null && discount.productId != productId)
      return false;
    if (discount.category != null && discount.category != category)
      return false;

    // Check minimum order amount
    if (discount.minOrderAmount != null &&
        orderAmount < discount.minOrderAmount!)
      return false;

    return true;
  }

  Future<void> incrementDiscountUses(String code) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE Discounts 
      SET UsesCount = UsesCount + 1 
      WHERE Code = ?
    ''',
      [code],
    );
  }

  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final cart = await query('Carts', where: 'UserID = ?', whereArgs: [userId]);
    if (cart.isEmpty) {
      return [];
    }
    final cartId = cart.first['CartID'];
    final cartProducts = await query(
      'CartProducts',
      where: 'CartID = ?',
      whereArgs: [cartId],
    );
    final products = await query('Products');
    return cartProducts.map((cp) {
      final product = products.firstWhere(
        (p) => p['ProductID'] == cp['ProductID'],
      );
      return {
        'ProductID': cp['ProductID'],
        'Quantity': cp['Quantity'],
        'Price': product['Price'] as double,
        'Name': product['Name'],
        'ImageURL': product['ImageURL'] ?? '',
      };
    }).toList();
  }

  Future<void> updateCartItemQuantity(
    int userId,
    int productId,
    int quantity,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get user's cart
      var cart = await txn.query(
        'Carts',
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      if (cart.isNotEmpty) {
        int cartId = cart.first['CartID'] as int;
        if (quantity > 0) {
          // Update quantity
          await txn.update(
            'CartProducts',
            {'Quantity': quantity},
            where: 'CartID = ? AND ProductID = ?',
            whereArgs: [cartId, productId],
          );
        } else {
          // Remove item if quantity is 0
          await txn.delete(
            'CartProducts',
            where: 'CartID = ? AND ProductID = ?',
            whereArgs: [cartId, productId],
          );
        }
      }
    });
  }

  Future<void> removeFromCart(int userId, int productId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get user's cart
      var cart = await txn.query(
        'Carts',
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      if (cart.isNotEmpty) {
        int cartId = cart.first['CartID'] as int;
        await txn.delete(
          'CartProducts',
          where: 'CartID = ? AND ProductID = ?',
          whereArgs: [cartId, productId],
        );
      }
    });
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get user's cart
      var cart = await txn.query(
        'Carts',
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      if (cart.isNotEmpty) {
        int cartId = cart.first['CartID'] as int;
        // Delete all cart products
        await txn.delete(
          'CartProducts',
          where: 'CartID = ?',
          whereArgs: [cartId],
        );
      }
    });
  }

  Future<Map<String, dynamic>?> getUserCart(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Carts',
      where: 'UserID = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> addToCart(int userId, int productId, int quantity) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get or create user's cart
      var cart = await txn.query(
        'Carts',
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      int cartId;
      if (cart.isEmpty) {
        cartId = await txn.insert('Carts', {'UserID': userId});
      } else {
        cartId = cart.first['CartID'] as int;
      }

      // Check if product already exists in cart
      var existingItem = await txn.query(
        'CartProducts',
        where: 'CartID = ? AND ProductID = ?',
        whereArgs: [cartId, productId],
      );

      if (existingItem.isNotEmpty) {
        // Update quantity if product exists
        int currentQuantity = existingItem.first['Quantity'] as int;
        await txn.update(
          'CartProducts',
          {'Quantity': currentQuantity + quantity},
          where: 'CartID = ? AND ProductID = ?',
          whereArgs: [cartId, productId],
        );
      } else {
        // Add new product to cart
        await txn.insert('CartProducts', {
          'CartID': cartId,
          'ProductID': productId,
          'Quantity': quantity,
        });
      }
    });
  }

  Future<int> insertOrder(
    int userId,
    double totalAmount,
    String? discountCode,
    double discountAmount,
  ) async {
    final db = await database;
    final order = {
      'UserID': userId,
      'OrderDate': DateTime.now().toIso8601String(),
      'TotalAmount': totalAmount,
      'Status': 'Pending',
      'PaymentMethod': 'Credit Card', // Default payment method
      'DiscountCode': discountCode,
      'DiscountAmount': discountAmount,
    };
    return await db.insert('Orders', order);
  }

  Future<void> insertOrderProduct(
    int orderId,
    int productId,
    int quantity,
    double priceAtTime,
  ) async {
    final db = await database;
    await db.insert('OrderProducts', {
      'OrderID': orderId,
      'ProductID': productId,
      'Quantity': quantity,
      'PriceAtTime': priceAtTime,
    });
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;

    // Start a transaction to ensure all operations succeed or fail together
    await db.transaction((txn) async {
      // First, get the user's cart ID
      final cart = await txn.query(
        'Carts',
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      if (cart.isNotEmpty) {
        final cartId = cart.first['CartID'];
        // Delete cart products
        await txn.delete(
          'CartProducts',
          where: 'CartID = ?',
          whereArgs: [cartId],
        );
        // Delete the cart
        await txn.delete('Carts', where: 'CartID = ?', whereArgs: [cartId]);
      }

      // Get all orders for the user
      final orders = await txn.query(
        'Orders',
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      // Delete order products for each order
      for (final order in orders) {
        await txn.delete(
          'OrderProducts',
          where: 'OrderID = ?',
          whereArgs: [order['OrderID']],
        );
      }

      // Delete the orders
      await txn.delete('Orders', where: 'UserID = ?', whereArgs: [userId]);

      // Delete user addresses
      await txn.delete('Addresses', where: 'UserID = ?', whereArgs: [userId]);

      // Delete user reviews
      await txn.delete('Reviews', where: 'UserID = ?', whereArgs: [userId]);

      // Finally, delete the user
      await txn.delete('Users', where: 'UserID = ?', whereArgs: [userId]);
    });
  }

  // Address Management Methods
  Future<List<Map<String, dynamic>>> getUserAddresses(int userId) async {
    final db = await database;
    return await db.query(
      'Addresses',
      where: 'UserID = ?',
      whereArgs: [userId],
    );
  }

  Future<int> insertAddress(Map<String, dynamic> address) async {
    final db = await database;
    return await db.insert('Addresses', address);
  }

  Future<void> updateAddress(Map<String, dynamic> address) async {
    final db = await database;
    await db.update(
      'Addresses',
      address,
      where: 'AddressID = ?',
      whereArgs: [address['AddressID']],
    );
  }

  Future<void> deleteAddress(int addressId) async {
    final db = await database;
    await db.delete(
      'Addresses',
      where: 'AddressID = ?',
      whereArgs: [addressId],
    );
  }

  Future<void> setDefaultAddress(int userId, int addressId) async {
    final db = await database;
    await db.transaction((txn) async {
      // First, set all addresses of the user to non-default
      await txn.update(
        'Addresses',
        {'IsDefault': 0},
        where: 'UserID = ?',
        whereArgs: [userId],
      );

      // Then, set the specified address as default
      await txn.update(
        'Addresses',
        {'IsDefault': 1},
        where: 'AddressID = ? AND UserID = ?',
        whereArgs: [addressId, userId],
      );
    });
  }

  Future<Map<String, dynamic>?> getDefaultAddress(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Addresses',
      where: 'UserID = ? AND IsDefault = 1',
      whereArgs: [userId],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }
}
