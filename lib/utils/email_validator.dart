class EmailValidator {
  // List of accepted email domains
  static const List<String> acceptedDomains = [
    '@thapar.edu',
    '@thapr.edu',
    // Add more domains as needed
  ];

  static bool isValidInstitutionalEmail(String email) {
    if (email.isEmpty) return false;

    // Check if email matches any accepted domain
    return acceptedDomains
        .any((domain) => email.toLowerCase().endsWith(domain.toLowerCase()));
  }

  static String getEmailValidationMessage() {
    String domains = acceptedDomains.join(', ');
    return "Please use an email from one of these domains: $domains";
  }

  static bool isValidEmailFormat(String email) {
    // Basic email format validation
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }
}
