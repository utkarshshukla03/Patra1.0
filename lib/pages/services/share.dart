import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/qr_share_service.dart';
import '../../widgets/qr_scanner_page.dart';

class ShareProfile extends StatefulWidget {
  const ShareProfile({super.key});

  @override
  State<ShareProfile> createState() => _ShareProfileState();
}

class _ShareProfileState extends State<ShareProfile>
    with TickerProviderStateMixin {
  String? _userQRData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  late AnimationController _qrAnimationController;
  late AnimationController _successAnimationController;
  late Animation<double> _qrScaleAnimation;
  late Animation<double> _qrOpacityAnimation;
  late Animation<double> _successScaleAnimation;
  bool _showSuccessDialog = false;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _qrAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _qrScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _qrAnimationController, curve: Curves.elasticOut),
    );

    _qrOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _qrAnimationController, curve: Curves.easeInOut),
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _successAnimationController, curve: Curves.elasticOut),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _qrAnimationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        setState(() {
          _userData = {
            'uid': currentUser.uid,
            'name': data['username'] ?? 'Unknown User',
            'photo': data['photoUrl'] ??
                (data['photoUrls'] as List?)?.first ??
                'https://via.placeholder.com/400x600?text=No+Image',
            'age': data['age'] ?? 22,
            'bio': data['bio'] ?? 'No bio available',
          };

          // Generate QR code data with user ID
          _userQRData = 'patra_user:${currentUser.uid}';
          _isLoading = false;
        });

        // Start QR animation
        _qrAnimationController.forward();
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openQRScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          onScanSuccess: _handleQRScanResult,
        ),
      ),
    );
  }

  Future<void> _handleQRScanResult(String qrData) async {
    try {
      // Parse QR data (expecting format: "patra_user:uid")
      if (!qrData.startsWith('patra_user:')) {
        _showErrorDialog('Invalid QR code. Please scan a Patra user QR code.');
        return;
      }

      final scannedUserId = qrData.replaceFirst('patra_user:', '');
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _showErrorDialog('Please log in to send requests.');
        return;
      }

      if (scannedUserId == currentUser.uid) {
        _showErrorDialog('You cannot send a request to yourself!');
        return;
      }

      // Send the like request
      final success = await QRShareService.sendLikeRequest(scannedUserId);

      if (success) {
        setState(() {
          _successMessage = 'Request sent successfully! 💝';
          _showSuccessDialog = true;
        });
        _successAnimationController.forward();

        // Auto hide after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccessDialog = false;
            });
            _successAnimationController.reset();
          }
        });

        HapticFeedback.lightImpact();
      } else {
        _showErrorDialog('Failed to send request. Please try again.');
      }
    } catch (e) {
      print('Error handling QR scan: $e');
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Oops!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Share Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: Colors.pink.shade600,
                size: 28,
              ),
              onPressed: _openQRScanner,
              tooltip: 'Scan QR Code',
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_userData == null || _userQRData == null) {
      return const Center(
        child: Text(
          'Failed to load profile data',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Title and description
              Text(
                'Share Your Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let others scan this code to send you a like request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              // QR Code with profile picture
              _buildQRCodeWithAvatar(),

              const SizedBox(height: 40),

              // User info
              _buildUserInfo(),

              const SizedBox(height: 40),

              // Instructions
              _buildInstructions(),
            ],
          ),
        ),

        // Success animation overlay
        if (_showSuccessDialog) _buildSuccessOverlay(),
      ],
    );
  }

  Widget _buildQRCodeWithAvatar() {
    return AnimatedBuilder(
      animation: _qrAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _qrScaleAnimation.value,
          child: Opacity(
            opacity: _qrOpacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // QR Code
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.pink.shade100,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: PrettyQr(
                        data: _userQRData!,
                        size: 276,
                        roundEdges: true,
                        elementColor: Colors.grey.shade800,
                        errorCorrectLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),

                  // Profile picture in center
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.pink.shade200,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        _userData!['photo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.pink.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.pink.shade400,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(_userData!['photo']),
            backgroundColor: Colors.pink.shade100,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData!['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Age ${_userData!['age']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userData!['bio'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.pink.shade600,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '1. Show this QR code to someone you\'d like to connect with\n'
            '2. They can scan it using the scanner (📷) in the top right\n'
            '3. They\'ll automatically send you a like request\n'
            '4. You\'ll get notified and can accept or dismiss',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.pink.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successAnimationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Transform.scale(
              scale: _successScaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.green.shade600,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _successMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
