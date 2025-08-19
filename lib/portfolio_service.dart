import 'package:flutter/material.dart';
import 'dart:math';

class PortfolioService extends ChangeNotifier {
  // Sample portfolio data
  List<PortfolioAsset> _assets = [];
  PortfolioSummary? _summary;
  
  // Getters
  List<PortfolioAsset> get assets => _assets;
  PortfolioSummary? get summary => _summary;
  
  // Initialize portfolio with sample data
  void loadPortfolio() {
    // Create sample assets
    _assets = [
      PortfolioAsset(
        id: 'asset_1',
        symbol: 'AAPL',
        name: 'Apple Inc.',
        type: 'stock',
        quantity: 10,
        purchasePrice: 175.60,
        currentPrice: 186.30,
        totalValue: 1863.00,
        profitLoss: 107.00,
        profitLossPercentage: 6.09,
        purchaseDate: DateTime.now().subtract(const Duration(days: 60)),
      ),
      PortfolioAsset(
        id: 'asset_2',
        symbol: 'MSFT',
        name: 'Microsoft Corporation',
        type: 'stock',
        quantity: 5,
        purchasePrice: 315.20,
        currentPrice: 350.50,
        totalValue: 1752.50,
        profitLoss: 176.50,
        profitLossPercentage: 11.20,
        purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      PortfolioAsset(
        id: 'asset_3',
        symbol: 'BTC',
        name: 'Bitcoin',
        type: 'crypto',
        quantity: 0.5,
        purchasePrice: 58000.00,
        currentPrice: 63421.05,
        totalValue: 31710.53,
        profitLoss: 2710.53,
        profitLossPercentage: 9.35,
        purchaseDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      PortfolioAsset(
        id: 'asset_4',
        symbol: 'AMZN',
        name: 'Amazon.com Inc.',
        type: 'stock',
        quantity: 3,
        purchasePrice: 145.50,
        currentPrice: 142.80,
        totalValue: 428.40,
        profitLoss: -8.10,
        profitLossPercentage: -1.85,
        purchaseDate: DateTime.now().subtract(const Duration(days: 45)),
      ),
      PortfolioAsset(
        id: 'asset_5',
        symbol: 'ETH',
        name: 'Ethereum',
        type: 'crypto',
        quantity: 2,
        purchasePrice: 1850.00,
        currentPrice: 3200.75,
        totalValue: 6401.50,
        profitLoss: 2701.50,
        profitLossPercentage: 73.01,
        purchaseDate: DateTime.now().subtract(const Duration(days: 180)),
      ),
      PortfolioAsset(
        id: 'asset_6',
        symbol: 'TSLA',
        name: 'Tesla Inc.',
        type: 'stock',
        quantity: 4,
        purchasePrice: 222.50,
        currentPrice: 237.30,
        totalValue: 949.20,
        profitLoss: 59.20,
        profitLossPercentage: 6.65,
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
    
    // Calculate portfolio summary
    _calculateSummary();
    
    notifyListeners();
  }
  
  // Add a new asset to the portfolio
  void addAsset(PortfolioAsset asset) {
    _assets.add(asset);
    _calculateSummary();
    notifyListeners();
  }
  
  // Remove an asset from the portfolio
  void removeAsset(String assetId) {
    _assets.removeWhere((asset) => asset.id == assetId);
    _calculateSummary();
    notifyListeners();
  }
  
  // Update an existing asset
  void updateAsset(PortfolioAsset updatedAsset) {
    final index = _assets.indexWhere((asset) => asset.id == updatedAsset.id);
    if (index != -1) {
      _assets[index] = updatedAsset;
      _calculateSummary();
      notifyListeners();
    }
  }
  
  // Refresh portfolio data (simulate API call)
  void refreshPortfolio() {
    // In a real app, you would fetch updated prices from an API
    // For now, we'll just add some random variations to the current prices
    final random = Random();
    
    for (var i = 0; i < _assets.length; i++) {
      final asset = _assets[i];
      final variation = (random.nextDouble() * 0.04) - 0.02; // -2% to +2%
      final newPrice = asset.currentPrice! * (1 + variation);
      
      _assets[i] = PortfolioAsset(
        id: asset.id,
        symbol: asset.symbol,
        name: asset.name,
        type: asset.type,
        quantity: asset.quantity,
        purchasePrice: asset.purchasePrice,
        currentPrice: newPrice,
        totalValue: newPrice * asset.quantity,
        profitLoss: (newPrice - asset.purchasePrice) * asset.quantity,
        profitLossPercentage: ((newPrice / asset.purchasePrice) - 1) * 100,
        purchaseDate: asset.purchaseDate,
      );
    }
    
    _calculateSummary();
    notifyListeners();
  }
  
  // Calculate portfolio summary statistics
  void _calculateSummary() {
    if (_assets.isEmpty) {
      _summary = null;
      return;
    }
    
    double totalValue = 0;
    double totalInvestment = 0;
    double totalProfitLoss = 0;
    
    // Asset allocation
    Map<String, double> assetAllocation = {};
    Map<String, double> sectorAllocation = {};
    
    for (var asset in _assets) {
      totalValue += asset.totalValue ?? 0;
      totalInvestment += asset.purchasePrice * asset.quantity;
      totalProfitLoss += asset.profitLoss ?? 0;
      
      // Update asset allocation
      final assetType = asset.type;
      assetAllocation[assetType] = (assetAllocation[assetType] ?? 0) + (asset.totalValue ?? 0);
      
      // Update sector allocation (in a real app, you would have sector information)
      String sector;
      if (asset.type == 'crypto') {
        sector = 'Cryptocurrency';
      } else if (['AAPL', 'MSFT', 'GOOGL'].contains(asset.symbol)) {
        sector = 'Technology';
      } else if (['JPM', 'BAC', 'GS'].contains(asset.symbol)) {
        sector = 'Finance';
      } else if (['JNJ', 'PFE', 'UNH'].contains(asset.symbol)) {
        sector = 'Healthcare';
      } else if (['AMZN', 'TSLA'].contains(asset.symbol)) {
        sector = 'Consumer';
      } else if (['XOM', 'CVX'].contains(asset.symbol)) {
        sector = 'Energy';
      } else {
        sector = 'Other';
      }
      
      sectorAllocation[sector] = (sectorAllocation[sector] ?? 0) + (asset.totalValue ?? 0);
    }
    
    // Convert to percentages
    for (var key in assetAllocation.keys) {
      assetAllocation[key] = (assetAllocation[key]! / totalValue) * 100;
    }
    
    for (var key in sectorAllocation.keys) {
      sectorAllocation[key] = (sectorAllocation[key]! / totalValue) * 100;
    }
    
    // Calculate risk score (simple naive approach)
    double riskScore = 0;
    if (assetAllocation['crypto'] != null) {
      riskScore += assetAllocation['crypto']! * 0.08; // Crypto is high risk
    }
    
    if (sectorAllocation['Technology'] != null) {
      riskScore += sectorAllocation['Technology']! * 0.06; // Tech is moderate-high risk
    }
    
    if (sectorAllocation['Finance'] != null) {
      riskScore += sectorAllocation['Finance']! * 0.05; // Finance is moderate risk
    }
    
    // Add a baseline risk
    riskScore += 2;
    
    // Cap at 10
    riskScore = min(10, riskScore);
    
    _summary = PortfolioSummary(
      totalValue: totalValue,
      totalInvestment: totalInvestment,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercentage: totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0,
      assetAllocation: assetAllocation,
      sectorAllocation: sectorAllocation,
      riskScore: riskScore,
    );
  }
  
  // Get rebalancing recommendations
  Future<String> getRebalancingRecommendations() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (_summary == null) {
      return 'No portfolio data available for analysis.';
    }
    
    final recommendations = '''Based on your current portfolio allocation, here are some rebalancing recommendations:

1. Your portfolio is ${_summary!.assetAllocation['crypto']?.toStringAsFixed(1) ?? '0'}% in cryptocurrencies, which is ${(_summary!.assetAllocation['crypto'] ?? 0) > 20 ? 'higher than the recommended 5-15%' : 'within a reasonable range'}.

2. Your exposure to the Technology sector is ${_summary!.sectorAllocation['Technology']?.toStringAsFixed(1) ?? '0'}%. Consider ${(_summary!.sectorAllocation['Technology'] ?? 0) > 30 ? 'reducing this to 20-30% for better diversification' : 'maintaining this balanced exposure'}.

3. You currently have limited exposure to defensive sectors. Consider adding some dividend-paying stocks or ETFs to improve portfolio stability.

4. Your cash reserves appear to be low. Consider maintaining 5-10% of your portfolio in cash equivalents for opportunities and emergencies.

5. Based on market conditions, gradual entry into value stocks might be beneficial to balance your current growth-focused holdings.''';
    
    return recommendations;
  }
  
  // Get investment opportunities
  Future<String> getInvestmentOpportunities() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    final opportunities = '''Here are some potential investment opportunities that might complement your portfolio:

🔹 **Value Investing Opportunities**
  • Financial sector ETFs are currently trading at attractive valuations
  • Consumer staples could provide defensive positioning in current market conditions

🔹 **Growth Potential**
  • AI and semiconductor companies show strong long-term growth prospects
  • Clean energy sector presents growth opportunities with increasing global focus

🔹 **Diversification Options**
  • Consider REITs for income and real estate exposure
  • International market ETFs could help balance US market exposure

🔹 **Risk Management**
  • Treasury ETFs could help balance your higher-risk equity and crypto holdings
  • Gold or commodity ETFs as inflation hedges

These suggestions are based on your current holdings and general market analysis. Always conduct your own research or consult with a financial advisor before making investment decisions.''';
    
    return opportunities;
  }
  
  // Get risk assessment
  Future<String> getRiskAssessment() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (_summary == null) {
      return 'No portfolio data available for risk assessment.';
    }
    
    String riskLevel;
    String recommendations;
    
    if (_summary!.riskScore <= 3) {
      riskLevel = 'Low';
      recommendations = '''Your portfolio has a conservative risk profile, which is suitable for investors prioritizing capital preservation. While this approach provides stability, it may limit growth potential, especially in bullish markets.

Consider:
• Gradually increasing exposure to growth assets for long-term investors
• Exploring dividend growth stocks to enhance returns while maintaining relative stability
• Adding selective technology or consumer discretionary stocks to potentially boost returns''';
    } else if (_summary!.riskScore <= 6) {
      riskLevel = 'Moderate';
      recommendations = '''Your portfolio has a balanced risk profile with a mix of growth and stability. This approach typically provides a good balance between capital appreciation and preservation.

Consider:
• Reviewing sector allocations to ensure proper diversification
• Maintaining current risk levels while optimizing within asset classes
• Setting up systematic rebalancing to maintain your target risk profile''';
    } else {
      riskLevel = 'High';
      recommendations = '''Your portfolio has an aggressive risk profile with significant exposure to volatile assets. While this approach may offer higher returns in favorable markets, it also carries substantial downside risk.

Consider:
• Adding some defensive positions to provide cushioning during market corrections
• Implementing stop-loss strategies for your most volatile holdings
• Diversifying within your high-growth assets to reduce company-specific risk
• Adding uncorrelated assets to improve the risk-adjusted return profile''';
    }
    
    final assessment = '''**Portfolio Risk Assessment**

**Risk Level: $riskLevel (${_summary!.riskScore.toStringAsFixed(1)}/10)**

**Risk Factors:**
• Cryptocurrency Exposure: ${_summary!.assetAllocation['crypto']?.toStringAsFixed(1) ?? '0'}% of portfolio
• Technology Sector Concentration: ${_summary!.sectorAllocation['Technology']?.toStringAsFixed(1) ?? '0'}% of portfolio
• Portfolio Volatility: ${_calculatePortfolioVolatility()}
• Diversification: ${_calculateDiversificationScore()}

**Volatility Sources:**
${_getVolatilitySources()}

**Risk Management Recommendations:**
$recommendations

**Market Condition Impact:**
Based on current market conditions, your portfolio may experience ${_summary!.riskScore > 5 ? 'higher than average' : 'moderate'} volatility in the near term. Economic indicators suggest ${_summary!.riskScore > 7 ? 'caution is warranted' : 'a balanced approach is appropriate'}.

Remember that higher risk profiles can lead to greater returns but also larger drawdowns. Ensure your risk tolerance aligns with your investment objectives and time horizon.''';
    
    return assessment;
  }
  
  // Helper methods for risk assessment
  String _calculatePortfolioVolatility() {
    // This would normally involve complex calculations with historical data
    // Simplified for demo purposes
    if (_summary!.riskScore < 4) {
      return "Low - Your portfolio is expected to experience less price fluctuation than the broader market";
    } else if (_summary!.riskScore < 7) {
      return "Medium - Your portfolio volatility is approximately in line with major market indices";
    } else {
      return "High - Your portfolio may experience significant price swings exceeding market average";
    }
  }
  
  String _calculateDiversificationScore() {
    // Count the number of sectors with significant allocation
    int diversifiedSectors = 0;
    for (var entry in _summary!.sectorAllocation.entries) {
      if (entry.value >= 5) { // More than 5% allocation
        diversifiedSectors++;
      }
    }
    
    if (diversifiedSectors <= 2) {
      return "Low - Portfolio is concentrated in few sectors";
    } else if (diversifiedSectors <= 4) {
      return "Moderate - Some diversification across sectors";
    } else {
      return "High - Well diversified across multiple sectors";
    }
  }
  
  String _getVolatilitySources() {
    List<String> sources = [];
    
    if ((_summary!.assetAllocation['crypto'] ?? 0) > 10) {
      sources.add("• Cryptocurrency holdings (${_summary!.assetAllocation['crypto']?.toStringAsFixed(1)}% of portfolio)");
    }
    
    if ((_summary!.sectorAllocation['Technology'] ?? 0) > 25) {
      sources.add("• Technology sector concentration (${_summary!.sectorAllocation['Technology']?.toStringAsFixed(1)}% of portfolio)");
    }
    
    if (_assets.length < 10) {
      sources.add("• Limited number of holdings (${_assets.length} assets)");
    }
    
    double largestPosition = 0;
    String largestSymbol = "";
    
    for (var asset in _assets) {
      final percentage = (asset.totalValue ?? 0) / (_summary?.totalValue ?? 1) * 100;
      if (percentage > largestPosition) {
        largestPosition = percentage;
        largestSymbol = asset.symbol;
      }
    }
    
    if (largestPosition > 15) {
      sources.add("• Large position in $largestSymbol (${largestPosition.toStringAsFixed(1)}% of portfolio)");
    }
    
    return sources.isEmpty ? "• No significant volatility sources identified" : sources.join("\n");
  }
}

class PortfolioAsset {
  final String id;
  final String symbol;
  final String name;
  final String type; // 'stock', 'crypto', 'etf', etc.
  final double quantity;
  final double purchasePrice;
  final double? currentPrice;
  final double? totalValue;
  final double? profitLoss;
  final double? profitLossPercentage;
  final DateTime purchaseDate;
  
  PortfolioAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.purchasePrice,
    this.currentPrice,
    this.totalValue,
    this.profitLoss,
    this.profitLossPercentage,
    required this.purchaseDate,
  });
}

class PortfolioSummary {
  final double totalValue;
  final double totalInvestment;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final Map<String, double> assetAllocation;
  final Map<String, double> sectorAllocation;
  final double riskScore; // 0-10 scale
  
  PortfolioSummary({
    required this.totalValue,
    required this.totalInvestment,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.assetAllocation,
    required this.sectorAllocation,
    required this.riskScore,
  });
}