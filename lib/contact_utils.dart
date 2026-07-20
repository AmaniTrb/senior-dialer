import 'package:flutter_contacts/flutter_contacts.dart';
 
/// Keeps only the digits of a phone number, and drops any leading country
/// code by comparing just the last [length] digits. This makes numbers
/// like "+213 555 12 34 56", "0555123456" and "555123456" all match as
/// the same number, even though they're formatted differently.
String _lastDigits(String? number, {int length = 9}) {
  if (number == null) return '';
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= length) return digits;
  return digits.substring(digits.length - length);
}
 
/// Finds the saved contact (if any) whose phone number matches [number].
/// Call history and SMS entries only give us a raw phone number, so this
/// is what lets us show the contact's real name and photo instead.
Contact? findContactForNumber(List<Contact> contacts, String? number) {
  if (number == null || number.isEmpty) return null;
  final target = _lastDigits(number);
  if (target.isEmpty) return null;
 
  for (final contact in contacts) {
    for (final phone in contact.phones) {
      if (_lastDigits(phone.number) == target) {
        return contact;
      }
    }
  }
  return null;
}
 