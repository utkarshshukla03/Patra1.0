import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRScannerPage extends StatefulWidget {
  final Function(String) onScanSuccess;

  const QRScannerPage({
    super.key,
    required this.onScanSuccess,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with TickerProviderStateMixin {
  bool _isScanning = true;
  bool _flashOn = false;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _scanAnimationController.repeat();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _simulateQRScan() {
    // For demo purposes, simulate scanning a QR code
    // In a real implementation, this would use camera scanning
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate QR Scan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a user ID to simulate scanning their QR code:'),
            const SizedBox(height: 16),
            TextField(
              controller: _manualInputController,
              decoration: const InputDecoration(
                hintText: 'Enter user ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final userInput = _manualInputController.text.trim();
              if (userInput.isNotEmpty) {
                Navigator.pop(context);
                Navigator.pop(context);
                widget.onScanSuccess('patra_user:$userInput');
              }
            },
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 100,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Camera Preview',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR scanner will be implemented here',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanning frame overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.pink,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  ...List.generate(4, (index) {
                    final isTop = index < 2;
                    final isLeft = index % 2 == 0;
                    return Positioned(
                      top: isTop ? -4 : null,
                      bottom: !isTop ? -4 : null,
                      left: isLeft ? -4 : null,
                      right: !isLeft ? -4 : null,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isTop && isLeft ? 16 : 0),
                            topRight:
                                Radius.circular(isTop && !isLeft ? 16 : 0),
                            bottomLeft:
                                Radius.circular(!isTop && isLeft ? 16 : 0),
                            bottomRight:
                                Radius.circular(!isTop && !isLeft ? 16 : 0),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Top app bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _flashOn = !_flashOn;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        color: _flashOn ? Colors.yellow : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanning animation and instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scanning indicator
                  if (_isScanning) ...[
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  Colors.pink.withOpacity(_scanAnimation.value),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.pink,
                            size: 30,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions
                  Text(
                    _isScanning
                        ? 'Position QR code within frame'
                        : 'QR code detected!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point camera at the QR code to scan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Demo scan button
                  ElevatedButton(
                    onPressed: _simulateQRScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simulate QR Scan (Demo)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanning line animation
          if (_isScanning)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            top: 280 * _scanAnimation.value - 2,
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.pink,
                                    Colors.pink,
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
