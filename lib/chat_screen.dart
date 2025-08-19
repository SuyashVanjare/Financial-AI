import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart'; // For adding charts
import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isTyping = false;
  final bool _showEmojis = false;
  final int _selectedTab = 0;
  late TabController _tabController;
  
  // Animation controllers
  late AnimationController _typingController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _tabController = TabController(length: 4, vsync: this);
    
    // Add post frame callback to scroll to bottom initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _fadeController.dispose();
    _tabController.dispose();
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
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() => _isTyping = true);
      Provider.of<ChatService>(context, listen: false).sendMessage(message);
      _messageController.clear();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isTyping = false);
        }
      });
      
      _focusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  String _getTimeString() {
    return DateFormat('h:mm a').format(DateTime.now());
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final position = (_typingController.value - delay) % 1.0;
              final opacity = position < 0 ? 0.0 : position;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400.withOpacity(0.3 + opacity * 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      }
    );
  }

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              // Tab bar
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF4260F5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: const [
                    Tab(text: "Market"),
                    Tab(text: "Stocks"),
                    Tab(text: "Crypto"),
                    Tab(text: "Learn"),
                  ],
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Market tab
                    ListView(
                      children: [
                        _buildCategoryHeader("Market Overview"),
                        _buildSuggestionItem(
                          "Market Status",
                          "How is the market performing today?",
                          Icons.show_chart,
                        ),
                        _buildSuggestionItem(
                          "Market Sentiment",
                          "What's the current market sentiment?",
                          Icons.psychology,
                        ),
                        _buildSuggestionItem(
                          "Sector Performance",
                          "Which sectors are outperforming today?",
                          Icons.category,
                        ),
                        
                        _buildCategoryHeader("Market Analysis"),
                        _buildSuggestionItem(
                          "Market Forecast",
                          "Predict market trends for next week",
                          Icons.trending_up,
                        ),
                        _buildSuggestionItem(
                          "Economic Indicators",
                          "How are current economic indicators affecting the market?",
                          Icons.bar_chart,
                        ),
                      ],
                    ),
                    
                    // Stocks tab
                    ListView(
                      children: [
                        _buildCategoryHeader("Popular Stocks"),
                        _buildSuggestionItem(
                          "Apple",
                          "Show me AAPL stock data",
                          Icons.smartphone,
                        ),
                        _buildSuggestionItem(
                          "Tesla",
                          "Show me TSLA stock analysis",
                          Icons.electric_car,
                        ),
                        _buildSuggestionItem(
                          "Amazon",
                          "Predict AMZN stock movement",
                          Icons.shopping_cart,
                        ),
                        
                        _buildCategoryHeader("Stock Analysis"),
                        _buildSuggestionItem(
                          "Stock Comparison",
                          "Compare AAPL and MSFT stocks",
                          Icons.compare_arrows,
                        ),
                        _buildSuggestionItem(
                          "Stock Screening",
                          "Find undervalued tech stocks",
                          Icons.search,
                        ),
                      ],
                    ),
                    
                    // Crypto tab
                    ListView(
                      children: [
                        _buildCategoryHeader("Popular Cryptocurrencies"),
                        _buildSuggestionItem(
                          "Bitcoin",
                          "Show me Bitcoin price",
                          Icons.currency_bitcoin,
                        ),
                        _buildSuggestionItem(
                          "Ethereum",
                          "Show me ETH analysis",
                          Icons.auto_awesome,
                        ),
                        _buildSuggestionItem(
                          "Solana",
                          "Predict SOL price movement",
                          Icons.bolt,
                        ),
                        
                        _buildCategoryHeader("Crypto Analysis"),
                        _buildSuggestionItem(
                          "Crypto Market",
                          "How is the crypto market today?",
                          Icons.devices_other,
                        ),
                        _buildSuggestionItem(
                          "Crypto Trends",
                          "What are the emerging trends in cryptocurrency?",
                          Icons.trending_up,
                        ),
                      ],
                    ),
                    
                    // Learn tab
                    ListView(
                      children: [
                        _buildCategoryHeader("Investment Basics"),
                        _buildSuggestionItem(
                          "Investment Types",
                          "Explain different types of investments",
                          Icons.menu_book,
                        ),
                        _buildSuggestionItem(
                          "Risk Management",
                          "How to manage investment risk?",
                          Icons.shield,
                        ),
                        
                        _buildCategoryHeader("Advanced Topics"),
                        _buildSuggestionItem(
                          "Options Trading",
                          "Explain options trading strategies",
                          Icons.insights,
                        ),
                        _buildSuggestionItem(
                          "Technical Analysis",
                          "Teach me about technical analysis indicators",
                          Icons.analytics,
                        ),
                        _buildSuggestionItem(
                          "DeFi",
                          "Explain decentralized finance (DeFi)",
                          Icons.account_balance,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildSuggestionItem(String title, String question, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          _messageController.text = question;
          _sendMessage();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4260F5).withAlpha(50),
                child: Icon(icon, color: const Color(0xFF4260F5), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      question,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF4260F5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeController,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4260F5),
                      const Color(0xFF4260F5).withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4260F5).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const Text(
                "Financial Market AI",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Your AI assistant for smarter investing, market insights, and financial education",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Featured suggestion buttons with attractive design
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Start with a question:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureSuggestion(
                      "How is the market performing today?",
                      Icons.trending_up,
                      [Color(0xFF4260F5), Color(0xFF2C3E8A)],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureSuggestion(
                      "Show me Apple stock analysis",
                      Icons.analytics,
                      [Color(0xFF26A69A), Color(0xFF1B5E56)],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureSuggestion(
                      "What's Bitcoin's price prediction?",
                      Icons.currency_bitcoin,
                      [Color(0xFFF57C00), Color(0xFF8F4700)],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureSuggestion(
                      "Explain investment portfolio diversification",
                      Icons.school,
                      [Color(0xFF7E57C2), Color(0xFF4527A0)],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Show a sample chart to make the empty state more engaging
              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Market Overview",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 3),
                                FlSpot(1, 1),
                                FlSpot(2, 4),
                                FlSpot(3, 2),
                                FlSpot(4, 5),
                                FlSpot(5, 4.5),
                                FlSpot(6, 6),
                              ],
                              isCurved: true,
                              color: const Color(0xFF4260F5),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF4260F5).withOpacity(0.2),
                              ),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    )
                  ],  
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSuggestion(String text, IconData icon, List<Color> gradientColors) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser, String time, bool showTime) {
    // Extract image URLs from message to display them separately
    final String text = _sanitizeText(message['text']);
    
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: 6,
            bottom: 2,
            right: isUser ? 0 : 48,
            left: isUser ? 48 : 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF4260F5).withAlpha(50),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF4260F5), size: 18),
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4260F5), Color(0xFF3150E0)],
                        )
                      : null,
                    color: isUser ? null : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 16 : 4),
                      topRight: Radius.circular(isUser ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser 
                          ? const Color(0xFF4260F5).withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2A2A2A),
                    child: Icon(Icons.person, color: Colors.grey.shade400, size: 18),
                  ),
                ),
            ],
          ),
        ),
        if (showTime)
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 8,
              left: 40,
              right: 40,
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  // Navigation drawer
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4260F5), Color(0xFF3150E0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Financial Market AI",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Intelligent Financial Assistant",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Color(0xFF2A2A2A)),
            
            // Navigation items
            _buildDrawerItem(
              "Chat Assistant",
              Icons.chat_bubble_outline,
              0,
              isActive: true,
            ),
            _buildDrawerItem(
              "Portfolio Tracker",
              Icons.account_balance_wallet_outlined,
              1,
            ),
            _buildDrawerItem(
              "Market Overview",
              Icons.trending_up,
              2,
            ),
            _buildDrawerItem(
              "Predictions & Alerts",
              Icons.notifications_none,
              3,
            ),
            _buildDrawerItem(
              "News & Verification",
              Icons.article_outlined,
              4,
            ),
            _buildDrawerItem(
              "Learning Center",
              Icons.school_outlined,
              5,
            ),
            
            const Divider(color: Color(0xFF2A2A2A)),
            
            // Settings and support
            _buildDrawerItem(
              "Settings",
              Icons.settings_outlined,
              6,
            ),
            _buildDrawerItem(
              "Help & Support",
              Icons.help_outline,
              7,
            ),
            
            const Spacer(),
            
            // Bottom section
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Guest User",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Set up your profile",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.login,
                        color: Color(0xFF4260F5),
                        size: 16,
                      ),
                      onPressed: () {
                        // Login action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Login feature coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(String title, IconData icon, int index, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4260F5).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF4260F5) : Colors.grey.shade400,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade400,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: () {
          // Handle navigation
          Navigator.pop(context);
          if (index > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title feature coming soon!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        trailing: isActive
          ? Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4260F5),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          : null,
        dense: true,
        visualDensity: const VisualDensity(vertical: -0.5),
      ),
    );
  }
  
  // Method to remove asterisks from text and process Markdown-like formatting
  // Method to remove asterisks from text and process Markdown-like formatting
  String _sanitizeText(String text) {
    // Replace markdown formatting while preserving emphasis
    // This is a simple implementation
    String processed = text;
    
    // Replace sequences of asterisks (fixed by escaping the $ properly)
    processed = processed.replaceAll(RegExp(r'\*\*\*(.*?)\*\*\*'), r'\1');
    processed = processed.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1');
    processed = processed.replaceAll(RegExp(r'\*(.*?)\*'), r'\1');
    
    return processed;
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
    // Dark theme colors
    final primaryColor = const Color(0xFF4260F5);
    final secondaryColor = const Color(0xFF2A2A2A);
    final backgroundColor = const Color(0xFF121212);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Financial Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Online',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show more options
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Actions
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text(
                          "Clear Conversation",
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: const Text(
                                "Clear Conversation",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "Are you sure you want to clear this conversation? This action cannot be undone.",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: const Text(
                                    "Clear",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    chatService.clearMessages();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_outlined, color: Colors.white),
                        title: const Text(
                          "Share Insights",
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined, color: Colors.white),
                        title: const Text(
                          "Settings",
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.help_outline, color: Colors.white),
                        title: const Text(
                          "Help & Feedback",
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Help & Feedback feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Chat messages
          Expanded(
            child: chatService.messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                  itemCount: chatService.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatService.messages[index];
                    final isUser = message['isUser'];
                    final showTime = index == 0 || 
                                  index == chatService.messages.length - 1 || 
                                  chatService.messages[index-1]['isUser'] != isUser;
                    
                    return _buildMessageBubble(
                      message,
                      isUser,
                      message['time'] ?? _getTimeString(),
                      showTime,
                    );
                  },
                ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.only(left: 64, bottom: 8),
              alignment: Alignment.centerLeft,
              child: _buildTypingIndicator(),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: primaryColor,
                      size: 20,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice input coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Ask about stocks, funds, market trends...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onTap: _scrollToBottom,
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: primaryColor.withAlpha(200),
                              size: 18,
                            ),
                          ),
                          onPressed: _showSuggestions,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4260F5), Color(0xFF3150E0)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4260F5).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: chatService.isLoading
        ? Container(
            margin: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF2A2A2A),
              mini: true,
              onPressed: () {
                // Cancel request not implemented yet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cancel request feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          )
        : null,
    );
  }
}