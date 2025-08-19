import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'secrets.dart'; // Make sure you have this file with your API keys

class ChatService with ChangeNotifier {
  List<Map<String, dynamic>> messages = [];
  final String geminiApiKey = Secrets.geminiApiKey;
  final String alphaVantageKey = Secrets.alphaVantageKey;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // History of financial data to avoid repeated API calls
  final Map<String, Map<String, dynamic>> _stockCache = {};
  final Map<String, Map<String, dynamic>> _cryptoCache = {};
  DateTime? _lastMarketDataFetch;
  Map<String, dynamic>? _lastMarketData;

  // Time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning";
    } else if (hour < 17) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  // Send user message and get AI response
  void sendMessage(String text) {
    final time = DateFormat('h:mm a').format(DateTime.now());

    // Add user message to chat
    messages.add({
      'text': text,
      'isUser': true,
      'time': time,
    });
    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    // Get AI response
    getAIResponse(text).then((response) {
      final responseTime = DateFormat('h:mm a').format(DateTime.now());
      messages.add({
        'text': response,
        'isUser': false,
        'time': responseTime,
      });
      _isLoading = false;
      notifyListeners();
    }).catchError((error) {
      print("Error in response: $error");
      final responseTime = DateFormat('h:mm a').format(DateTime.now());
      messages.add({
        'text': "I apologize, but I encountered an issue while analyzing that request. Let's try a different approach or question. If you're looking for specific market data, you can ask me about stocks, cryptocurrencies, or the overall market status.",
        'isUser': false,
        'time': responseTime,
      });
      _isLoading = false;
      notifyListeners();
    });
  }

  // Get market data with caching
  Future<String> _getMarketData() async {
    // Check if we have recent data (within 5 minutes)
    final now = DateTime.now();
    if (_lastMarketDataFetch != null &&
        _lastMarketData != null &&
        now.difference(_lastMarketDataFetch!).inMinutes < 5) {
      return _formatMarketData(_lastMarketData!);
    }

    try {
      // Fetch S&P 500 data
      final spyResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=SPY&apikey=$alphaVantageKey'));

      // Fetch Dow Jones data
      final diaResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=DIA&apikey=$alphaVantageKey'));

      // Fetch Nasdaq data
      final qqqResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=QQQ&apikey=$alphaVantageKey'));

      if (spyResponse.statusCode == 200 &&
          diaResponse.statusCode == 200 &&
          qqqResponse.statusCode == 200) {
        final spyData = jsonDecode(spyResponse.body);
        final diaData = jsonDecode(diaResponse.body);
        final qqqData = jsonDecode(qqqResponse.body);

        final marketData = {
          'spy': spyData['Global Quote'],
          'dia': diaData['Global Quote'],
          'qqq': qqqData['Global Quote'],
          'timestamp': now.toString(),
        };

        // Cache the data
        _lastMarketData = marketData;
        _lastMarketDataFetch = now;

        return _formatMarketData(marketData);
      }
      return "⚠️ Market data is currently unavailable. Please try again later. This could be due to API rate limits or temporary service disruptions.";
    } catch (e) {
      print("Market data error: $e");
      return "❌ I'm having trouble connecting to the market data services. Please check your internet connection or try again in a few minutes.";
    }
  }

  // Format market data for display with more user-friendly output
  String _formatMarketData(Map<String, dynamic> data) {
    try {
      final spy = data['spy'];
      final dia = data['dia'];
      final qqq = data['qqq'];

      if (spy == null || dia == null || qqq == null) {
        return "⚠️ I could only retrieve partial market data. This might be due to API limits or service issues. Please try again in a few minutes.";
      }

      // Determine overall market trend
      final spyChangeStr = spy['10. change percent'] ?? '0%';
      final diaChangeStr = dia['10. change percent'] ?? '0%';
      final qqqChangeStr = qqq['10. change percent'] ?? '0%';
      
      // Extract percentages, handling % signs and parentheses
      final spyChange = double.parse(spyChangeStr.replaceAll('%', '').replaceAll('(', '').replaceAll(')', ''));
      final diaChange = double.parse(diaChangeStr.replaceAll('%', '').replaceAll('(', '').replaceAll(')', ''));
      final qqqChange = double.parse(qqqChangeStr.replaceAll('%', '').replaceAll('(', '').replaceAll(')', ''));
      
      final avgChange = (spyChange + diaChange + qqqChange) / 3;
      
      // Get appropriate market sentiment and icon
      String marketMood, marketIcon;
      if (avgChange < -1.5) {
        marketMood = "significantly bearish";
        marketIcon = "📉";
      } else if (avgChange < -0.5) {
        marketMood = "moderately bearish";
        marketIcon = "🔴";
      } else if (avgChange < 0) {
        marketMood = "slightly bearish";
        marketIcon = "🟠";
      } else if (avgChange < 0.5) {
        marketMood = "neutral to slightly bullish";
        marketIcon = "🟡";
      } else if (avgChange < 1.5) {
        marketMood = "moderately bullish";
        marketIcon = "🟢";
      } else {
        marketMood = "strongly bullish";
        marketIcon = "📈";
      }
      
      // Format time in a friendly way
      final now = DateTime.parse(data['timestamp']);
      final timeString = DateFormat('h:mm a').format(now);
      final dateString = DateFormat('EEEE, MMMM d, yyyy').format(now);
      
      // Get up/down arrows
      final spyArrow = spyChange >= 0 ? "↗️" : "↘️";
      final diaArrow = diaChange >= 0 ? "↗️" : "↘️";
      final qqqArrow = qqqChange >= 0 ? "↗️" : "↘️";
      
      // Color indicators (emoji-based since we can't use actual colors in text)
      final spyColor = spyChange >= 0 ? "🟢" : "🔴";
      final diaColor = diaChange >= 0 ? "🟢" : "🔴";
      final qqqColor = qqqChange >= 0 ? "🟢" : "🔴";

      // Format the market overview with more personality and detail
      String response = "${_getTimeBasedGreeting()}! Here's your market update as of $timeString $marketIcon\n\n";
      response += "📊 **Current Market Overview**\n";
      response += "The market is looking $marketMood today.\n\n";
      
      // S&P 500
      response += "**S&P 500 (SPY):** $spyArrow $spyColor\n";
      response += "• Price: \$${double.parse(spy['05. price']).toStringAsFixed(2)}\n";
      response += "• Change: ${spy['10. change percent']} from previous close\n";
      response += "• Volume: ${NumberFormat.compact().format(int.parse(spy['06. volume']))} shares\n\n";
      
      // Dow Jones
      response += "**Dow Jones (DIA):** $diaArrow $diaColor\n";
      response += "• Price: \$${double.parse(dia['05. price']).toStringAsFixed(2)}\n";
      response += "• Change: ${dia['10. change percent']} from previous close\n\n";
      
      // Nasdaq
      response += "**Nasdaq (QQQ):** $qqqArrow $qqqColor\n";
      response += "• Price: \$${double.parse(qqq['05. price']).toStringAsFixed(2)}\n";
      response += "• Change: ${qqq['10. change percent']} from previous close\n\n";
      
      // Market insights
      response += "**What This Means:**\n";
      
      if (Math.abs(avgChange) < 0.5) {
        response += "• The market is showing low volatility today\n";
      } else if (Math.abs(avgChange) > 1.5) {
        response += "• The market is experiencing high volatility today\n";
      }
      
      if (qqqChange < spyChange && qqqChange < diaChange) {
        response += "• Technology stocks are underperforming compared to other sectors\n";
      } else if (qqqChange > spyChange && qqqChange > diaChange) {
        response += "• Technology stocks are outperforming the broader market\n";
      }
      
      if (diaChange > spyChange && diaChange > qqqChange) {
        response += "• Blue chip stocks are showing strength today\n";
      }
      
      // Add follow-up suggestions
      response += "\n**Would you like to know more about:**\n";
      response += "• A specific stock (e.g., 'Show me AAPL stock')\n";
      response += "• Cryptocurrency performance (e.g., 'Bitcoin price')\n";
      response += "• Market sentiment and analysis\n";
      
      // Add update time and source
      response += "\nLast updated: $dateString at $timeString\n";
      response += "_Data provided by Alpha Vantage_";
      
      return response;
    } catch (e) {
      print("Error formatting market data: $e");
      return "I encountered an issue processing the market data. The data structure may have changed or there might be a temporary API issue. Let me know if you'd like me to try again or help with something else.";
    }
  }

  // Get stock data with caching
  Future<String> _getStockData(String symbol) async {
    // Standardize symbol format
    symbol = symbol.toUpperCase().trim();
    

    // Check cache for recent data (within 15 minutes)
    final now = DateTime.now();
    if (_stockCache.containsKey(symbol)) {
      final cacheTime = DateTime.parse(_stockCache[symbol]!['timestamp']);
      if (now.difference(cacheTime).inMinutes < 15) {
        return _formatStockData(_stockCache[symbol]!, symbol);
      }
    }

    try {
      // Get quote data
      final quoteResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageKey'));

      // Get company overview
      final overviewResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=OVERVIEW&symbol=$symbol&apikey=$alphaVantageKey'));

      if (quoteResponse.statusCode == 200 &&
          overviewResponse.statusCode == 200) {
        final quoteData = jsonDecode(quoteResponse.body);
        final overviewData = jsonDecode(overviewResponse.body);

        if (quoteData['Global Quote'] == null ||
            quoteData['Global Quote'].isEmpty) {
          return "⚠️ I couldn't find data for $symbol. Please verify the stock symbol and try again. For example, Apple's symbol is 'AAPL', Microsoft is 'MSFT', etc.";
        }
        // Combine data
        final stockData = {
          'quote': quoteData['Global Quote'],
          'overview': overviewData,
          'timestamp': now.toString(),
        };

        // Cache the data
        _stockCache[symbol] = stockData;

        return _formatStockData(stockData, symbol);
      }

      return "⚠️ I couldn't retrieve complete data for $symbol. This might be due to API limits or an invalid symbol. Please check the symbol and try again in a few minutes.";
    } catch (e) {
      print("Stock data error for $symbol: $e");
      return "❌ I ran into an issue while getting data for $symbol. Please check your internet connection or try again later.";
    }
  }

  // Format stock data for display with enhanced presentation
  String _formatStockData(Map<String, dynamic> data, String symbol) {
    try {
      final quote = data['quote'];
      final overview = data['overview'];

      // Handle empty response
      if (quote == null || quote.isEmpty) {
        return "⚠️ No data available for $symbol. Please check the symbol and try again.";
      }

      // Determine if stock is up or down
      final changePercent = quote['10. change percent'] ?? '';
      final changePercentClean = changePercent.replaceAll('%', '').replaceAll('(', '').replaceAll(')', '');
      final changeValue = double.parse(changePercentClean);
      final isUp = changeValue >= 0;
      final trendIcon = isUp ? "🟢" : "🔴";
      final trendArrow = isUp ? "↗️" : "↘️";

      // Get trading date
      final tradeDateFormatted = quote['07. latest trading day'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Format the stock data with company information if available
      String response = "${_getTimeBasedGreeting()}! Here's your analysis for $symbol $trendIcon\n\n";

      // Add company name and sector if available
      if (overview != null && overview.isNotEmpty) {
        final companyName = overview['Name'] ?? symbol;
        response += "📊 **$companyName ($symbol)** $trendArrow\n";
        
        if (overview['Sector'] != null) {
          response += "**Sector:** ${overview['Sector']}";
          if (overview['Industry'] != null) {
            response += " | **Industry:** ${overview['Industry']}";
          }
          response += "\n";
        }
        
        if (overview['Description'] != null && overview['Description'].toString().isNotEmpty) {
          String description = overview['Description'];
          if (description.length > 200) {
            description = "${description.substring(0, 200)}...";
          }
          response += "\n_$description\n";
        }
        
        response += "\n";
      } else {
        response += "📊 **$symbol Stock Analysis** $trendArrow\n\n";
      }
      // Add price and change information with more detail
      final currentPrice = double.parse(quote['05. price'] ?? '0');
      final previousClose = double.parse(quote['08. previous close'] ?? '0');
      final priceChange = double.parse(quote['09. change'] ?? '0');
      
      response += "**Price Data:**\n";
      response += "• Current: \$${currentPrice.toStringAsFixed(2)}\n";
      response += "• Previous Close: \$${previousClose.toStringAsFixed(2)}\n";
      response += "• Change: ${isUp ? '+' : ''}${priceChange.toStringAsFixed(2)} (${quote['10. change percent']})\n";
      
      // Add day's range
      final dayLow = double.parse(quote['04. low'] ?? '0');
      final dayHigh = double.parse(quote['03. high'] ?? '0');
      response += "• Today's Range: \$${dayLow.toStringAsFixed(2)} - \$${dayHigh.toStringAsFixed(2)}\n";
      
      // Calculate position in day's range
      if (dayHigh > dayLow) {
        final rangePosition = ((currentPrice - dayLow) / (dayHigh - dayLow) * 100).round();
        response += "• Position in Range: $rangePosition% of daily range\n";
      }
      
      // Add volume with comparison if available
      final volume = int.parse(quote['06. volume'] ?? '0');
      response += "• Volume: ${NumberFormat.compact().format(volume)} shares\n\n";

      // Add fundamentals with more context if available
      if (overview != null && overview.isNotEmpty) {
        response += "**Fundamentals:**\n";
        
        // P/E Ratio with context
        if (overview['PERatio'] != null && overview['PERatio'] != 'None') {
          final peRatio = double.parse(overview['PERatio']);
          String peContext = "";
          if (peRatio < 0) {
            peContext = " (Negative earnings)";
          } else if (peRatio < 15) {
            peContext = " (Potentially undervalued)";
          } else if (peRatio > 30) {
            peContext = " (Higher growth expectations)";
          }
          response += "• P/E Ratio: ${peRatio.toStringAsFixed(2)}$peContext\n";
        }
        
        // Dividend info with yield
        if (overview['DividendYield'] != null && overview['DividendYield'] != 'None' && overview['DividendYield'] != '0') {
          final dividendYield = double.parse(overview['DividendYield']) * 100;
          response += "• Dividend Yield: ${dividendYield.toStringAsFixed(2)}%";
          
          if (overview['DividendPerShare'] != null && overview['DividendPerShare'] != 'None' && overview['DividendPerShare'] != '0') {
            final dividendPerShare = double.parse(overview['DividendPerShare']);
            response += " (\$${dividendPerShare.toStringAsFixed(2)} per share)";
          }
          response += "\n";
        } else {
          response += "• Dividend: No dividend\n";
        }
        
        // 52-week range with current position
        if (overview['52WeekHigh'] != null && overview['52WeekLow'] != null) {
          final fiftyTwoWeekLow = double.parse(overview['52WeekLow']);
          final fiftyTwoWeekHigh = double.parse(overview['52WeekHigh']);
          response += "• 52-Week Range: \$${fiftyTwoWeekLow.toStringAsFixed(2)} - \$${fiftyTwoWeekHigh.toStringAsFixed(2)}\n";
          
          // Calculate position in 52-week range
          if (fiftyTwoWeekHigh > fiftyTwoWeekLow) {
            final rangePosition = ((currentPrice - fiftyTwoWeekLow) / (fiftyTwoWeekHigh - fiftyTwoWeekLow) * 100).round();
            response += "• Position in 52-Week Range: $rangePosition%\n";
          }
        }
        
        // Market cap with context
        if (overview['MarketCapitalization'] != null) {
          final marketCap = int.parse(overview['MarketCapitalization']);
          String marketCapCategory = "";
          if (marketCap > 200000000000) {
            marketCapCategory = " (Mega Cap)";
          } else if (marketCap > 10000000000) {
            marketCapCategory = " (Large Cap)";
          } else if (marketCap > 2000000000) {
            marketCapCategory = " (Mid Cap)";
          } else if (marketCap > 300000000) {
            marketCapCategory = " (Small Cap)";
          } else {
            marketCapCategory = " (Micro Cap)";
          }
          response += "• Market Cap: ${NumberFormat.compactCurrency(symbol: '\$').format(marketCap)}$marketCapCategory\n";
        }
        
        // Add EPS and Beta if available
        if (overview['EPS'] != null && overview['EPS'] != 'None') {
          final eps = double.parse(overview['EPS']);
          response += "• EPS: \$${eps.toStringAsFixed(2)}\n";
        }
        
        if (overview['Beta'] != null && overview['Beta'] != 'None') {
          final beta = double.parse(overview['Beta']);
          String betaContext = "";
          if (beta < 0.8) {
            betaContext = " (Less volatile than market)";
          } else if (beta > 1.2) {
            betaContext = " (More volatile than market)";
          } else {
            betaContext = " (Similar volatility to market)";
          }
          response += "• Beta: ${beta.toStringAsFixed(2)}$betaContext\n";
        }
      }

      // Add analyst recommendations if available
      if (overview != null && overview['AnalystRatingStrongBuy'] != null) {
        response += "\n**Analyst Ratings:**\n";
        // This is hypothetical as Alpha Vantage doesn't provide this directly,
        // but could be added if you have this data
        response += "• Consensus: Hold with price target of \$XX.XX\n";
      }

      // Add follow-up suggestions
      response += "\n**What would you like to know next?**\n";
      response += "• 'Predict $symbol' for price outlook\n";
      response += "• 'Compare with competitors'\n";
      response += "• 'Show me similar stocks'\n";

      // Add timestamp and data source
      response += "\nLast updated: ${DateFormat('EEEE, MMMM d').format(DateTime.parse(data['timestamp']))} at ${DateFormat('h:mm a').format(DateTime.parse(data['timestamp']))}\n";
      response += "Trading date: $tradeDateFormatted\n";
      response += "_Data provided by Alpha Vantage_";

      return response;
    } catch (e) {
      print("Error formatting stock data for $symbol: $e");
      return "⚠️ I had trouble processing the data for $symbol. This might be due to an unexpected data format. You can try another stock symbol or ask about the market in general.";
    }
  }

  // Get cryptocurrency data with caching
  Future<String> _getCryptoData(String symbol) async {
    // Standardize symbol format
    symbol = symbol.toUpperCase().trim();

    // Check cache for recent data (within 15 minutes)
    final now = DateTime.now();
    if (_cryptoCache.containsKey(symbol)) {
      final cacheTime = DateTime.parse(_cryptoCache[symbol]!['timestamp']);
      if (now.difference(cacheTime).inMinutes < 15) {
        return _formatCryptoData(_cryptoCache[symbol]!, symbol);
      }
    }

    try {
      // Get current exchange rate for the cryptocurrency
      final exchangeResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=$symbol&to_currency=USD&apikey=$alphaVantageKey'));

      // Get daily time series for the cryptocurrency
      final dailyResponse = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_DAILY&symbol=$symbol&market=USD&apikey=$alphaVantageKey'));

      if (exchangeResponse.statusCode == 200 && dailyResponse.statusCode == 200) {
        final exchangeData = jsonDecode(exchangeResponse.body);
        final dailyData = jsonDecode(dailyResponse.body);

        // Check if we have real data or an error message from Alpha Vantage
        if (exchangeData['Realtime Currency Exchange Rate'] == null &&
            !exchangeData.containsKey('Realtime Currency Exchange Rate')) {
          return "⚠️ I couldn't find data for the cryptocurrency $symbol. Please verify the symbol and try again. For example, Bitcoin's symbol is 'BTC', Ethereum is 'ETH', etc.";
        }

        // Combine data
        final cryptoData = {
          'exchange': exchangeData['Realtime Currency Exchange Rate'],
          'daily': dailyData,
          'timestamp': now.toString(),
        };

        // Cache the data
        _cryptoCache[symbol] = cryptoData;

        return _formatCryptoData(cryptoData, symbol);
      }

      return "⚠️ I couldn't retrieve complete data for the cryptocurrency $symbol. This might be due to API limits or an invalid symbol. Please check the symbol and try again in a few minutes.";
    } catch (e) {
      print("Crypto data error for $symbol: $e");
      return "❌ I ran into an issue while getting data for the cryptocurrency $symbol. Please check your internet connection or try again later.";
    }
  }

  // Format cryptocurrency data for display with enhanced UX
  String _formatCryptoData(Map<String, dynamic> data, String symbol) {
    try {
      final exchange = data['exchange'];
      final daily = data['daily'];

      if (exchange == null) {
        return "⚠️ No exchange rate data available for $symbol. Please check the symbol and try again.";
      }

      // Get full name and friendly display name
      final cryptoName = exchange['2. From_Currency Name'] ?? symbol;
      String friendlyName;
      
      // Map common cryptos to their popular names with logos
      switch (symbol.toUpperCase()) {
        case 'BTC':
          friendlyName = "Bitcoin (₿)";
          break;
        case 'ETH':
          friendlyName = "Ethereum (Ξ)";
          break;
        case 'USDT':
          friendlyName = "Tether (₮)";
          break;
        case 'BNB':
          friendlyName = "Binance Coin";
          break;
        case 'SOL':
          friendlyName = "Solana";
          break;
        case 'XRP':
          friendlyName = "Ripple";
          break;
        case 'ADA':
          friendlyName = "Cardano";
          break;
        case 'DOGE':
          friendlyName = "Dogecoin";
          break;
        default:
          friendlyName = cryptoName;
      }

      // Current price and format based on price level
      final currentPrice = double.parse(exchange['5. Exchange Rate'] ?? '0');
      String formattedPrice;
      if (currentPrice >= 1000) {
        formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(currentPrice);
      } else if (currentPrice >= 1) {
        formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(currentPrice);
      } else if (currentPrice >= 0.01) {
        formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 4).format(currentPrice);
      } else {
        formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 6).format(currentPrice);
      }

      // Calculate daily change if possible
      var changePercent = "N/A";
      var changeIcon = "⚪";
      var changeValue = 0.0;
      var todayClose = 0.0;
      var yesterdayClose = 0.0;
      var hasChangeData = false;

      if (daily != null && daily['Time Series (Digital Currency Daily)'] != null) {
        final timeSeries = daily['Time Series (Digital Currency Daily)'];
        final dates = timeSeries.keys.toList();

        if (dates.length >= 2) {
          final today = timeSeries[dates[0]];
          final yesterday = timeSeries[dates[1]];

          if (today != null && yesterday != null) {
            todayClose = double.parse(today['4a. close (USD)'] ?? '0');
            yesterdayClose = double.parse(yesterday['4a. close (USD)'] ?? '0');

            if (todayClose > 0 && yesterdayClose > 0) {
              changeValue = ((todayClose - yesterdayClose) / yesterdayClose) * 100;
              changePercent = '${changeValue.toStringAsFixed(2)}%';
              changeIcon = changeValue >= 0 ? "🟢" : "🔴";
              hasChangeData = true;
            }
          }
        }
      }

      // Get time for greeting
      final timeBasedGreeting = _getTimeBasedGreeting();

      // Format the crypto data with more personality and detail
      String response = "$timeBasedGreeting! Here's your cryptocurrency analysis:\n\n";
      
      // Crypto header with appropriate icon
      String cryptoIcon;
      switch (symbol.toUpperCase()) {
        case 'BTC':
          cryptoIcon = "₿";
          break;
        case 'ETH':
          cryptoIcon = "Ξ";
          break;
        case 'USDT':
          cryptoIcon = "₮";
          break;
        case 'DOGE':
          cryptoIcon = "🐶";
          break;
        default:
          cryptoIcon = "🪙";
      }
      
      response += "$cryptoIcon **$friendlyName ($symbol)** $changeIcon\n\n";
      
      // Current price with emphasis
      response += "**Current Price:** $formattedPrice\n";
      
      // Change data with context
      if (hasChangeData) {
        final changeDirection = changeValue >= 0 ? "↗️ up" : "↘️ down";
        response += "**24h Change:** $changeDirection $changePercent";
        
        // Add absolute value change
        final absoluteChange = Math.abs(todayClose - yesterdayClose);
        String formattedAbsoluteChange;
        if (absoluteChange >= 1000) {
          formattedAbsoluteChange = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(absoluteChange);
        } else if (absoluteChange >= 1) {
          formattedAbsoluteChange = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(absoluteChange);
        } else {
          formattedAbsoluteChange = NumberFormat.currency(symbol: '\$', decimalDigits: 4).format(absoluteChange);
        }
        response += " ($formattedAbsoluteChange)\n";
      } else {
        response += "**24h Change:** Data unavailable\n";
      }
      // Market info
      response += "**Market:** ${exchange['4. To_Currency Name']} (${exchange['3. To_Currency Code']})\n";
      response += "**Exchange Rate Time:** ${exchange['6. Last Refreshed'] ?? 'N/A'}\n\n";

      // Add trading data if available
      if (daily != null && daily['Time Series (Digital Currency Daily)'] != null) {
        final timeSeries = daily['Time Series (Digital Currency Daily)'];
        final latestDate = timeSeries.keys.first;
        final latestData = timeSeries[latestDate];

        if (latestData != null) {
          final volume = double.parse(latestData['5. volume'] ?? '0');
          final volumeUSD = double.parse(latestData['5. volume'] ?? '0') * currentPrice;
          final open = double.parse(latestData['1a. open (USD)'] ?? '0');
          final high = double.parse(latestData['2a. high (USD)'] ?? '0');
          final low = double.parse(latestData['3a. low (USD)'] ?? '0');

          response += "**Today's Trading Activity:**\n";
          
          // Volume with better formatting
          response += "• Volume: ${NumberFormat.compact().format(volume)} $symbol\n";
          response += "• Volume (USD): ${NumberFormat.compactCurrency(symbol: '\$').format(volumeUSD)}\n";
          
          // Day's range with visual indicator of current position
          response += "• Day's Range: ${NumberFormat.currency(symbol: '\$', decimalDigits: currentPrice < 1 ? 4 : 2).format(low)} - ${NumberFormat.currency(symbol: '\$', decimalDigits: currentPrice < 1 ? 4 : 2).format(high)}\n";
          
          // Position in day's range
          if (high > low) {
            final rangePosition = ((currentPrice - low) / (high - low) * 100).round();
            response += "• Position in Day's Range: $rangePosition%\n";
          }
          
          // Market sentiment based on position relative to open
          if (currentPrice > open) {
            final percentAboveOpen = ((currentPrice - open) / open * 100).toStringAsFixed(2);
            response += "• Trading $percentAboveOpen% above today's open\n";
          } else if (currentPrice < open) {
            final percentBelowOpen = ((open - currentPrice) / open * 100).toStringAsFixed(2);
            response += "• Trading $percentBelowOpen% below today's open\n";
          } else {
            response += "• Trading at the same level as today's open\n";
          }
        }
      }

      // Add market trend analysis
      response += "\n**Market Analysis:**\n";
      if (hasChangeData) {
        if (changeValue > 5) {
          response += "• Strong bullish momentum in the last 24 hours\n";
        } else if (changeValue > 2) {
          response += "• Moderate upward trend in the last 24 hours\n";
        } else if (changeValue > 0) {
          response += "• Slight positive movement in the last 24 hours\n";
        } else if (changeValue > -2) {
          response += "• Minor negative movement in the last 24 hours\n";
        } else if (changeValue > -5) {
          response += "• Moderate downward trend in the last 24 hours\n";
        } else {
          response += "• Strong bearish momentum in the last 24 hours\n";
        }
      }
      
      // Add token-specific context for major cryptocurrencies
      switch(symbol.toUpperCase()) {
        case 'BTC':
          response += "• Bitcoin is viewed as the market leader and often influences overall crypto market direction\n";
          break;
        case 'ETH':
          response += "• Ethereum is fundamental to DeFi and the broader blockchain ecosystem\n";
          break;
        case 'SOL':
          response += "• Solana is known for high throughput and low transaction costs\n";
          break;
        case 'ADA':
          response += "• Cardano focuses on research-driven development and sustainability\n";
          break;
        case 'XRP':
          response += "• Ripple/XRP is designed for cross-border payment solutions\n";
          break;
        case 'DOGE':
          response += "• Dogecoin often exhibits high volatility in response to social media\n";
          break;
        default:
          // No specific context for less common tokens
      }

      // Add next actions suggestion
      response += "\n**What would you like to know?**\n";
      response += "• 'Predict $symbol' for price forecast\n";
      response += "• 'Compare with other cryptocurrencies'\n";
      response += "• 'Show me $symbol news'\n";

      // Add price prediction disclaimer
      response += "\n**Disclaimer:** Cryptocurrency prices are highly volatile and predictions should be treated as speculative. Past performance is not indicative of future results.\n";

      // Add timestamp and data source
      response += "\nLast updated: ${DateFormat('MMMM d, h:mm a').format(DateTime.parse(data['timestamp']))}\n";
      response += "_Data provided by Alpha Vantage_";

      return response;
    } catch (e) {
      print("Error formatting crypto data for $symbol: $e");
      return "⚠️ I encountered difficulty processing cryptocurrency data for $symbol. This could be due to API limitations or volatility in the data. You can try another cryptocurrency or ask about market trends in general.";
    }
  }

  // Handle market sentiment analysis with Gemini
  Future<String> _getMarketSentiment() async {
    try {
      final prompt = """
      Act as a financial expert and provide a current market sentiment analysis. 
      Focus on these aspects:
      1. General market mood (bullish, bearish, or neutral)
      2. Key sectors that are trending
      3. Major factors currently influencing the market
      4. Short-term outlook
      
      Format your response with clear sections and bullet points.
      Use emojis where appropriate.
      Keep the response concise and focused on actionable insights.
      
      DO NOT make up specific numbers or statistics, only provide general insights.
      """;

      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var sentimentText = data['candidates'][0]['content']['parts'][0]
                ['text'] ??
            "Unable to generate market sentiment analysis at this time.";

        return "${_getTimeBasedGreeting()}! Here's the latest market sentiment analysis:\n\n🧠 **Market Sentiment Analysis**\n\n$sentimentText\n\n_Analysis generated by AI based on market patterns_\n\nWould you like to know more about specific sectors, stocks, or cryptocurrencies?";
      }

      return "⚠️ I couldn't generate a market sentiment analysis at this moment. This might be due to API limitations. Please try again later or ask about specific stocks or market data instead.";
    } catch (e) {
      print("Market sentiment error: $e");
      return "❌ I encountered an issue while generating the market sentiment analysis. This might be due to connectivity problems or API limitations. Please try again later.";
    }
  }

  // Generate predictions for stock/crypto
  Future<String> _generatePrediction(String symbol, String type) async {
    try {
      // Get current data first
      String currentData;
      if (type.toLowerCase() == 'crypto') {
        currentData = await _getCryptoData(symbol);
      } else {
        currentData = await _getStockData(symbol);
      }

      // Create a prompt for Gemini with more engaging output request
      final prompt = """
      Act as a financial analyst and provide a prediction analysis for ${type.toLowerCase() == 'crypto' ? 'cryptocurrency' : 'stock'} $symbol.
      
      Here is the current data:
      $currentData
      
      Provide insights on:
      1. Short-term outlook (1-7 days)
      2. Medium-term outlook (1-3 months)
      3. Key factors that could influence price
      4. Potential support and resistance levels (approximate)
      
      Format your analysis with clear sections and use a conversational, engaging tone. 
      Include a balanced view considering both bullish and bearish scenarios.
      Use bullet points for clarity and emojis where appropriate.
      
      IMPORTANT: Add standard disclaimer about financial predictions being speculative.
      DO NOT make up specific price numbers, only provide general insights and ranges.
      
      Write as if you're a seasoned analyst speaking directly to the investor in an approachable but professional manner.
      """;

      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var predictionText = data['candidates'][0]['content']['parts'][0]
                ['text'] ??
            "Unable to generate prediction at this time.";

        return "${_getTimeBasedGreeting()}! Here's my analysis for $symbol:\n\n🔮 **$symbol ${type.toUpperCase()} Prediction Analysis**\n\n$predictionText\n\nWould you like to explore specific aspects of this prediction in more detail?";
      }

      return "⚠️ I couldn't generate a prediction for $symbol at this moment. This might be due to API limitations or insufficient data. Please try again later or ask about current market data instead.";
    } catch (e) {
      print("Prediction error for $symbol: $e");
      return "❌ I encountered an issue while generating the prediction for $symbol. This might be due to connectivity problems or API limitations. Please try again later.";
    }
  }

  // Main method to process user input and determine response
  Future<String> getAIResponse(String query) async {
    try {
      // Convert query to lowercase for case-insensitive matching
      final lowerQuery = query.toLowerCase();

      // Handle greetings and basic interactions with more personalization
      if (RegExp(r'\b(hello|hi|hey|greetings)\b').hasMatch(lowerQuery)) {
        return "${_getTimeBasedGreeting()}! 👋 I'm your Financial Market Predictor AI.\n\n"
            "I can help you with:\n"
            "• Market overviews and real-time data 📊\n"
            "• Stock analysis and fundamentals 📈\n"
            "• Cryptocurrency tracking and predictions 💰\n"
            "• Investment strategies and personalized advice 💼\n\n"
            "What financial information are you interested in today? You can ask about specific stocks, cryptocurrencies, or the overall market condition.";
      }

      // Handle thank you and appreciation with personality
      if (RegExp(r'\b(thank|thanks|thx|appreciate)\b').hasMatch(lowerQuery)) {
        return "You're welcome! 😊 I'm glad I could help. Is there anything else you'd like to know about the financial markets, specific stocks, or cryptocurrencies? I'm here to assist with any financial questions you have.";
      }

      // Handle market data requests
      if (RegExp(
              r'\b(market today|how is the market|market overview|market update|market status)\b')
          .hasMatch(lowerQuery)) {
        return await _getMarketData();
      }

      // Handle market sentiment analysis
      if (RegExp(
              r'\b(market sentiment|market feeling|market mood|investor sentiment|market outlook)\b')
          .hasMatch(lowerQuery)) {
        return await _getMarketSentiment();
      }

      // Handle specific stock requests
      final stockMatch = RegExp(
              r'(?:stock|price of|quote for|info on|data for)\s+([A-Za-z]{1,5})\b')
          .firstMatch(lowerQuery);
      if (stockMatch != null) {
        final symbol = stockMatch.group(1)!.toUpperCase();
        return await _getStockData(symbol);
      }

      // Detect if query contains stock symbol
      final symbolMatch = RegExp(r'\b([A-Z]{1,5})\b(?!\w)').allMatches(query);
      if (symbolMatch.isNotEmpty) {
        for (final match in symbolMatch) {
          final potentialSymbol = match.group(1)!;
          if (potentialSymbol.length >= 2 &&
              ![
                'AI',
                'MY',
                'ME',
                'BY',
                'TO',
                'AN',
                'IN',
                'ON',
                'IS',
                'BE',
                'IT',
                'AT',
                'OR',
                'IF',
                'AS'
              ].contains(potentialSymbol)) {
            if (lowerQuery.contains('stock') ||
                lowerQuery.contains('share') ||
                lowerQuery.contains('equity')) {
              return await _getStockData(potentialSymbol);
            }
          }
        }
      }

      // Handle cryptocurrency requests
      final cryptoMatch = RegExp(
              r'(?:crypto|cryptocurrency|bitcoin|ethereum|btc|eth)\s+([A-Za-z]{1,5})\b|([A-Za-z]{1,5})\s+(?:crypto|cryptocurrency)')
          .firstMatch(lowerQuery);
      if (cryptoMatch != null) {
        final symbol =
            (cryptoMatch.group(1) ?? cryptoMatch.group(2))!.toUpperCase();
        return await _getCryptoData(symbol);
      }

      // Handle common crypto names
      if (lowerQuery.contains('bitcoin') || lowerQuery.contains(' btc')) {
        return await _getCryptoData('BTC');
      }
      if (lowerQuery.contains('ethereum') || lowerQuery.contains(' eth')) {
        return await _getCryptoData('ETH');
      }
      if (lowerQuery.contains('dogecoin') || lowerQuery.contains(' doge')) {
        return await _getCryptoData('DOGE');
      }

      // Handle prediction requests for stocks
      final stockPredictMatch = RegExp(
              r'(?:forecast|predict|prediction|outlook|future)\s+(?:for|of)?\s+(?:stock|price)?\s+([A-Za-z]{1,5})\b')
          .firstMatch(lowerQuery);
      if (stockPredictMatch != null) {
        final symbol = stockPredictMatch.group(1)!.toUpperCase();
        return await _generatePrediction(symbol, 'stock');
      }

      // Handle prediction requests for crypto
      final cryptoPredictMatch = RegExp(
              r'(?:forecast|predict|prediction|outlook|future)\s+(?:for|of)?\s+(?:crypto|bitcoin|ethereum)\s+([A-Za-z]{1,5})\b')
          .firstMatch(lowerQuery);
      if (cryptoPredictMatch != null) {
        final symbol = cryptoPredictMatch.group(1)!.toUpperCase();
        return await _generatePrediction(symbol, 'crypto');
      }

      // Special cases for common crypto predictions
      if (RegExp(r'\b(bitcoin|btc)\b.+\b(forecast|predict|prediction|outlook|future)\b')
              .hasMatch(lowerQuery) ||
          RegExp(r'\b(forecast|predict|prediction|outlook|future)\b.+\b(bitcoin|btc)\b')
              .hasMatch(lowerQuery)) {
        return await _generatePrediction('BTC', 'crypto');
      }
      if (RegExp(r'\b(ethereum|eth)\b.+\b(forecast|predict|prediction|outlook|future)\b')
              .hasMatch(lowerQuery) ||
          RegExp(r'\b(forecast|predict|prediction|outlook|future)\b.+\b(ethereum|eth)\b')
              .hasMatch(lowerQuery)) {
        return await _generatePrediction('ETH', 'crypto');
      }

      // Default to Gemini AI for other queries with better prompt engineering
      // Replace the current enhancedQuery in the getAIResponse method with this:
final enhancedQuery = "As a professional financial advisor responding to this query: \"$query\"\n\n"
    "1. Provide a concise, authoritative response with no placeholder text or brackets\n"
    "2. Use a professional, confident tone suitable for financial industry executives\n"
    "3. Include specific, relevant financial insights using precise terminology\n"
    "4. Structure information clearly with logical flow\n"
    "5. Use minimal emoji - only where truly appropriate for emphasis\n"
    "6. Maintain professionalism while being engaging\n"
    "7. For specific stock queries, provide direct data and analysis\n"
    "8. For general queries or unknown company names, provide educational information without apologizing\n"
    "9. End with a thoughtful follow-up question that demonstrates market knowledge\n\n"
    "Important: Never use placeholder text like '[Client Name]'. Never apologize for not knowing something - instead pivot to providing valuable general information. Speak with authority but avoid making up specific numbers.";

      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": enhancedQuery}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            "I'm sorry, I couldn't process your request. Please try rephrasing your question or ask about specific market data.";
      }
      return "I encountered an issue processing your request. The financial AI service might be temporarily unavailable. Please try asking about market data, specific stocks, or cryptocurrencies instead.";
    } catch (e) {
      print("Error in getAIResponse: $e");
      return "I apologize, but I encountered an error while processing your request. This might be due to connectivity issues or API limitations. Please check your internet connection and try again with a specific question about stocks or market data.";
    }
  }

  // Clear all messages
  void clearMessages() {
    messages.clear();
    notifyListeners();
  }
}

// Math utility class (since we had Math.abs in the code)
class Math {
  static double abs(double value) {
    return value < 0 ? -value : value;
  }
}