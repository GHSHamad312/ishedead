class ErrorParser {
  static String parse(dynamic error) {
    String message = error.toString();

    // Check for Firebase Auth Errors (often contain [firebase_auth/code])
    if (message.contains('firebase_auth')) {
      if (message.contains('user-not-found')) {
        return "No user found with this email.";
      } else if (message.contains('wrong-password')) {
        return "Incorrect password. Please try again.";
      } else if (message.contains('email-already-in-use')) {
        return "This email is already registered.";
      } else if (message.contains('invalid-email')) {
        return "Please enter a valid email address.";
      } else if (message.contains('weak-password')) {
        return "Password is too weak. Try a stronger one.";
      } else if (message.contains('too-many-requests')) {
        return "Too many attempts. Please try again later.";
      } else if (message.contains('network-request-failed')) {
        return "Network error. Check your connection.";
      }
    }

    // Generic Cleanups
    if (message.startsWith("Exception: ")) {
      message = message.replaceAll("Exception: ", "");
    }

    // Fallback for very long technical errors
    if (message.length > 100) {
      return "An unexpected error occurred. Please try again.";
    }

    return message;
  }
}
