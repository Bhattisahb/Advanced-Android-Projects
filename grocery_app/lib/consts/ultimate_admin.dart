/// Ultimate admin identity — **must stay in sync** with `ultimateAdminEmailStr()`
/// in [firestore.rules].
const kUltimateAdminEmail = 'husnainbhatti943@gmail.com';

bool isUltimateAdminCustomerEmail(String? email) {
  if (email == null || email.isEmpty) return false;
  return email.toLowerCase().trim() == kUltimateAdminEmail;
}
