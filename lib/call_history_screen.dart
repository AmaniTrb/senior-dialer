import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
 
import 'contact_utils.dart';
 
/// Shows recent calls. Tapping an entry calls that number back, matching
/// the same "tap to call" behavior as the main contacts screen.
class CallHistoryScreen extends StatefulWidget {
  final List<Contact> contacts;
 
  const CallHistoryScreen({super.key, required this.contacts});
 
  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}
 
class _CallHistoryScreenState extends State<CallHistoryScreen> {
  List<CallLogEntry> _entries = [];
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
 
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      setState(() {
        _loading = false;
        _error =
            'This needs permission to see call history.\nPlease allow "Phone" access in Settings.';
      });
      return;
    }
 
    try {
      final entries = await CallLog.query();
      setState(() {
        _entries = entries.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load call history.\n$e';
      });
    }
  }
 
  Future<void> _callBack(String? number) async {
    if (number == null || number.isEmpty) return;
    await FlutterPhoneDirectCaller.callNumber(number);
  }
 
  IconData _iconFor(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.rejected:
      case CallType.blocked:
        return Icons.call_end;
      default:
        return Icons.call;
    }
  }
 
  Color _colorFor(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
      case CallType.rejected:
      case CallType.blocked:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
 
  DateTime? _timestamp(CallLogEntry entry) {
    // Different versions of the call_log package have returned this as
    // either an int or a numeric String -- handle both safely.
    final raw = entry.timestamp;
    if (raw == null) return null;
    final ms = raw is int ? raw : int.tryParse(raw.toString());
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Call History',
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
 
    if (_entries.isEmpty) {
      return const Center(
        child: Text('No call history yet.', style: TextStyle(fontSize: 22)),
      );
    }
 
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final matched = findContactForNumber(widget.contacts, entry.number);
        final name =
            matched?.displayName ?? entry.name ?? entry.number ?? 'Unknown';
        final photoBytes = matched?.photo ?? matched?.thumbnail;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final ts = _timestamp(entry);
        final dateText = ts != null ? DateFormat('MMM d, HH:mm').format(ts) : '';
 
        return InkWell(
          onTap: () => _callBack(entry.number),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage:
                      photoBytes != null ? MemoryImage(photoBytes) : null,
                  child: photoBytes == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 26,
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
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(dateText,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(_iconFor(entry.callType),
                    color: _colorFor(entry.callType), size: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}