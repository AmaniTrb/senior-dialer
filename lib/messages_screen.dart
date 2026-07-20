import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
 
import 'contact_utils.dart';
 
/// Shows received text messages, read-only. There is deliberately no
/// text field, no reply button, and no compose screen -- she can look,
/// but there's nothing to accidentally type into.
class MessagesScreen extends StatefulWidget {
  final List<Contact> contacts;
 
  const MessagesScreen({super.key, required this.contacts});
 
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}
 
class _MessagesScreenState extends State<MessagesScreen> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];
  bool _loading = true;
  String? _error;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
 
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      setState(() {
        _loading = false;
        _error =
            'This needs permission to see messages.\nPlease allow "SMS" access in Settings.';
      });
      return;
    }
 
    try {
      final messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
      messages.sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load messages.\n$e';
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
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
 
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet.', style: TextStyle(fontSize: 22)),
      );
    }
 
    return ListView.separated(
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final matched = findContactForNumber(widget.contacts, msg.address);
        final name = matched?.displayName ?? msg.address ?? 'Unknown';
        final photoBytes = matched?.photo ?? matched?.thumbnail;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final dateText =
            msg.date != null ? DateFormat('MMM d, HH:mm').format(msg.date!) : '';
 
        // Plain, non-interactive tile: no onTap, no input field.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal.shade100,
                backgroundImage:
                    photoBytes != null ? MemoryImage(photoBytes) : null,
                child: photoBytes == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(dateText,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(msg.body ?? '', style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
 