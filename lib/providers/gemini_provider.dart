import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class GeminiProvider with ChangeNotifier {
  String? _apiKey;
  GenerativeModel? _model;
  String? _systemContext; // system instruction injected as first user turn

  final List<ChatMessage> _messages = [];
  // Maintain raw content history for generateContentStream
  final List<Content> _history = [];
  bool _isLoading = false;
  bool _initialized = false;

  String? get apiKey => _apiKey;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;

  GeminiProvider() {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _initModel();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    _apiKey = key.trim();
    _initModel();
    _initialized = true;
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    _apiKey = null;
    _model = null;
    _messages.clear();
    _history.clear();
    _systemContext = null;
    notifyListeners();
  }

  void _initModel() {
    if (_apiKey == null) return;
    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey!,
    );
  }

  void startChat(DashboardProvider dashboard) {
    if (_model == null && _apiKey != null) _initModel();
    if (_model == null) return;

    _messages.clear();
    _history.clear();

    _systemContext = '''
Anda adalah Konsultan Ritel dan Kepemimpinan Bisnis UMKM yang ahli. Anda sedang berbicara dengan pemilik warung/toko kelontong.
Gunakan bahasa Indonesia yang ramah, profesional, praktis, dan memotivasi. JANGAN gunakan bahasa robot.
Berikan saran yang bisa langsung dipraktikkan (actionable), bukan teori manajemen yang rumit.

Data terkini dari warung pengguna (WAJIB dijadikan acuan dalam saran):
- Total Transaksi: ${dashboard.totalTransactions}
- Total Penjualan: Rp ${dashboard.totalSales.toInt()}
- Estimasi Margin Keuntungan: ${dashboard.profitMarginPercentage.toStringAsFixed(1)}%
- Produk Terlaris: ${dashboard.topSellingProduct}
- Kategori Terlaris: ${dashboard.topCategory}
- Produk Paling Lambat Laku: ${dashboard.slowestMovingProduct}
- Kombinasi Bundling Disarankan: ${dashboard.suggestedBundle}
- Hari Tersibuk: ${dashboard.peakDayOfWeek}
- Jam Tersibuk: ${dashboard.busiestHour}
- Persentase Transaksi Member: ${dashboard.memberTransactionPercentage.toStringAsFixed(0)}%
''';

    const greeting = "Halo! Saya adalah Asisten AI Bisnis Anda. Berdasarkan data warung Anda saat ini, ada yang bisa saya bantu diskusikan? Misalnya merencanakan promo diskon, strategi bundling produk, atau optimalisasi jam operasional?";

    _messages.add(ChatMessage(text: greeting, isUser: false));
    // Seed history so first real exchange has context
    _history.add(Content.text(_systemContext!));
    _history.add(Content.model([TextPart(greeting)]));

    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_model == null || text.trim().isEmpty) return;

    final userMessage = text.trim();
    _messages.add(ChatMessage(text: userMessage, isUser: true));
    _history.add(Content.text(userMessage));
    _isLoading = true;
    notifyListeners();

    try {
      final responseStream = _model!.generateContentStream(_history);
      final botMessageIndex = _messages.length;
      _messages.add(ChatMessage(text: "", isUser: false));

      final buffer = StringBuffer();
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          buffer.write(chunk.text!);
          _messages[botMessageIndex] = ChatMessage(text: buffer.toString(), isUser: false);
          _isLoading = false;
          notifyListeners();
        }
      }

      final finalText = buffer.toString();
      if (finalText.isEmpty) {
        _messages[botMessageIndex] = ChatMessage(text: "Maaf, saya tidak dapat memproses permintaan tersebut.", isUser: false);
      }
      // Append AI response to history for next turn context
      _history.add(Content.model([TextPart(finalText.isEmpty ? "Maaf, saya tidak dapat memproses permintaan tersebut." : finalText)]));
    } catch (e) {
      final errorMsg = "Terjadi kesalahan. Detail: $e";
      if (_messages.last.isUser) {
        _messages.add(ChatMessage(text: errorMsg, isUser: false));
      } else {
        _messages[_messages.length - 1] = ChatMessage(text: errorMsg, isUser: false);
      }
      // Remove the last user content from history since we failed
      if (_history.isNotEmpty) _history.removeLast();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
