import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../widgets/nfc_pulse.dart';

enum _NfcStatus { detecting, notDetected, success, error, unavailable }

class NfcActionDialog extends StatefulWidget {
  const NfcActionDialog();

  @override
  State<NfcActionDialog> createState() => _NfcActionDialogState();
}

class _NfcActionDialogState extends State<NfcActionDialog>
    with SingleTickerProviderStateMixin {
  static const _nfcUri = 'migraine-tracker://log';
  late final AnimationController _pulseController;
  _NfcStatus _status = _NfcStatus.detecting;
  String _message = 'Detecting NFC chip...';
  Timer? _timeout;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _startNfc();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _pulseController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfc() async {
    final available = await NfcManager.instance.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _status = _NfcStatus.unavailable;
        _message = 'NFC not available on this device.';
      });
      return;
    }

    _completed = false;
    setState(() {
      _status = _NfcStatus.detecting;
      _message =
          'Hold an NFC tag near your phone to program it with the app shortcut.';
    });

    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 8), () async {
      if (_completed || !mounted) return;
      await NfcManager.instance.stopSession();
      if (!mounted) return;
      setState(() {
        _status = _NfcStatus.notDetected;
        _message = 'Not detected';
      });
    });

    NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        if (_completed) return;
        _completed = true;
        _timeout?.cancel();
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw Exception('Tag not writable');
          }
          final msg = NdefMessage([NdefRecord.createUri(Uri.parse(_nfcUri))]);
          await ndef.write(msg);
          await NfcManager.instance.stopSession();
          if (!mounted) return;
          setState(() {
            _status = _NfcStatus.success;
            _message =
                'NFC tag programmed. You can now tap it from Home/Lock screen to open logging.';
          });
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: e.toString());
          if (!mounted) return;
          setState(() {
            _status = _NfcStatus.error;
            _message = 'Error: $e';
          });
        }
      },
    );
  }

  Future<void> _scanAgain() async {
    await _startNfc();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError =
        _status == _NfcStatus.notDetected || _status == _NfcStatus.error;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Program NFC Tag',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            NfcPulse(
              controller: _pulseController,
              color: isError ? scheme.error : scheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? scheme.error : scheme.onSurface,
                fontWeight: isError ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            if (_status == _NfcStatus.notDetected ||
                _status == _NfcStatus.error)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _scanAgain,
                      child: const Text('Scan again'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            if (_status == _NfcStatus.success ||
                _status == _NfcStatus.unavailable)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
