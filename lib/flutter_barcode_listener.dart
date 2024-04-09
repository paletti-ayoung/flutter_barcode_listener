import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef BarcodeScannedCallback = void Function(String barcode);
typedef ContinuousScanCallback = void Function(List<String> barcodes);

class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback _onBarcodeScanned;
  final Duration _bufferDuration;
  final ContinuousScanCallback? _onContinuousScanCallback;
  final bool useKeyDownEvent;
  final Duration scanInterval;

  BarcodeKeyboardListener({
    Key? key,
    required this.child,
    required Function(String) onBarcodeScanned,
    ContinuousScanCallback? onContinuousScan,
    this.useKeyDownEvent = false,
    Duration bufferDuration = const Duration(milliseconds: 300),
    this.scanInterval = const Duration(milliseconds: 500),
  })  : _onBarcodeScanned = onBarcodeScanned,
        _onContinuousScanCallback = onContinuousScan,
        _bufferDuration = bufferDuration,
        super(key: key);

  @override
  _BarcodeKeyboardListenerState createState() => _BarcodeKeyboardListenerState(
        _onBarcodeScanned,
        _bufferDuration,
        useKeyDownEvent,
        _onContinuousScanCallback,
        scanInterval,
      );
}

const String lineFeed = '\n';

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  List<String> _scannedChars = [];
  DateTime? _lastScannedCharCodeTime;
  late StreamSubscription<String?> _keyboardSubscription;

  final BarcodeScannedCallback _onBarcodeScannedCallback;
  final ContinuousScanCallback? _onContinuousScanCallback;
  final Duration _bufferDuration;
  final bool _useKeyDownEvent;
  final Duration _scanInterval;

  final _controller = StreamController<String?>();

  _BarcodeKeyboardListenerState(
    this._onBarcodeScannedCallback,
    this._bufferDuration,
    this._useKeyDownEvent,
    this._onContinuousScanCallback,
    this._scanInterval,
  ) {
    RawKeyboard.instance.addListener(_keyBoardCallback);
    _keyboardSubscription =
        _controller.stream.where((char) => char != null).listen(onKeyEvent);
  }

  @override
  void initState() {

    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");

    Future.delayed(Duration(milliseconds: 300), () {
         onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");

    });

    Future.delayed(Duration(milliseconds: 600), () {
       onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    onKeyEvent("test11\n");
    });
  }

  void onKeyEvent(String? char) {
    checkPendingCharCodesToClear();
    print("char = " + char!);
    print("lineFeed = " +lineFeed);
    if (char == lineFeed) {
      if (_scannedChars.isNotEmpty && _isWithinScanInterval()) {
        print("연속연속?");
        _onContinuousScanCallback?.call(_scannedChars);
      }
      _resetScanInterval();
      _onBarcodeScannedCallback(_scannedChars.join());
      resetScannedCharCodes();
    } else {
      _scannedChars.add(char!);
    }
  }

  bool _isWithinScanInterval() {
    return _lastScannedCharCodeTime != null &&
        DateTime.now().difference(_lastScannedCharCodeTime!) <= _scanInterval;
  }

  void _resetScanInterval() {
    _lastScannedCharCodeTime = DateTime.now();
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

  void _keyBoardCallback(RawKeyEvent keyEvent) {
    if (keyEvent.logicalKey.keyId > 255 &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.enter &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.shiftLeft) return;

    if ((!_useKeyDownEvent && keyEvent is RawKeyUpEvent) ||
        (_useKeyDownEvent && keyEvent is RawKeyDownEvent)) {
      if (keyEvent.data is RawKeyEventDataAndroid) {
        if (keyEvent.data.logicalKey == LogicalKeyboardKey.shiftLeft) {
          // Handle shift key if needed
        } else {
          _controller.sink.add(String.fromCharCode(
              (keyEvent.data as RawKeyEventDataAndroid).codePoint));
        }
      } else if (keyEvent.data is RawKeyEventDataFuchsia) {
        _controller.sink.add(String.fromCharCode(
            (keyEvent.data as RawKeyEventDataFuchsia).codePoint));
      } else if (keyEvent.data.logicalKey == LogicalKeyboardKey.enter) {
        _controller.sink.add(lineFeed);
      } else if (keyEvent.data is RawKeyEventDataWeb) {
        _controller.sink.add((keyEvent.data as RawKeyEventDataWeb).keyLabel);
      } else if (keyEvent.data is RawKeyEventDataLinux) {
        _controller.sink.add((keyEvent.data as RawKeyEventDataLinux).keyLabel);
      } else if (keyEvent.data is RawKeyEventDataWindows) {
        _controller.sink.add(String.fromCharCode(
            (keyEvent.data as RawKeyEventDataWindows).keyCode));
      } else if (keyEvent.data is RawKeyEventDataMacOs) {
        _controller.sink
            .add((keyEvent.data as RawKeyEventDataMacOs).characters);
      } else if (keyEvent.data is RawKeyEventDataIos) {
        _controller.sink.add((keyEvent.data as RawKeyEventDataIos).characters);
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
