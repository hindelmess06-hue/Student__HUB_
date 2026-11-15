import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Student view: scan the organiser's QR code to log attendance.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _paste = TextEditingController();
  bool _handled = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.startsWith('studenthub://')) {
        _handled = true;
        _process(v);
        break;
      }
    }
  }

  Future<void> _process(String raw) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AppState>().checkIn(raw);
    if (!mounted) return;

    switch (result) {
      case CheckInResult.ok:
        nav.pop();
        messenger.showSnackBar(
            const SnackBar(content: Text('Checked in. Attendance logged')));
      case CheckInResult.already:
        nav.pop();
        messenger.showSnackBar(
            const SnackBar(content: Text('You are already checked in')));
      case CheckInResult.closed:
        _fail('This check-in session is closed.');
      case CheckInResult.invalid:
        _fail('That code is not valid or has been replaced. Ask the organiser for the current code.');
      case CheckInResult.error:
        _fail('Something went wrong. Please try again.');
    }
  }

  void _fail(String message) {
    setState(() {
      _busy = false;
      _handled = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppScaffold(
      body: Column(
        children: [
          const DetailTopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                Text('Scan to check in', style: AppText.display(30)),
                const SizedBox(height: 4),
                Text('Point your camera at the organiser\'s QR code.',
                    style: AppText.body(14.5, color: AppColors.muted)),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 340,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(onDetect: _onDetect),
                        Center(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: p.b, width: 3),
                            ),
                          ),
                        ),
                        if (_busy)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(_message!,
                      style: AppText.body(13.5,
                          color: AppColors.danger, height: 1.4)),
                ],
                const SizedBox(height: 26),
                Text('No camera? Paste the code instead',
                    style: AppText.display(16, color: AppColors.muted)),
                const SizedBox(height: 10),
                AppField(
                  controller: _paste,
                  hint: 'studenthub://checkin?...',
                  icon: Icons.link_rounded,
                ),
                const SizedBox(height: 12),
                GhostButton(
                  label: 'Check in with code',
                  icon: Icons.verified_rounded,
                  onTap: _busy ? null : () => _process(_paste.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
