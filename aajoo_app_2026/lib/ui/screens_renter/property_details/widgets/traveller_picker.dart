import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/models/traveller_model.dart';
import 'package:rent_home/service/traveller_service.dart';

/// Who is this stay actually for?
///
/// Mirrors the web's checkout step. Most bookings are somebody booking for
/// themselves, so that is the default and costs no extra taps. Booking for a
/// parent, a colleague or a child saves the traveller to the account and
/// reuses them next time, rather than asking for the same details again.
///
/// The government ID is optional on purpose: a guest halfway through checkout
/// with their documents in another room should not be stopped. It can be added
/// afterwards from this same list, and a failed upload never loses the
/// traveller who was just saved.
class TravellerPicker extends StatefulWidget {
  /// Currently chosen traveller; null means the account holder is staying.
  final int? value;
  final ValueChanged<int?> onChanged;

  const TravellerPicker({super.key, required this.value, required this.onChanged});

  @override
  State<TravellerPicker> createState() => _TravellerPickerState();
}

class _TravellerPickerState extends State<TravellerPicker> {
  final _service = TravellerService();

  List<Traveller> _list = const [];
  bool _forSelf = true;
  bool _busy = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    _forSelf = widget.value == null;
    _load();
  }

  /// What went wrong, in words a guest can act on.
  ///
  /// `e.toString()` on a Dio failure is four lines of "DioException
  /// [connection error] … SocketFailed host lookup … errno = 7", which tells
  /// somebody trying to remove a guest nothing at all. The server's own
  /// message is good and is kept; everything below it becomes plain English.
  String _reason(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String &&
          (data['message'] as String).trim().isNotEmpty) {
        return data['message'] as String;
      }
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return 'No connection. Check your internet and try again.';
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'That took too long. Try again in a moment.';
        default:
          break;
      }
      if (e.response?.statusCode == 401) {
        return 'Your session has expired. Sign in again to make changes.';
      }
      return fallback;
    }
    final text = e.toString().replaceFirst('Exception: ', '');
    // A stringified exception that still looks like one is not a message.
    return text.contains('Exception') || text.contains('\n') ? fallback : text;
  }

  Future<void> _load() async {
    final rows = await _service.list();
    if (!mounted) return;
    setState(() => _list = rows);
  }

  Future<void> _openForm() async {
    final saved = await showModalBottomSheet<Traveller>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTravellerSheet(),
    );
    if (saved == null || !mounted) return;
    setState(() {
      _list = [saved, ..._list];
      _forSelf = false;
    });
    widget.onChanged(saved.id);
  }

  Future<void> _attach(Traveller t) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    setState(() { _busy = true; _note = null; });
    try {
      final updated = await _service.uploadDocument(t.id, path, docType: t.docType);
      if (!mounted) return;
      setState(() => _list = _list.map((x) => x.id == t.id ? updated : x).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _note = _reason(e, "That ID didn't upload. Please try again."));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Traveller t) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove guest'),
        content: Text('Remove ${t.fullName} from your saved guests?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (yes != true) return;

    // The row is only taken off screen once the server has actually removed
    // it. It used to go the moment the request was SENT, so a refusal left
    // the guest looking at a list that said they were gone and a server that
    // disagreed — and the next time the sheet opened, they were back.
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      await _service.remove(t.id);
      if (!mounted) return;
      setState(() => _list = _list.where((x) => x.id != t.id).toList());
      if (widget.value == t.id) widget.onChanged(null);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _note = _reason(e, "Couldn't remove that guest. Please try again."));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who is this stay for?',
              style: fraunces(
                  fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 4),
          Text(
            "Hosts keep a record of who is staying. Booking for someone else? Add their details.",
            style: inter(fontSize: 12, color: kMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          // Wrap, not two Expandeds sharing a row.
          //
          // "Booking for someone else" is the website's wording and it does
          // not fit half a phone's width — split down the middle it rendered
          // as "Booking for someone …", which hides the one word that says
          // whose stay it is. The site wraps these buttons; so does this, so
          // a label that needs a full line gets one instead of being cut.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                label: "I'm staying",
                icon: Icons.person_outline,
                selected: _forSelf,
                onTap: () {
                  setState(() { _forSelf = true; _note = null; });
                  widget.onChanged(null);
                },
              ),
              _Choice(
                label: 'Booking for someone else',
                icon: Icons.group_outlined,
                selected: !_forSelf,
                onTap: () {
                  setState(() => _forSelf = false);
                  // Nothing is silently adopted — an explicit pick, or the
                  // form. Leaving the value null keeps Book honest about
                  // what is still missing.
                  if (_list.isEmpty) _openForm();
                },
              ),
            ],
          ),
          if (!_forSelf) ...[
            const SizedBox(height: 12),
            for (final t in _list) _row(t),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _busy ? null : _openForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add someone new'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: kIndigo),
            ),
          ],
          if (_note != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDanger.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 15, color: kDanger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_note!,
                        style: inter(
                            fontSize: 12, color: kDanger, height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(Traveller t) {
    final picked = widget.value == t.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: picked ? kIndigo50 : kSurface,
        border: Border.all(
          color: picked ? kIndigo : kLine,
          width: picked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => widget.onChanged(t.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.fullName,
                      style: inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 1),
                  Text(
                    // "25 yrs · male · 8901717173", or a plain sentence when
                    // the guest gave nothing but a name — the website's
                    // wording, so the same row reads the same on both.
                    t.summary.trim().isEmpty ? 'No other details' : t.summary,
                    style: inter(fontSize: 11.5, color: kMuted),
                  ),
                ],
              ),
            ),
          ),
          if (t.hasDocument)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_user_outlined,
                    size: 11, color: kSuccess),
                const SizedBox(width: 4),
                Text('ID on file',
                    style: inter(
                        fontSize: 10.5,
                        color: kSuccess,
                        fontWeight: FontWeight.w600)),
              ]),
            )
          else
            TextButton(
              onPressed: _busy ? null : () => _attach(t),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                foregroundColor: kIndigo,
              ),
              child: Text('Add ID',
                  style: inter(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            onPressed: _busy ? null : () => _remove(t),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: kMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? kIndigo : kSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? kIndigo : kLine),
        ),
        // Sizes to its label rather than to half the row, so nothing is cut.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : kMuted),
            const SizedBox(width: 7),
            Text(
              label,
              style: inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : kInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The add-a-guest form, as a sheet so it has room on a phone.
class _AddTravellerSheet extends StatefulWidget {
  const _AddTravellerSheet();

  @override
  State<_AddTravellerSheet> createState() => _AddTravellerSheetState();
}

class _AddTravellerSheetState extends State<_AddTravellerSheet> {
  final _service = TravellerService();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController();

  String _gender = 'unspecified';
  String _docType = '';
  String? _filePath;
  String? _fileName;
  bool _busy = false;
  String? _note;

  static const _idTypes = ['Aadhaar', 'Passport', 'Driving Licence', 'Voter ID', 'Other'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final f = picked?.files.single;
    if (f?.path == null || !mounted) return;
    setState(() { _filePath = f!.path; _fileName = f.name; });
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _note = "Enter the guest's name.");
      return;
    }
    setState(() { _busy = true; _note = null; });
    try {
      var saved = await _service.save(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        age: int.tryParse(_age.text.trim()),
        gender: _gender,
        docType: _docType,
      );
      if (_filePath != null) {
        // A failed upload must not lose the guest just saved — they are on the
        // account already and the ID can be added from the list.
        try {
          saved = await _service.uploadDocument(saved.id, _filePath!, docType: _docType);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Guest saved, but the ID didn't upload. Add it from the list."),
            ));
          }
        }
      }
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _note = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  decoration: BoxDecoration(
                    color: kLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Add a guest',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _field(_name, 'Full name', TextInputType.name),
              _field(_phone, 'Phone', TextInputType.phone),
              _field(_email, 'Email', TextInputType.emailAddress),
              _field(_age, 'Age', TextInputType.number),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'unspecified', child: Text('Prefer not to say')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'unspecified'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _docType.isEmpty ? null : _docType,
                decoration: const InputDecoration(labelText: 'ID type', border: OutlineInputBorder()),
                items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _docType = v ?? ''),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(_fileName ?? 'Government ID (optional)'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 12, color: kMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Stored privately. Only you, the host of this stay, and Aajoo support can open it.',
                      style: TextStyle(fontSize: 10.5, color: kMuted),
                    ),
                  ),
                ],
              ),
              if (_note != null) ...[
                const SizedBox(height: 8),
                Text(_note!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_busy ? 'Saving…' : 'Save guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// keyboardType is a hint about which keys to SHOW, not a rule about which
  /// characters may arrive: a paste, a hardware keyboard or a swipe keyboard
  /// all ignore it. These four fields had nothing else, so the app accepted
  /// traveller names with digits and phone numbers with letters where the web
  /// form (redesign/components/TravellerPicker.tsx) filtered all four.
  Widget _field(TextEditingController c, String label, TextInputType type) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: type,
          inputFormatters: _formattersFor(type),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  List<TextInputFormatter> _formattersFor(TextInputType type) {
    if (type == TextInputType.name) return AppInputFormatters.name;
    if (type == TextInputType.phone) return AppInputFormatters.mobile;
    if (type == TextInputType.emailAddress) return AppInputFormatters.email;
    if (type == TextInputType.number) return AppInputFormatters.digits(3);
    return const [];
  }
}
