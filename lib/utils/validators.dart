class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Full name validation
  static String? fullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters long';
    }
    
    // Check if name contains at least one letter
    final nameRegex = RegExp(r'[a-zA-Z]');
    if (!nameRegex.hasMatch(value)) {
      return 'Please enter a valid name';
    }
    
    return null;
  }

  // Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Optional phone number validation
  static String? optionalPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    return phoneNumber(value);
  }

  // Bio validation
  static String? bio(String? value) {
    if (value != null && value.length > 500) {
      return 'Bio cannot exceed 500 characters';
    }
    
    return null;
  }

  // Required field validation
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // Minimum length validation
  static String? minLength(String? value, int minLength, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    return null;
  }

  // Maximum length validation
  static String? maxLength(String? value, int maxLength, {String fieldName = 'This field'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    return null;
  }

  // URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Strong password validation
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$&*~)';
    }
    
    return null;
  }
}

