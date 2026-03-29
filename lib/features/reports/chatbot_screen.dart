import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/gemini_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _scrollController = ScrollController();
  
  final List<String> _suggestions = [
    "📈 Analisis performa toko",
    "💡 Saran promo stok lambat",
    "📦 Ide bundling terpopuler",
    "🤝 Cara tarik member baru",
    "⏰ Optimasi jam sibuk",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryStartChat();
    });
  }

  void _tryStartChat() {
    final gemini = context.read<GeminiProvider>();
    final dashboard = context.read<DashboardProvider>();

    if (!gemini.isInitialized) {
      // Not ready yet — listen and retry once initialized
      late VoidCallback listener;
      listener = () {
        if (gemini.isInitialized) {
          gemini.removeListener(listener);
          if (mounted && gemini.messages.isEmpty && gemini.apiKey != null) {
            gemini.startChat(dashboard);
          }
        }
      };
      gemini.addListener(listener);
      return;
    }

    // Already initialized — start immediately if messages are empty
    if (!gemini.isLoading && gemini.messages.isEmpty && gemini.apiKey != null) {
      gemini.startChat(dashboard);
    }
  }


  @override
  void dispose() {
    _messageController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.isNotEmpty) {
      _sendMessageWithText(text);
      _messageController.clear();
    }
  }

  void _sendMessageWithText(String text) {
    if (text.isNotEmpty) {
      context.read<GeminiProvider>().sendMessage(text);
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _saveApiKey() {
    final text = _apiKeyController.text;
    if (text.isNotEmpty) {
      context.read<GeminiProvider>().saveApiKey(text);
      final dashboard = context.read<DashboardProvider>();
      context.read<GeminiProvider>().startChat(dashboard);
    }
  }

  void _showApiKeySettings() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Pengaturan API Key', style: TextStyle(fontWeight: FontWeight.w900)),
        description: const Text('Apakah Anda ingin menghapus API Key Gemini yang tersimpan saat ini?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ShadButton.destructive(
            onPressed: () {
              context.read<GeminiProvider>().clearApiKey();
              Navigator.pop(context);
            },
            child: const Text('Hapus Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gemini = context.watch<GeminiProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            badgeLabel: "AI ASSISTANT",
            title: "Praktisi Bisnis AI",
            actions: [
              if (gemini.apiKey != null)
                ShadButton.ghost(
                  onPressed: _showApiKeySettings,
                  child: const Icon(Icons.settings_outlined, size: 22),
                ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: gemini.apiKey == null 
              ? _buildApiKeySetup() 
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH),
                  child: _buildChatInterface(gemini),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySetup() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.screenPaddingH),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 80, color: AppTheme.accentColor).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
              const SizedBox(height: 32),
              const Text(
                'Asisten Bisnis AI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              Text(
                'Konsultasikan strategi bisnis Anda secara privat dengan kecerdasan buatan Gemini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), height: 1.5),
              ),
              const SizedBox(height: 48),
              ShadInput(
                controller: _apiKeyController,
                obscureText: true,
                placeholder: const Text('Masukkan Gemini API Key...'),
                leading: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.key_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: _saveApiKey,
                width: double.infinity,
                size: ShadButtonSize.lg,
                child: const Text('MULAI PERCAKAPAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
        ),
      ),
    );
  }

  Widget _buildChatInterface(GeminiProvider gemini) {
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!gemini.isLoading) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        // Chat Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: gemini.messages.length,
            itemBuilder: (context, index) {
              final message = gemini.messages[index];
              final isUser = message.isUser;
              
              // Skip the initial hidden prompt payload from being displayed in full UI, 
              // except here we structured it differently so the first message in UI is the bot greeting.
              if (index == 0 && !message.isUser && message.text.contains("Total Transaksi")) {
                 return const SizedBox.shrink(); // Hide the hidden system prompt if it ever leaks in
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  key: ValueKey(index),
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    radius: 20,
                    color: isUser ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
                    border: isUser ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                          fontSize: 14,
                          fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
            },
          ),
        ),
        
        if (gemini.isLoading)
           Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                 const SizedBox(width: 12),
                 Text('Berpikir...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
               ],
             ),
           ),

        // Suggestions Area
        if (!gemini.isLoading)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ShadButton.outline(
                    onPressed: () => _sendMessageWithText(_suggestions[index]),
                    size: ShadButtonSize.sm,
                    child: Text(
                      _suggestions[index],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 400.ms),

        // Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24).copyWith(
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: ShadInput(
                      controller: _messageController,
                      decoration: ShadDecoration(border: ShadBorder.none),
                      placeholder: Text('Tanyakan saran promosi atau bundle...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ShadButton(
                onPressed: gemini.isLoading ? null : _sendMessage,
                height: 54,
                width: 54,
                padding: EdgeInsets.zero,
                child: const Icon(Icons.send_rounded, size: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
