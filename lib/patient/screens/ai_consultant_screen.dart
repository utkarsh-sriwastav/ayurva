import 'package:flutter/material.dart';

import '../data/patient_repository.dart';
import '../models/consultation_message.dart';
import '../models/consultation_summary.dart';
import 'summary_screen.dart';

/// Pre-consultation chat for one token. The patient can type, use the
/// keyboard microphone, or tap options. After the first message they
/// can generate the one-page report.
class AiConsultantScreen extends StatefulWidget {
  /// The token this consultation belongs to (created earlier by
  /// Token Booking; the consultant never creates a token).
  final String tokenId;
  final String patientName;

  const AiConsultantScreen({
    super.key,
    required this.tokenId,
    this.patientName = 'Patient',
  });

  @override
  State<AiConsultantScreen> createState() => _AiConsultantScreenState();
}

class _AiConsultantScreenState extends State<AiConsultantScreen> {
  // Prototype: real file picking will be connected later.
  static const List<String> _sampleReports = [
    'blood_test.pdf',
    'xray_report.pdf',
    'prescription.jpg',
  ];

  // Touch options: tap to add a symptom to the message box.
  static const List<String> _symptomChips = [
    'Fever',
    'Cough',
    'Cold',
    'Headache',
    'Stomach pain',
    'Vomiting',
    'Body pain',
    'Skin problem',
    'Eye problem',
    'Tooth pain',
    'Chest pain',
  ];

  // Touch options: tap to answer quickly (sent immediately).
  static const List<String> _quickReplies = [
    'Since yesterday',
    '2-3 days',
    'More than a week',
    'Mild',
    'Moderate',
    'Severe',
  ];

  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  List<ConsultationMessage> _messages = [];
  bool _isLoadingHistory = true;
  bool _isAiTyping = false;
  bool _isGeneratingSummary = false;
  ConsultationSummary? _summary;

  bool get _canSend => _inputController.text.trim().isNotEmpty && !_isAiTyping;

  /// How many messages the patient typed (attachments not counted).
  int get _typedCount => _messages
      .where((m) =>
          m.sender == MessageSender.patient && m.attachmentName == null)
      .length;

  /// The report can be generated once the patient has said anything.
  bool get _hasPatientMessage =>
      _messages.any((m) => m.sender == MessageSender.patient);

  List<String> get _attachedReports => _messages
      .where((m) => m.attachmentName != null)
      .map((m) => m.attachmentName!)
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = PatientRepository.instance;
      final messages = await repo.getConsultationMessages(widget.tokenId);
      final summary = await repo.getConsultationSummary(widget.tokenId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _summary = summary;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
      _showMessage('Could not load the conversation: $e');
    }
  }

  void _addMessage(ConsultationMessage message, {bool aiIsTyping = false}) {
    setState(() {
      _messages = [..._messages, message];
      _isAiTyping = aiIsTyping;
    });
    _scrollToBottom();
  }

  /// Sends one patient message and shows the AI reply.
  Future<void> _sendText(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isAiTyping) return;

    _addMessage(
      ConsultationMessage(
        sender: MessageSender.patient,
        text: text,
        timestamp: DateTime.now(),
      ),
      aiIsTyping: true,
    );

    try {
      final reply = await PatientRepository.instance.sendConsultationMessage(
        tokenId: widget.tokenId,
        text: text,
      );
      if (!mounted) return;
      _addMessage(ConsultationMessage(
        sender: MessageSender.ai,
        text: reply,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAiTyping = false);
      _showMessage('Could not get a reply: $e');
    }
  }

  void _handleSend() {
    final text = _inputController.text;
    _inputController.clear();
    _sendText(text);
  }

  /// Adds a tapped symptom to the message box (patient can tap several).
  void _appendToInput(String label) {
    final current = _inputController.text.trim();
    final next = current.isEmpty ? label : '$current, $label';
    setState(() {
      _inputController.text = next;
      _inputController.selection = TextSelection.collapsed(offset: next.length);
    });
  }

  Future<void> _handleAttach() async {
    if (_isAiTyping) return;

    final fileName = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Upload Medical Report (optional, prototype)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'A report is not required. File picking will be connected later. Choose a sample report:',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            for (final name in _sampleReports)
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(name),
                onTap: () => Navigator.pop(sheetContext, name),
              ),
          ],
        ),
      ),
    );

    if (fileName == null || !mounted) return;

    _addMessage(
      ConsultationMessage(
        sender: MessageSender.patient,
        text: 'Attached report: $fileName',
        timestamp: DateTime.now(),
        attachmentName: fileName,
      ),
      aiIsTyping: true,
    );

    try {
      final reply = await PatientRepository.instance.attachReport(
        tokenId: widget.tokenId,
        fileName: fileName,
      );
      if (!mounted) return;
      _addMessage(ConsultationMessage(
        sender: MessageSender.ai,
        text: reply,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAiTyping = false);
      _showMessage('Could not attach the report: $e');
    }
  }

  /// Voice: uses the microphone of the phone keyboard (speech-to-text
  /// built into Android). No extra package is needed.
  void _handleVoice() {
    _focusNode.requestFocus();
    _showMessage(
      'Tap the microphone on your keyboard and speak. Your words will '
      'appear in the box. Then press send.',
    );
  }

  Future<void> _handleGenerateSummary() async {
    setState(() => _isGeneratingSummary = true);

    try {
      final repo = PatientRepository.instance;

      // 1. The AI builds the one-page report from the conversation.
      final summary = await repo.generateConsultationSummary(
        tokenId: widget.tokenId,
        patientName: widget.patientName,
      );

      // 2. It is saved under the token ID, so the Doctor side can read
      //    this very same report later.
      await repo.saveConsultationSummary(widget.tokenId, summary);

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isGeneratingSummary = false;
      });
      _openSummary();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingSummary = false);
      _showMessage('Could not generate the summary: $e');
    }
  }

  void _openSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(tokenId: widget.tokenId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Consultant')),
      body: SafeArea(
        child: Column(
          children: [
            _buildInfoBanner(),
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessageList(),
            ),
            _buildSummaryBar(),
            _buildChips(),
            _buildAttachedReports(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'Pre-consultation assistant. It prepares a report for the doctor. '
        'It cannot diagnose or prescribe medicines. '
        'In an emergency, call 112.',
        style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12.5),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingBubble();
        return _buildBubble(_messages[index]);
      },
    );
  }

  Widget _buildBubble(ConsultationMessage message) {
    final isPatient = message.sender == MessageSender.patient;
    final scheme = Theme.of(context).colorScheme;
    final textColor = isPatient ? Colors.white : Colors.black87;

    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isPatient ? scheme.primary : Colors.white,
          border: isPatient ? null : Border.all(color: Colors.black12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isPatient ? 16 : 4),
            bottomRight: Radius.circular(isPatient ? 4 : 16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachmentName != null)
              Padding(
                padding: const EdgeInsets.only(right: 6, top: 2),
                child: Icon(Icons.attach_file, size: 16, color: textColor),
              ),
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(color: textColor, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('AI is typing...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  /// Generate Summary right after the first message,
  /// then View Summary once the report exists.
  Widget _buildSummaryBar() {
    final busy = _isGeneratingSummary || _isAiTyping;
    const spinner = SizedBox(
      height: 16,
      width: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    if (_summary != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _openSummary,
                icon: const Icon(Icons.article_outlined),
                label: const Text('View Summary'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: busy ? null : _handleGenerateSummary,
              child: _isGeneratingSummary ? spinner : const Text('Update'),
            ),
          ],
        ),
      );
    }

    if (_hasPatientMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : _handleGenerateSummary,
            icon: _isGeneratingSummary
                ? spinner
                : const Icon(Icons.auto_awesome_outlined),
            label: const Text('Generate Summary'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Touch options above the message box.
  Widget _buildChips() {
    final showSymptoms = _typedCount == 0;
    final showReplies = _typedCount >= 1 && _typedCount <= 3;
    if (!showSymptoms && !showReplies) return const SizedBox.shrink();

    final labels = showSymptoms ? _symptomChips : _quickReplies;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = labels[index];
          return ActionChip(
            label: Text(label),
            onPressed: _isAiTyping
                ? null
                : () {
                    if (showSymptoms) {
                      _appendToInput(label);
                    } else {
                      _sendText(label);
                    }
                  },
          );
        },
      ),
    );
  }

  Widget _buildAttachedReports() {
    final reports = _attachedReports;
    if (reports.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final name in reports)
            Chip(
              avatar: const Icon(Icons.description_outlined, size: 16),
              label: Text(name),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Upload Medical Report',
            icon: const Icon(Icons.attach_file),
            onPressed: _isAiTyping ? null : _handleAttach,
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type or speak your symptoms...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Speak',
            icon: const Icon(Icons.mic_none),
            onPressed: _handleVoice,
          ),
          CircleAvatar(
            backgroundColor: _canSend ? primary : Colors.black26,
            child: IconButton(
              tooltip: 'Send',
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _canSend ? _handleSend : null,
            ),
          ),
        ],
      ),
    );
  }
}