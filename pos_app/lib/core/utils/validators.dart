/// Input validators for authentication and form inputs
/// Ensures data integrity before storage

class Validators {
  /// Validates email format using regex
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates product name (non-empty)
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }
    if (value.length < 2) {
      return 'Product name must be at least 2 characters';
    }
    return null;
  }

  /// Validates SKU (non-empty)
  static String? validateSKU(String? value) {
    if (value == null || value.isEmpty) {
      return 'SKU is required';
    }
    return null;
  }

  /// Validates price (numeric and positive)
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Please enter a valid price greater than 0';
    }
    return null;
  }

  /// Validates cost (numeric and non-negative)
  static String? validateCost(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cost is required';
    }
    final cost = double.tryParse(value);
    if (cost == null || cost < 0) {
      return 'Please enter a valid cost';
    }
    return null;
  }

  /// Validates quantity (positive integer)
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    final qty = int.tryParse(value);
    if (qty == null || qty < 0) {
      return 'Please enter a valid quantity';
    }
    return null;
  }
}
