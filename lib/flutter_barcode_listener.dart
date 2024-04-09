library flutter_barcode_listener;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef BarcodeScannedCallback = void Function(String barcode);
typedef ContinuousScanCallback = void Function(List<String> barcodes);

/// This widget will listen for raw PHYSICAL keyboard events
/// even when other controls have primary focus.
/// It will buffer all characters coming in specifed `bufferDuration` time frame
/// that end with line feed character and call callback function with result.
/// Keep in mind this widget will listen for events even when not visible.
/// Windows seems to be using the [RawKeyDownEvent] instead of the
/// [RawKeyUpEvent], this behaviour can be managed by setting [useKeyDownEvent].
class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback _onBarcodeScanned;
  final Duration _bufferDuration;
  final bool useKeyDownEvent;
  

  /// Make barcode scanner return case sensitive characters
  ///
  /// Default value is false, It will sent scanned barcode with case sensitive
  /// characters. It listen to [LogicalKeyboardKey.shiftLeft]
  /// Currently support for Android
  final bool caseSensitive;

  /// This widget will listen for raw PHYSICAL keyboard events
  /// even when other controls have primary focus.
  /// It will buffer all characters coming in specifed `bufferDuration` time frame
  /// that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  BarcodeKeyboardListener(
      {Key? key,

      /// Child widget to be displayed.
      required this.child,
      ContinuousScanCallback? onContinuousScan,
      /// Callback to be called when barcode is scanned.
      required Function(String) onBarcodeScanned,

      /// When experiencing issueswith empty barcodes on Windows,
      /// set this value to true. Default value is `false`.
      this.useKeyDownEvent = false,
      
      /// Maximum time between two key events.
      /// If time between two key events is longer than this value
      /// previous keys will be ignored.
      Duration bufferDuration = hundredMs,
      this.caseSensitive = false,
      })
      : _onBarcodeScanned = onBarcodeScanned,
        _bufferDuration = bufferDuration,
         _onContinuousScanCallback = onContinuousScan,
        super(key: key);
final ContinuousScanCallback? _onContinuousScanCallback;
  @override
  _BarcodeKeyboardListenerState createState() => _BarcodeKeyboardListenerState(
      _onBarcodeScanned, _bufferDuration, useKeyDownEvent, caseSensitive
      );
}

const Duration aSecond = Duration(seconds: 1);
const Duration hundredMs = Duration(milliseconds: 100);
const String lineFeed = '\n';

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  List<String> _scannedChars = [];
  DateTime? _lastScannedCharCodeTime;
  late StreamSubscription<String?> _keyboardSubscription;
final ContinuousScanCallback _onContinuousScanCallback;
  List<String> _continuousScans = [];

  final BarcodeScannedCallback _onBarcodeScannedCallback;
  final Duration _bufferDuration;

  final _controller = StreamController<String?>();

  final bool _useKeyDownEvent;

  final bool _caseSensitive;

  bool _isShiftPressed = false;

  _BarcodeKeyboardListenerState(this._onBarcodeScannedCallback,
      this._bufferDuration, this._useKeyDownEvent, this._caseSensitive, this._onContinuousScanCallback,) {
    RawKeyboard.instance.addListener(_keyBoardCallback);
    _keyboardSubscription =
        _controller.stream.where((char) => char != null).listen(onKeyEvent);
  }

  void onKeyEvent(String? char) {
    //remove any pending characters older than bufferDuration value
    checkPendingCharCodesToClear();
    
   if (_continuousScans.isNotEmpty && _onContinuousScanCallback != null) {
      _onContinuousScanCallback!(_continuousScans);
      _continuousScans = [];
    }

    if (char == lineFeed) {
      _onBarcodeScannedCallback.call(_scannedChars.join());
      resetScannedCharCodes();
    } else {
      //add character to list of scanned characters;
      _scannedChars.add(char!);
    }
  }

  void checkPendingCharCodesToClear() {
    if (_lastScannedCharCodeTime != null) {
      if (_lastScannedCharCodeTime!
          .isBefore(DateTime.now().subtract(_bufferDuration))) {
        resetScannedCharCodes();
      }
    }
  }

  void resetScannedCharCodes() {
    _lastScannedCharCodeTime = null;
    _scannedChars = [];
  }

  void addScannedCharCode(String charCode) {
    _scannedChars.add(charCode);
  }

  void _keyBoardCallback(RawKeyEvent keyEvent) {
    if (keyEvent.logicalKey.keyId > 255 &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.enter &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.shiftLeft) return;
    if ((!_useKeyDownEvent && keyEvent is RawKeyUpEvent) ||
        (_useKeyDownEvent && keyEvent is RawKeyDownEvent)) {
      if (keyEvent.data is RawKeyEventDataAndroid) {
        if (keyEvent.data.logicalKey == LogicalKeyboardKey.shiftLeft) {
          _isShiftPressed = true;
        } else {
          if (_isShiftPressed && _caseSensitive) {
            _isShiftPressed = false;
            _controller.sink.add(String.fromCharCode(
                ((keyEvent.data) as RawKeyEventDataAndroid).codePoint).toUpperCase());
          } else {
            _controller.sink.add(String.fromCharCode(
                ((keyEvent.data) as RawKeyEventDataAndroid).codePoint));
          }
        }
      } else if (keyEvent.data is RawKeyEventDataFuchsia) {
        _controller.sink.add(String.fromCharCode(
            ((keyEvent.data) as RawKeyEventDataFuchsia).codePoint));
      } else if (keyEvent.data.logicalKey == LogicalKeyboardKey.enter) {
        _controller.sink.add(lineFeed);
      } else if (keyEvent.data is RawKeyEventDataWeb) {
        _controller.sink.add(((keyEvent.data) as RawKeyEventDataWeb).keyLabel);
      } else if (keyEvent.data is RawKeyEventDataLinux) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataLinux).keyLabel);
      } else if (keyEvent.data is RawKeyEventDataWindows) {
        _controller.sink.add(String.fromCharCode(
            ((keyEvent.data) as RawKeyEventDataWindows).keyCode));
      } else if (keyEvent.data is RawKeyEventDataMacOs) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataMacOs).characters);
      } else if (keyEvent.data is RawKeyEventDataIos) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataIos).characters);
      } else {
        _controller.sink.add(keyEvent.character);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _controller.close();
    RawKeyboard.instance.removeListener(_keyBoardCallback);
    super.dispose();
  }
}
