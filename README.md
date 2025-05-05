# E-Commerce App with Flutter and SQFlite

This is a Flutter application that serves as a front-end for an e-commerce database system. The app uses SQFlite for local database storage and provides a user interface for managing users, products, orders, and shopping carts.

## Features

- User Management (Add, Edit, Delete, View)
- Product Management (Add, Edit, Delete, View)
- Order Management (Add, Edit, Delete, View)
- Shopping Cart Functionality
- SQLite Database Integration
- Material Design UI

## Prerequisites

- Flutter SDK (version 3.7.2 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- macOS (for running on desktop) or Chrome (for web)

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd ecommerce_app_with_flutter_and_sqflite
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   - For macOS desktop:
     ```bash
     flutter run -d macos
     ```
   - For web:
     ```bash
     flutter run -d chrome
     ```

## Project Structure

```
lib/
├── main.dart               # Entry point
├── models/                # Entity classes
│   ├── user.dart
│   ├── product.dart
│   ├── order.dart
│   └── cart.dart
├── screens/               # UI screens
│   ├── home_screen.dart
│   ├── user_list_screen.dart
│   ├── user_form_screen.dart
│   ├── product_list_screen.dart
│   ├── product_form_screen.dart
│   ├── order_list_screen.dart
│   ├── order_form_screen.dart
│   └── cart_screen.dart
└── services/              # Database operations
    └── database_helper.dart
```

## Database Schema

The app uses the following database tables:
- Users
- Products
- Orders
- OrderProducts
- Carts
- CartProducts
- Addresses
- Suppliers
- Discounts
- Reviews
- ShippingFees
- TaxRates

## Screenshots and Documentation:
