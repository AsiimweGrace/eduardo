import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets.dart';
import '../services/leaf_disease_service.dart';
import '../services/offline_storage_service.dart';
import '../l10n/app_localizations.dart';

class AdvisoryPage extends StatefulWidget {
  final String? prediction;
  const AdvisoryPage({super.key, this.prediction});

  @override
  State<AdvisoryPage> createState() => _AdvisoryPageState();
}

class _AdvisoryPageState extends State<AdvisoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I am your Banana Health AI. How can I help you today?',
      'isUser': false
    },
  ];
  final OfflineStorageService _offlineStorage = OfflineStorageService.instance;

  String? currentPredictionId;
  String? currentPrediction;
  bool _hasPrediction = false;
  bool _isTyping = false;
  bool _isLoadingHistory = false;
  bool _isSendingFeedback = false;
  bool _showFloatingFeedback = false;
  List<DiseasePrediction> _predictionHistory = [];

  // Hugging Face Configuration
  final String _apiKey = '';
  final String _modelId = '';
  final String _baseUrl = 'https://api-inference.huggingface.co/models/';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
    _checkFeedbackVisibility();
  }

  Future<void> _checkFeedbackVisibility() async {
    final shouldShow = await _offlineStorage.shouldShowFeedback();
    if (mounted) {
      setState(() {
        _showFloatingFeedback = shouldShow;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;

    if (widget.prediction != null) {
      currentPrediction = widget.prediction;
      _hasPrediction = true;
    } else if (args != null) {
      if (args is String) {
        currentPrediction = args;
        _hasPrediction = true;
      } else if (args is Map<String, dynamic>) {
        currentPrediction = args['disease'] as String?;
        currentPredictionId = args['id'] as String?;
        _hasPrediction = true;
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await LeafDiseaseService.instance.getPredictionHistory();
      if (mounted) {
        setState(() {
          _predictionHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.logout ?? 'Logout'),
        content: Text(l10n?.areYouSureLogout ?? 'Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n?.cancel ?? 'Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(l10n?.logout ?? 'Logout')),
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

  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _chatController.clear();
      _isTyping = true;
    });

    try {
      final prompt =
          "<s>[INST] You are an expert Banana Plantation Agronomist. The farmer says: '$text'. The detected crop condition is: ${currentPrediction ?? 'unknown'}. Provide concise, professional advice. [/INST]";
      final response = await http.post(
        Uri.parse('$_baseUrl$_modelId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {'max_new_tokens': 250, 'return_full_text': false},
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final aiResponse =
            (data.isNotEmpty && data[0]['generated_text'] != null)
                ? data[0]['generated_text'] as String
                : "I am sorry, I couldn't process that.";
        if (mounted) {
          setState(() {
            _messages.add({'text': aiResponse.trim(), 'isUser': false});
            _isTyping = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _messages.add({
              'text': 'AI server error. Please try again later.',
              'isUser': false
            });
            _isTyping = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
              {'text': 'Connection error. Please try again.', 'isUser': false});
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n?.advisory ?? 'AI Advisory',
      showBottomNav: true,
      currentIndex: 1,
      actions: [
        IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
            onPressed: _handleLogout),
      ],
      body: Stack(
        children: [
          Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: l10n?.results ?? 'Diagnosis'),
                  Tab(text: l10n?.treatment ?? 'Treatment'),
                  Tab(text: l10n?.aiChat ?? 'AI Chat'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDiagnosisTab(),
                    _buildTreatmentTab(),
                    _buildChatTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_showFloatingFeedback)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showFeedbackSheet(context),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.feedback, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Half: Diagnosis Section
          Text(l10n?.currentDiagnosis ?? 'Current Diagnosis',
              style: AppTextStyles.subtitleSemiBold),
          const SizedBox(height: 12),
          if (!_hasPrediction || currentPrediction == null)
            SmallCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(l10n?.goToScan ?? 'Go to scan to see results',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textMuted)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/scan'),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n?.goToScan ?? 'Go to Scan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SmallCard(
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final bool isNonCropResult = currentPrediction != null &&
                          (currentPrediction!
                                  .toLowerCase()
                                  .contains('not a crop') ||
                              currentPrediction!
                                  .toLowerCase()
                                  .contains('non crop'));

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n?.scanResult ?? 'Scan Result',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500)),
                              InfoChip(
                                label: isNonCropResult
                                    ? (l10n?.noCropDetected ?? 'No Crop Detected')
                                    : currentPrediction!.toLowerCase() ==
                                            'healthy'
                                        ? (l10n?.healthy ?? 'Healthy')
                                        : (l10n?.diseaseDetected ?? 'Disease Detected'),
                                color: isNonCropResult
                                    ? AppColors.warning
                                    : currentPrediction!.toLowerCase() ==
                                            'healthy'
                                        ? AppColors.success
                                        : AppColors.danger,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                isNonCropResult
                                    ? Icons.block
                                    : currentPrediction!.toLowerCase() ==
                                            'healthy'
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_amber_rounded,
                                color: isNonCropResult
                                    ? AppColors.warning
                                    : currentPrediction!.toLowerCase() ==
                                            'healthy'
                                        ? AppColors.success
                                        : AppColors.warning,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  currentPrediction!,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!isNonCropResult)
                            GreenButton(
                              label: l10n?.seeTreatmentOptions ?? 'See Treatment Options',
                              icon: Icons.medication_liquid_rounded,
                              onPressed: () => _tabController.animateTo(1),
                              fullWidth: true,
                            ),
                          const SizedBox(height: 12),
                          _buildFeedbackSection(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Bottom Half: Scan History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n?.scanHistory ?? 'Scan History', style: AppTextStyles.subtitleSemiBold),
              IconButton(
                  icon: const Icon(Icons.refresh,
                      size: 18, color: AppColors.primary),
                  onPressed: _loadHistory),
            ],
          ),
          const SizedBox(height: 12),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingHistory && _predictionHistory.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }
    if (_predictionHistory.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n?.noHistory ?? 'No history found.',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _predictionHistory.length,
      itemBuilder: (context, index) {
        final item = _predictionHistory[index];
        final isHealthy = item.disease.toLowerCase() == 'healthy';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isHealthy
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.danger.withValues(alpha: 0.1),
              child: Icon(isHealthy ? Icons.eco : Icons.bug_report,
                  color: isHealthy ? AppColors.success : AppColors.danger,
                  size: 20),
            ),
            title: Text(item.disease,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
                '${_formatDateTime(item.timestamp)} • ${item.confidence.toStringAsFixed(1)}%'),
            trailing: TextButton(
              onPressed: () {
                setState(() {
                  currentPrediction = item.disease;
                  currentPredictionId = item.id;
                  _hasPrediction = true;
                });
                _tabController.animateTo(1);
              },
              child: Text(l10n?.viewTreatment ?? 'View Treatment',
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTreatmentTab() {
    final l10n = AppLocalizations.of(context);
    if (!_hasPrediction || currentPrediction == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(l10n?.scanInstruction ?? 'Scan a leaf to get treatment recommendations.',
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            GreenButton(
                label: l10n?.goToScan ?? 'Go to Scan',
                icon: Icons.camera_alt,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/scan'),
                fullWidth: false),
          ],
        ),
      );
    }

    String p = currentPrediction!.toLowerCase();
    bool isSigatoka = p.contains('sigatoka') || p == 'black sigatoka';
    bool isFusarium = p.contains('fusarium') || p == 'fusarium wilt';
    bool isHealthy = p == 'healthy';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHealthy
                  ? [
                      AppColors.success.withValues(alpha: 0.2),
                      AppColors.success.withValues(alpha: 0.1)
                    ]
                  : [
                      AppColors.danger.withValues(alpha: 0.2),
                      AppColors.danger.withValues(alpha: 0.1)
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(isHealthy ? Icons.eco : Icons.warning_amber,
                  color: isHealthy ? AppColors.success : AppColors.danger,
                  size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentPrediction!} Treatment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHealthy
                          ? (l10n?.maintainPlantHealth ?? 'Maintain your plant health')
                          : (l10n?.recommendedManagementPlan ?? 'Recommended management plan'),
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n?.recommendedActions ?? 'Recommended Actions',
            style: AppTextStyles.subtitleSemiBold),
        const SizedBox(height: 12),
        if (isSigatoka)
          ..._buildSigatokaTreatmentSteps()
        else if (isFusarium)
          ..._buildFusariumTreatmentSteps()
        else if (isHealthy)
          ..._buildHealthyMaintenanceSteps()
        else
          ..._buildGenericTreatmentSteps(),
      ],
    );
  }

  List<Widget> _buildSigatokaTreatmentSteps() {
    final l10n = AppLocalizations.of(context);
    return [
      _buildActionItem(
          icon: Icons.content_cut,
          title: 'Sanitary Pruning',
          desc:
              'Remove and destroy all infected leaves showing more than 15% damage.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.danger),
      _buildActionItem(
          icon: Icons.local_fire_department,
          title: 'Burn Infected Material',
          desc:
              'Dispose of cut leaves by burning. Do not compost infected material.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.danger),
      _buildActionItem(
          icon: Icons.science,
          title: 'Fungicide Application',
          desc:
              'Apply systemic fungicides (Propiconazole, Mancozeb) rotating products to prevent resistance.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.danger),
      _buildActionItem(
          icon: Icons.air,
          title: 'Improve Circulation',
          desc:
              'Increase plant spacing and remove weeds to allow better airflow.',
          priority: l10n?.medium ?? 'Medium',
          priorityColor: AppColors.warning),
    ];
  }

  List<Widget> _buildFusariumTreatmentSteps() {
    final l10n = AppLocalizations.of(context);
    return [
      _buildActionItem(
          icon: Icons.block,
          title: 'Quarantine Area',
          desc:
              'Immediately isolate infected plants and restrict all movement of equipment/water.',
          priority: l10n?.critical ?? 'Critical',
          priorityColor: AppColors.danger),
      _buildActionItem(
          icon: Icons.delete_forever,
          title: 'Destroy Plants',
          desc:
              'Remove and destroy infected plants in place. Do not transport material.',
          priority: l10n?.critical ?? 'Critical',
          priorityColor: AppColors.danger),
      _buildActionItem(
          icon: Icons.cleaning_services,
          title: 'Tool Disinfection',
          desc:
              'Sterilize all tools with 70% alcohol or bleach after each use.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.danger),
      _buildActionItem(
          icon: Icons.shield,
          title: 'Resistant Varieties',
          desc:
              'Plant Fusarium-resistant varieties like GCTCV-218 in future cycles.',
          priority: l10n?.critical ?? 'Critical',
          priorityColor: AppColors.danger),
    ];
  }

  List<Widget> _buildHealthyMaintenanceSteps() {
    final l10n = AppLocalizations.of(context);
    return [
      _buildActionItem(
          icon: Icons.eco,
          title: 'Balanced Nutrition',
          desc:
              'Apply NPK fertilizer and organic compost to keep plant immunity strong.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.success),
      _buildActionItem(
          icon: Icons.water_drop,
          title: 'Optimal Irrigation',
          desc: 'Maintain consistent soil moisture. Avoid waterlogging.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.success),
      _buildActionItem(
          icon: Icons.search,
          title: 'Weekly Scouting',
          desc: 'Scan leaves every week for early detection of any issues.',
          priority: l10n?.medium ?? 'Medium',
          priorityColor: AppColors.warning),
    ];
  }

  List<Widget> _buildGenericTreatmentSteps() {
    final l10n = AppLocalizations.of(context);
    return [
      _buildActionItem(
          icon: Icons.local_hospital,
          title: 'Consult Expert',
          desc:
              'Contact a local agricultural officer for an accurate professional diagnosis.',
          priority: l10n?.high ?? 'High',
          priorityColor: AppColors.warning),
      _buildActionItem(
          icon: Icons.camera_alt,
          title: 'Document Symptoms',
          desc:
              'Take clear photos of affected areas for record keeping and review.',
          priority: l10n?.medium ?? 'Medium',
          priorityColor: AppColors.warning),
    ];
  }

  Widget _buildActionItem(
      {required IconData icon,
      required String title,
      required String desc,
      required String priority,
      required Color priorityColor}) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SmallCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: AppColors.primaryDark, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(l10n?.priority(priority) ?? 'Priority: $priority',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor)),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildChatTab() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildChatMessage(msg['text'], msg['isUser']);
            },
          ),
        ),
        if (_isTyping)
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator()),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderDark))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                      hintText: l10n?.askAi ?? 'Ask AI...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.bgDark,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryDark),
                  onPressed: _handleSendMessage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: isUser ? AppColors.primaryDark : AppColors.primaryPale,
            borderRadius: BorderRadius.circular(16)),
        child: Text(text,
            style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined,
                  color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(l10n?.wasDiagnosisAccurate ?? 'Was this diagnosis accurate?',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FeedbackButton(
                  label: l10n?.yesCorrect ?? 'Yes, correct',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  isLoading: _isSendingFeedback,
                  onPressed: () => _submitFeedback(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeedbackButton(
                  label: l10n?.noWrong ?? 'No, wrong',
                  icon: Icons.cancel,
                  color: AppColors.danger,
                  isLoading: _isSendingFeedback,
                  onPressed: () => _showIncorrectFeedbackDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(bool isAccurate) async {
    final l10n = AppLocalizations.of(context);
    if (currentPredictionId == null) return;

    setState(() => _isSendingFeedback = true);

    try {
      await _offlineStorage.saveFeedback(
        predictionId: currentPredictionId!,
        isAccurate: isAccurate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.thankYouFeedback ?? 'Thank you for your feedback!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.submit ?? 'Failed to submit feedback'}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingFeedback = false);
      }
    }
  }

  void _showIncorrectFeedbackDialog() {
    final l10n = AppLocalizations.of(context);
    final TextEditingController correctController = TextEditingController();
    final TextEditingController commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.bg,
        title: Row(
          children: [
            const Icon(Icons.feedback_outlined, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(l10n?.helpUsImprove ?? 'Help us improve', style: AppTextStyles.subtitleSemiBold),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.correctDiagnosis ?? 'What is the correct diagnosis?',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: correctController,
                decoration: AppDecorations.inputDecoration(
                    'e.g., Black Sigatoka', Icons.edit),
              ),
              const SizedBox(height: 16),
              const Text('Additional comments (optional)',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: commentsController,
                maxLines: 3,
                decoration: AppDecorations.inputDecoration(
                    'Any additional details...', Icons.comment),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel',
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitFeedbackWithDetails(
                correctController.text.trim(),
                commentsController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n?.submit ?? 'Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.feedback_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              l10n?.wasDiagnosisAccurate ?? 'Was this diagnosis accurate?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _submitFeedback(true);
                      if (mounted) {
                        setState(() => _showFloatingFeedback = false);
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(l10n?.yesCorrect ?? 'Yes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      foregroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side:
                          BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showIncorrectFeedbackDialog();
                    },
                    icon: const Icon(Icons.cancel),
                    label: Text(l10n?.noWrong ?? 'No'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side:
                          BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedbackWithDetails(
      String correctDiagnosis, String comments) async {
    final l10n = AppLocalizations.of(context);
    if (currentPredictionId == null) return;

    setState(() => _isSendingFeedback = true);

    try {
      await _offlineStorage.saveFeedback(
        predictionId: currentPredictionId!,
        isAccurate: false,
        correctDiagnosis: correctDiagnosis.isNotEmpty ? correctDiagnosis : null,
        comments: comments.isNotEmpty ? comments : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.thankYouFeedback ?? 'Thank you for your feedback!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.submit ?? 'Failed to submit feedback'}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingFeedback = false);
      }
    }
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
    );
  }
}
