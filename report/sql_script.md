# SQL Script

## Table Creation
```sql
-- Users Table
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
);

-- Addresses Table
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
);

-- Products Table
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
    ImageURL TEXT,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- Orders Table
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
);

-- OrderProducts Table
CREATE TABLE OrderProducts (
    OrderID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK(Quantity > 0),
    PriceAtTime REAL NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Carts Table
CREATE TABLE Carts (
    CartID INTEGER PRIMARY KEY AUTOINCREMENT,
    UserID INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- CartProducts Table
CREATE TABLE CartProducts (
    CartID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK(Quantity > 0),
    PRIMARY KEY (CartID, ProductID),
    FOREIGN KEY (CartID) REFERENCES Carts(CartID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Suppliers Table
CREATE TABLE Suppliers (
    SupplierID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    ContactNumber TEXT,
    Address TEXT
);

-- Discounts Table
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
);

-- Reviews Table
CREATE TABLE Reviews (
    ReviewID INTEGER PRIMARY KEY AUTOINCREMENT,
    UserID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    ReviewDate TEXT NOT NULL,
    Rating INTEGER NOT NULL CHECK(Rating >= 1 AND Rating <= 5),
    Comment TEXT,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- ShippingFees Table
CREATE TABLE ShippingFees (
    Country TEXT NOT NULL,
    City TEXT NOT NULL,
    ShippingFee REAL NOT NULL CHECK(ShippingFee >= 0),
    PRIMARY KEY (Country, City)
);

-- TaxRates Table
CREATE TABLE TaxRates (
    Country TEXT NOT NULL,
    City TEXT NOT NULL,
    Tax REAL NOT NULL CHECK(Tax >= 0),
    PRIMARY KEY (Country, City)
);
```

## Sample Data Insertion
```sql
-- Sample Users
INSERT INTO Users (FirstName, MiddleName, LastName, Password, Email, Gender, DateOfBirth, DateJoined, UserType, PhoneNumber)
VALUES 
('Admin', '', 'User', 'admin123', 'admin@example.com', 'Male', '1990-01-01', CURRENT_TIMESTAMP, 'Admin', '+1234567890'),
('John', 'William', 'Doe', 'password123', 'john@example.com', 'Male', '1995-05-15', CURRENT_TIMESTAMP, 'Customer', '+1987654321'),
('Jane', 'Elizabeth', 'Smith', 'password123', 'jane@example.com', 'Female', '1992-08-20', CURRENT_TIMESTAMP, 'Customer', '+1654321890');

-- Sample Addresses
INSERT INTO Addresses (UserID, AddressType, Country, City, Province, District, Street, BuildingNumber, ApartmentNumber, PostalCode, IsDefault)
VALUES 
(2, 'Home', 'USA', 'New York', 'NY', 'Manhattan', '123 Main Street', '45', '3B', '10001', 1),
(3, 'Home', 'USA', 'Los Angeles', 'CA', 'Downtown', '456 Oak Avenue', '12', '7A', '90012', 1);

-- Sample Products
INSERT INTO Products (Name, Description, Price, Amount, Category, Size, Color, SupplierID, ImageURL)
VALUES 
('Smartphone X', 'Latest smartphone with amazing features', 999.99, 50, 'Electronics', '6.1 inches', 'Black', 1, 'smartphone_x.jpg'),
('Laptop Pro', 'High-performance laptop for professionals', 1499.99, 30, 'Electronics', '15.6 inches', 'Silver', 1, 'laptop_pro.jpg'),
('Designer Dress', 'Elegant evening dress', 299.99, 20, 'Fashion', 'M', 'Red', 2, 'designer_dress.jpg');

-- Sample Suppliers
INSERT INTO Suppliers (Name, ContactNumber, Address)
VALUES 
('Tech Supplies Inc.', '+1234567890', '123 Tech Street, Silicon Valley'),
('Fashion World Ltd.', '+0987654321', '456 Fashion Avenue, New York'),
('Home Essentials Co.', '+1122334455', '789 Home Lane, Chicago');

-- Sample Discounts
INSERT INTO Discounts (Code, Percentage, ExpirationDate, ProductID, Category, MinOrderAmount, MaxUses, UsesCount, IsActive)
VALUES 
('WELCOME10', 10.0, DATE('now', '+30 days'), 1, NULL, 50.0, 100, 0, 1),
('ELECTRONICS15', 15.0, DATE('now', '+30 days'), NULL, 'Electronics', 100.0, 50, 0, 1);

-- Sample Shipping Fees
INSERT INTO ShippingFees (Country, City, ShippingFee)
VALUES 
('USA', 'New York', 10.00),
('USA', 'Los Angeles', 12.00);

-- Sample Tax Rates
INSERT INTO TaxRates (Country, City, Tax)
VALUES 
('USA', 'New York', 8.875),
('USA', 'Los Angeles', 9.5);
```

## Example Queries
```sql
-- Get user's cart items with product details
SELECT p.Name, p.Price, cp.Quantity, (p.Price * cp.Quantity) as Total
FROM CartProducts cp
JOIN Products p ON cp.ProductID = p.ProductID
JOIN Carts c ON cp.CartID = c.CartID
WHERE c.UserID = 1;

-- Get order history with product details
SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.Status,
       p.Name, op.Quantity, op.PriceAtTime
FROM Orders o
JOIN OrderProducts op ON o.OrderID = op.OrderID
JOIN Products p ON op.ProductID = p.ProductID
WHERE o.UserID = 1
ORDER BY o.OrderDate DESC;

-- Get product reviews with user information
SELECT r.Rating, r.Comment, r.ReviewDate,
       u.FirstName, u.LastName
FROM Reviews r
JOIN Users u ON r.UserID = u.UserID
WHERE r.ProductID = 1
ORDER BY r.ReviewDate DESC;

-- Calculate order total with tax and shipping
SELECT 
    SUM(op.Quantity * op.PriceAtTime) as Subtotal,
    t.Tax as TaxRate,
    s.ShippingFee,
    (SUM(op.Quantity * op.PriceAtTime) * (1 + t.Tax/100) + s.ShippingFee) as Total
FROM OrderProducts op
JOIN Orders o ON op.OrderID = o.OrderID
JOIN TaxRates t ON o.Country = t.Country AND o.City = t.City
JOIN ShippingFees s ON o.Country = s.Country AND o.City = s.City
WHERE o.OrderID = 1;
```

## Stored Procedures
```sql
-- Calculate order total
CREATE PROCEDURE CalculateOrderTotal(IN orderId INT, IN country TEXT, IN city TEXT)
BEGIN
    DECLARE subtotal DECIMAL(10,2);
    DECLARE taxRate DECIMAL(5,2);
    DECLARE shippingFee DECIMAL(10,2);
    DECLARE total DECIMAL(10,2);
    
    -- Calculate subtotal
    SELECT SUM(op.Quantity * op.PriceAtTime) INTO subtotal
    FROM OrderProducts op
    WHERE op.OrderID = orderId;
    
    -- Get tax rate
    SELECT Tax INTO taxRate
    FROM TaxRates
    WHERE Country = country AND City = city;
    
    -- Get shipping fee
    SELECT ShippingFee INTO shippingFee
    FROM ShippingFees
    WHERE Country = country AND City = city;
    
    -- Calculate total
    SET total = subtotal * (1 + taxRate/100) + shippingFee;
    
    -- Update order total
    UPDATE Orders
    SET TotalAmount = total
    WHERE OrderID = orderId;
END;

-- Validate and apply discount
CREATE PROCEDURE ApplyDiscount(IN orderId INT, IN discountCode TEXT)
BEGIN
    DECLARE discountPercentage DECIMAL(5,2);
    DECLARE minOrderAmount DECIMAL(10,2);
    DECLARE orderTotal DECIMAL(10,2);
    DECLARE discountAmount DECIMAL(10,2);
    
    -- Get discount details
    SELECT Percentage, MinOrderAmount INTO discountPercentage, minOrderAmount
    FROM Discounts
    WHERE Code = discountCode AND IsActive = 1;
    
    -- Get order total
    SELECT TotalAmount INTO orderTotal
    FROM Orders
    WHERE OrderID = orderId;
    
    -- Validate and apply discount
    IF orderTotal >= minOrderAmount THEN
        SET discountAmount = orderTotal * (discountPercentage/100);
        UPDATE Orders
        SET DiscountCode = discountCode,
            DiscountAmount = discountAmount,
            TotalAmount = TotalAmount - discountAmount
        WHERE OrderID = orderId;
    END IF;
END;
``` 