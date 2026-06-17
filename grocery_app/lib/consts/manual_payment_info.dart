/// Bank / wallet details shown at checkout. Edit here only.
///
/// If this repo is public, move these values to a private config or remote flags.
class ManualPaymentInfo {
  ManualPaymentInfo._();

  static const accountHolder = 'Meezan bank :HUSNAIN AMIN';
  static const bankAccountNumber = '00300109953931';
  static const iban = 'PK94MEZN0000300109953931';

  static const walletDisplayName = 'Husnain Amin';
  /// Easypaisa / JazzCash — same number can be used for WhatsApp.
  static const walletPhoneDisplay = '03068502553';

  /// `wa.me` expects country code without `+` (Pakistan = 92).
  static const whatsAppWaMeDigits = '923068502553';

  static Uri whatsAppUriWithMessage(String message) {
    final encoded = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$whatsAppWaMeDigits?text=$encoded');
  }

  static String copyBlock() {
    return '''
Account name: $accountHolder
Account number: $bankAccountNumber
IBAN: $iban

Easypaisa / JazzCash
Name: $walletDisplayName
Mobile: $walletPhoneDisplay

Send payment screenshot on WhatsApp: $walletPhoneDisplay
'''.trim();
  }
}
