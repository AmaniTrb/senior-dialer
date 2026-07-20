import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
 
import 'call_history_screen.dart';
import 'messages_screen.dart';
 
void main() {
  runApp(const GrandmaDialerApp());
}
 
class GrandmaDialerApp extends StatelessWidget {
  const GrandmaDialerApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grandma Dialer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        // Big base font size everywhere in the app.
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 26),
          bodyMedium: TextStyle(fontSize: 22),
        ),
      ),
      home: const ContactsScreen(),
    );
  }
}
 
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
 
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}
 
class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  bool _loading = true;
  String? _error;
 
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
 
  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
 
    // Ask for contacts permission and call permission (call permission is
    // required to place calls directly without opening the dialer).
    final contactsStatus = await Permission.contacts.request();
    final phoneStatus = await Permission.phone.request();
 
    if (!contactsStatus.isGranted) {
      setState(() {
        _loading = false;
        _error =
            'This app needs permission to read contacts.\nPlease allow "Contacts" access in Settings.';
      });
      return;
    }
 
    if (!phoneStatus.isGranted) {
      setState(() {
        _loading = false;
        _error =
            'This app needs permission to make calls.\nPlease allow "Phone" access in Settings.';
      });
      return;
    }
 
    try {
      // withProperties: true -> also loads phone numbers.
      // withPhoto: true -> loads full-size saved photo.
      // withThumbnail: true -> loads the smaller cached thumbnail, which is
      // more reliably available than the full photo for many contacts.
      final all = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
        withThumbnail: true,
      );
 
      // Keep only contacts that have at least one phone number.
      // (A contact with no number is useless in a dialer.)
      final withNumbers = all.where((c) => c.phones.isNotEmpty).toList();
 
      // Sort by first name so the list is predictable.
      withNumbers.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
 
      setState(() {
        _contacts = withNumbers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load contacts.\n$e';
      });
    }
  }
 
  Future<void> _call(String phoneNumber) async {
    // Places the call directly -- no dialer screen, no extra tap needed.
    final res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    if (res != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not place the call.')),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Call',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 32),
            tooltip: 'Call history',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallHistoryScreen(contacts: _contacts),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined, size: 32),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagesScreen(contacts: _contacts),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }
 
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
 
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadContacts,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Try again', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      );
    }
 
    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts with phone numbers found.',
          style: TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
      );
    }
 
    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fewer contacts fit per screen in landscape, since there's much
          // less height to work with -- this keeps each tile a sensible
          // size instead of squeezing everything and overflowing.
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          final contactsPerScreen = isLandscape ? 2.6 : 4.2;
          final tileHeight = constraints.maxHeight / contactsPerScreen;
 
          return ListView.separated(
            itemCount: _contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              final phone = contact.phones.first.number;
              return ContactTile(
                contact: contact,
                phoneNumber: phone,
                tileHeight: tileHeight,
                onTap: () => _call(phone),
              );
            },
          );
        },
      ),
    );
  }
}
 
class ContactTile extends StatelessWidget {
  final Contact contact;
  final String phoneNumber;
  final double tileHeight;
  final VoidCallback onTap;
 
  const ContactTile({
    super.key,
    required this.contact,
    required this.phoneNumber,
    required this.tileHeight,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    // Prefer the full photo; fall back to the thumbnail if only that
    // was available (some contacts only have a thumbnail synced).
    final photoBytes = contact.photo ?? contact.thumbnail;
    final initial = contact.displayName.isNotEmpty
        ? contact.displayName[0].toUpperCase()
        : '?';
 
    // Photo diameter fills most of the tile height, leaving a little
    // breathing room above/below. Made bigger than before.
    final avatarRadius = (tileHeight * 0.46).clamp(38.0, 100.0);
 
    // Text sizes scale with the tile height instead of being fixed, so
    // they always fit -- this is what was overflowing in landscape mode,
    // where tiles are naturally shorter.
    final nameFontSize = (tileHeight * 0.22).clamp(16.0, 30.0);
    final numberFontSize = (tileHeight * 0.16).clamp(13.0, 22.0);
    final textGap = (tileHeight * 0.05).clamp(2.0, 8.0);
 
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: tileHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Photo on the left. Tapping anywhere on the row calls,
              // so the whole row is one big, forgiving touch target.
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.teal.shade100,
                backgroundImage:
                    photoBytes != null ? MemoryImage(photoBytes) : null,
                child: photoBytes == null
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontSize: avatarRadius * 0.8,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 24),
              // Name and number on the right.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.displayName,
                      style: TextStyle(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: textGap),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: numberFontSize,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}