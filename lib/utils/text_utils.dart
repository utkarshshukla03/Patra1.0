/// Utility functions for text formatting and manipulation
class TextUtils {
  /// Capitalizes the first letter of a string and converts the rest to lowercase
  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalizes the first letter of each word in a string
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Formats a username by capitalizing the first letter
  static String formatUsername(String? username) {
    if (username == null || username.isEmpty) return 'Username';
    return capitalizeFirstLetter(username);
  }
}
