import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
        User_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT NOT NULL,
        Password TEXT NOT NULL,
        Email TEXT UNIQUE NOT NULL,
        Gender TEXT,
        DateOfBirth TEXT,
        DateJoined TEXT NOT NULL,
        UserType TEXT NOT NULL CHECK(UserType IN ('Customer', 'Admin'))
      )
    ''');

    // Create Addresses table
    await db.execute('''
      CREATE TABLE Addresses (
        AddressID INTEGER PRIMARY KEY AUTOINCREMENT,
        User_ID INTEGER NOT NULL,
        Country TEXT NOT NULL,
        City TEXT NOT NULL,
        Province TEXT,
        Street TEXT NOT NULL,
        FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE
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
        User_ID INTEGER NOT NULL,
        Date TEXT NOT NULL,
        GrandTotal REAL NOT NULL CHECK(GrandTotal >= 0),
        Status TEXT NOT NULL CHECK(Status IN ('Pending', 'Shipped', 'Delivered')),
        PaymentMethod TEXT NOT NULL,
        FOREIGN KEY (User_ID) REFERENCES Users(User_ID)
      )
    ''');

    // Create OrderProducts table
    await db.execute('''
      CREATE TABLE OrderProducts (
        OrderID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity INTEGER NOT NULL CHECK(Quantity > 0),
        PRIMARY KEY (OrderID, ProductID),
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
      )
    ''');

    // Create Carts table
    await db.execute('''
      CREATE TABLE Carts (
        CartID INTEGER PRIMARY KEY AUTOINCREMENT,
        User_ID INTEGER NOT NULL UNIQUE,
        FOREIGN KEY (User_ID) REFERENCES Users(User_ID)
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
        Discount_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Percentage REAL NOT NULL CHECK(Percentage > 0 AND Percentage <= 100),
        ExpiryDate TEXT NOT NULL
      )
    ''');

    // Create Reviews table
    await db.execute('''
      CREATE TABLE Reviews (
        Review_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        User_ID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        ReviewDate TEXT NOT NULL,
        Rating INTEGER NOT NULL CHECK(Rating >= 1 AND Rating <= 5),
        Comment TEXT,
        FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
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
      'Name': 'Admin User',
      'Password': 'admin123',
      'Email': 'admin@example.com',
      'Gender': 'Male',
      'DateOfBirth': '1990-01-01',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Admin',
    });

    await db.insert('Users', {
      'Name': 'John Doe',
      'Password': 'password123',
      'Email': 'john@example.com',
      'Gender': 'Male',
      'DateOfBirth': '1995-05-15',
      'DateJoined': DateTime.now().toIso8601String(),
      'UserType': 'Customer',
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
    });

    await db.insert('Products', {
      'Name': 'Laptop Pro',
      'Description': 'High-performance laptop for professionals',
      'Price': 1499.99,
      'Amount': 30,
      'Category': 'Electronics',
      'Size': '15.6 inches',
      'Color': 'Silver',
    });

    // Insert sample supplier
    await db.insert('Suppliers', {
      'Name': 'Tech Supplies Inc.',
      'ContactNumber': '+1234567890',
      'Address': '123 Tech Street, Silicon Valley',
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
      JOIN Users u ON r.User_ID = u.User_ID
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
    await update('Orders', {'GrandTotal': total}, 'OrderID = ?', [orderId]);
  }
}
