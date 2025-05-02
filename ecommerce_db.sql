-- Create database tables
CREATE TABLE Users (
    User_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    Password TEXT NOT NULL,
    Email TEXT UNIQUE NOT NULL,
    Gender TEXT,
    DateOfBirth TEXT,
    DateJoined TEXT NOT NULL,
    UserType TEXT NOT NULL CHECK(UserType IN ('Customer', 'Admin'))
);

CREATE TABLE Addresses (
    AddressID INTEGER PRIMARY KEY AUTOINCREMENT,
    User_ID INTEGER NOT NULL,
    Country TEXT NOT NULL,
    City TEXT NOT NULL,
    Province TEXT,
    Street TEXT NOT NULL,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE
);

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
);

CREATE TABLE Orders (
    OrderID INTEGER PRIMARY KEY AUTOINCREMENT,
    User_ID INTEGER NOT NULL,
    Date TEXT NOT NULL,
    GrandTotal REAL NOT NULL CHECK(GrandTotal >= 0),
    Status TEXT NOT NULL CHECK(Status IN ('Pending', 'Shipped', 'Delivered')),
    PaymentMethod TEXT NOT NULL,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID)
);

CREATE TABLE OrderProducts (
    OrderID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK(Quantity > 0),
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Carts (
    CartID INTEGER PRIMARY KEY AUTOINCREMENT,
    User_ID INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID)
);

CREATE TABLE CartProducts (
    CartID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK(Quantity > 0),
    PRIMARY KEY (CartID, ProductID),
    FOREIGN KEY (CartID) REFERENCES Carts(CartID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Suppliers (
    SupplierID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    ContactNumber TEXT,
    Address TEXT
);

CREATE TABLE Discounts (
    Discount_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Percentage REAL NOT NULL CHECK(Percentage > 0 AND Percentage <= 100),
    ExpiryDate TEXT NOT NULL,
    ProductID INTEGER,
    Category TEXT,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Reviews (
    Review_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    User_ID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    ReviewDate TEXT NOT NULL,
    Rating INTEGER NOT NULL CHECK(Rating >= 1 AND Rating <= 5),
    Comment TEXT,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE ShippingFees (
    Country TEXT NOT NULL,
    City TEXT NOT NULL,
    ShippingFee REAL NOT NULL CHECK(ShippingFee >= 0),
    PRIMARY KEY (Country, City)
);

CREATE TABLE TaxRates (
    Country TEXT NOT NULL,
    City TEXT NOT NULL,
    Tax REAL NOT NULL CHECK(Tax >= 0),
    PRIMARY KEY (Country, City)
);

-- Create stored procedure for calculating order total
CREATE TRIGGER calculate_order_total
AFTER INSERT ON OrderProducts
BEGIN
    UPDATE Orders
    SET GrandTotal = (
        SELECT COALESCE(SUM(op.Quantity * p.Price), 0)
        FROM OrderProducts op
        JOIN Products p ON op.ProductID = p.ProductID
        WHERE op.OrderID = NEW.OrderID
    )
    WHERE OrderID = NEW.OrderID;
END;

-- Insert sample data
INSERT INTO Users (Name, Password, Email, Gender, DateOfBirth, DateJoined, UserType)
VALUES
    ('Admin User', 'admin123', 'admin@example.com', 'Male', '1990-01-01', datetime('now'), 'Admin'),
    ('John Doe', 'password123', 'john@example.com', 'Male', '1995-05-15', datetime('now'), 'Customer'),
    ('Jane Smith', 'password123', 'jane@example.com', 'Female', '1992-08-20', datetime('now'), 'Customer');

INSERT INTO Suppliers (Name, ContactNumber, Address)
VALUES
    ('Tech Supplies Inc.', '+1234567890', '123 Tech Street, Silicon Valley'),
    ('Fashion World Ltd.', '+0987654321', '456 Fashion Avenue, New York'),
    ('Home Essentials Co.', '+1122334455', '789 Home Lane, Chicago');

INSERT INTO Products (Name, Description, Price, Amount, Category, Size, Color, SupplierID)
VALUES
    ('Smartphone X', 'Latest smartphone with amazing features', 999.99, 50, 'Electronics', '6.1 inches', 'Black', 1),
    ('Laptop Pro', 'High-performance laptop for professionals', 1499.99, 30, 'Electronics', '15.6 inches', 'Silver', 1),
    ('Designer Dress', 'Elegant evening dress', 299.99, 20, 'Fashion', 'M', 'Red', 2),
    ('Coffee Maker', 'Automatic coffee maker with timer', 89.99, 40, 'Home', 'Standard', 'Black', 3),
    ('Wireless Headphones', 'Noise-cancelling wireless headphones', 199.99, 25, 'Electronics', 'One Size', 'White', 1),
    ('Running Shoes', 'Lightweight running shoes', 129.99, 35, 'Sports', '10', 'Blue', 2);

INSERT INTO Reviews (User_ID, ProductID, ReviewDate, Rating, Comment)
VALUES
    (2, 1, datetime('now'), 5, 'Amazing phone! The camera quality is outstanding.'),
    (3, 1, datetime('now'), 4, 'Great phone but a bit expensive.'),
    (2, 2, datetime('now'), 5, 'Perfect for my work needs.'),
    (3, 3, datetime('now'), 5, 'Beautiful dress, fits perfectly.'),
    (2, 4, datetime('now'), 4, 'Makes great coffee, easy to use.'),
    (3, 5, datetime('now'), 5, 'Best headphones I''ve ever owned.'),
    (2, 6, datetime('now'), 4, 'Comfortable and lightweight.');

INSERT INTO Discounts (Percentage, ExpiryDate, ProductID, Category)
VALUES
    (10.0, '2024-12-31', 1, NULL),
    (15.0, '2024-12-31', NULL, 'Electronics'),
    (20.0, '2024-12-31', 3, NULL),
    (25.0, '2024-12-31', NULL, 'Fashion');

INSERT INTO ShippingFees (Country, City, ShippingFee)
VALUES
    ('USA', 'New York', 10.00),
    ('USA', 'Los Angeles', 12.00),
    ('USA', 'Chicago', 8.00),
    ('Canada', 'Toronto', 15.00),
    ('Canada', 'Vancouver', 18.00);

INSERT INTO TaxRates (Country, City, Tax)
VALUES
    ('USA', 'New York', 8.875),
    ('USA', 'Los Angeles', 9.5),
    ('USA', 'Chicago', 10.25),
    ('Canada', 'Toronto', 13.0),
    ('Canada', 'Vancouver', 12.0); 