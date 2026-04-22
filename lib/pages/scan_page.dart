import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';
import '../services/leaf_disease_service.dart';
import '../services/offline_storage_service.dart';
import '../l10n/app_localizations.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _cornerController;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _cornerAnim;

  bool _isScanning = false;
  bool _isProcessing = false;
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final LeafDiseaseService _leafDiseaseService = LeafDiseaseService.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService.instance;

  @override
  void initState() {
    super.initState();
    
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _cornerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scanAnim = CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut);
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _cornerAnim = CurvedAnimation(parent: _cornerController, curve: Curves.easeOutBack);
    
    // Initialize the leaf disease service
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _leafDiseaseService.initialize();
      print('? Leaf disease model initialized successfully');
      if (mounted) setState(() {}); // Rebuild UI when ready
    } catch (e) {
      print('? Failed to initialize leaf disease model: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model initialization failed: $e'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _cornerController.dispose();
    super.dispose();
  }

  /// Open camera to capture leaf image
  Future<void> _openCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan leaves'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      setState(() => _isProcessing = true);

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening camera: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Open gallery to pick leaf image
  Future<void> _openGallery() async {
    try {
      // Request storage permission for older Android versions
      await Permission.photos.request();
      
      // Try to open gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isProcessing = true;
        });
        await _processImage();
      }
    } catch (e) {
      // If permission denied, try alternative approach
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing gallery: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Process the selected image through the TFLite model
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isScanning = true);

    try {
      // Show processing animation
      await Future.delayed(const Duration(milliseconds: 1500));

      // Run classification - this will handle initialization internally
      final prediction = await _leafDiseaseService.classifyImage(_selectedImage!);

      await _offlineStorage.incrementPredictionCount();

      if (mounted) {
        // Navigate to advisory page with prediction result
        Navigator.pushReplacementNamed(
          context,
          '/advisory',
          arguments: {'disease': prediction.disease, 'id': prediction.id},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      setState(() => _isScanning = false);
    }
  }

  void _startScan() async {
    // Open camera directly when scan button is tapped
    await _openCamera();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      showBottomNav: true,
      currentIndex: 0,
      extendBodyBehindAppBar: true,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.logout, color: Colors.white, size: 18),
          label: Text(
            l10n?.profile ?? 'Logout',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onPressed: _handleLogout,
        ),
      ],
      body: Stack(
        children: [
          // Camera area (background)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1A10),
                    Color(0xFF0D2818),
                    Color(0xFF112213),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background leaf hint
                  Center(
                    child: Opacity(
                      opacity: 0.04,
                      child: Icon(
                        Icons.eco,
                        size: 300,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // Vignette overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content Column
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'AI Diagnosis',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'AI Ready',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40), // Spacing below top bar

                // Viewfinder (Scan Area) - Moved to top
                Center(
                  child: AnimatedBuilder(
                    animation: _cornerAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + 0.2 * _cornerAnim.value,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        children: [
                          ..._buildCorners(),

                          // Scan line
                          AnimatedBuilder(
                            animation: _scanAnim,
                            builder: (context, _) {
                              return Positioned(
                                top: 16 + _scanAnim.value * 248,
                                left: 16,
                                right: 16,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.primary.withValues(alpha: 0.8),
                                        AppColors.primaryLight,
                                        AppColors.primary.withValues(alpha: 0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.primary,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Center target
                          Center(
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 
                                        0.3 + _pulseAnim.value * 0.4,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withValues(alpha: 
                                          0.6 + _pulseAnim.value * 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20), // Spacing below viewfinder

                                // Guide text
                Column(
                  children: [
                    Text(
                      _isScanning ? (l10n?.appTitle != null ? 'Analyzing...' : 'Analyzing leaf...') : _isProcessing ? 'Processing image...' : (l10n?.alignLeaf ?? 'Align the leaf within the frame'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.80),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n?.daylightTip ?? 'Works best in natural daylight',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(), // Pushes everything below to the bottom

                // Quick tips row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TipChip(label: l10n?.focusTip.split(' / ')[0] ?? 'Front side'),
                      const SizedBox(width: 8),
                      _TipChip(label: l10n?.focusTip.split(' / ')[1] ?? 'Good light'),
                      const SizedBox(width: 8),
                      _TipChip(label: l10n?.focusTip.split(' / ')[2] ?? 'In focus'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Real-time detection button - Re-added here
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/realtime');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.realTimeDetection ?? 'Real-Time Detection',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 24),

                // Bottom controls (Scan and Gallery)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // Padding from the very bottom
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery button
                      _CircleControl(
                        icon: Icons.photo_library_outlined,
                        onTap: _isProcessing ? null : _openGallery,
                      ),

                      // Capture button
                      GestureDetector(
                        onTap: (_isScanning || _isProcessing) ? null : _startScan,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) {
                            return Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 
                                      _isScanning || _isProcessing
                                          ? 0.3 + _pulseAnim.value * 0.3
                                          : 0.2,
                                    ),
                                    blurRadius: _isScanning || _isProcessing ? 24 : 12,
                                    spreadRadius: _isScanning || _isProcessing ? 4 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isScanning || _isProcessing
                                    ? SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 64,
                                        height: 64,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primaryDark,
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.document_scanner,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Placeholder for removed Flash button (maintaining spacing)
                      const SizedBox(width: 52, height: 52), // Same size as CircleControl
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double cornerLen = 28;
    const double cornerThick = 3;
    const Color color = AppColors.primary;

    Widget corner(double top, double left, double? right, double? bottom,
        bool flipH, bool flipV) {
      return Positioned(
        top: top == -1 ? null : top,
        left: left == -1 ? null : left,
        right: right,
        bottom: bottom,
        child: Transform.scale(
          scaleX: flipH ? -1 : 1,
          scaleY: flipV ? -1 : 1,
          child: SizedBox(
            width: cornerLen,
            height: cornerLen,
            child: CustomPaint(
              painter: _CornerPainter(color: color, thickness: cornerThick),
            ),
          ),
        ),
      );
    }

    return [
      corner(0, 0, null, null, false, false),
      corner(0, -1, 0, null, true, false),
      corner(-1, 0, null, 0, false, true),
      corner(-1, -1, 0, 0, true, true),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _TipChip extends StatelessWidget {
  final String label;
  const _TipChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.70),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleControl({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.90),
          size: 24,
        ),
      ),
    );
  }
}






