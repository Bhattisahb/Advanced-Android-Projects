/// App-wide constants for the POS application
/// Includes database names, low stock thresholds, and UI constants

class AppConstants {
  // Database
  static const String DATABASE_NAME = 'pos_app.db';
  static const int DATABASE_VERSION = 5;

  // Inventory
  static const int LOW_STOCK_THRESHOLD = 5;

  // Validation
  static const int MIN_PASSWORD_LENGTH = 6;
  static const int MIN_SKU_LENGTH = 1;
  static const int MIN_PRODUCT_NAME_LENGTH = 1;

  // UI
  static const double DEFAULT_PADDING = 16.0;
  static const double DEFAULT_BORDER_RADIUS = 8.0;

  // Routes
  static const String ROUTE_LOGIN = '/login';
  static const String ROUTE_SIGNUP = '/signup';
  static const String ROUTE_HOME = '/home';
  static const String ROUTE_PRODUCTS = '/products';
  static const String ROUTE_PRODUCT_FORM = '/products/form';
  static const String ROUTE_INVENTORY = '/inventory';
  static const String ROUTE_POS = '/pos';
  static const String ROUTE_CUSTOMERS = '/customers';
  static const String ROUTE_REPORTS = '/reports';
  static const String ROUTE_TRANSACTIONS = '/transactions';
  static const String ROUTE_BACKUP = '/backup';

  // Messages
  static const String ERROR_INVALID_EMAIL = 'Please enter a valid email';
  static const String ERROR_WEAK_PASSWORD = 'Password must be at least 6 characters';
  static const String ERROR_PASSWORDS_DONT_MATCH = 'Passwords do not match';
  static const String ERROR_INVALID_PRODUCT_NAME = 'Product name is required';
  static const String ERROR_INVALID_SKU = 'SKU is required';
  static const String ERROR_INVALID_PRICE = 'Price must be greater than 0';
  static const String ERROR_INVALID_COST = 'Cost must be greater than or equal to 0';

  // Success Messages
  static const String SUCCESS_PRODUCT_ADDED = 'Product added successfully';
  static const String SUCCESS_PRODUCT_UPDATED = 'Product updated successfully';
  static const String SUCCESS_PRODUCT_DELETED = 'Product deleted successfully';
  static const String SUCCESS_STOCK_UPDATED = 'Stock updated successfully';
}
