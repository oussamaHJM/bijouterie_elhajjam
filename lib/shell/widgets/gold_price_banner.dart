import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';

class GoldPriceBanner extends StatefulWidget {
  const GoldPriceBanner({super.key});

  @override
  State<GoldPriceBanner> createState() => _GoldPriceBannerState();
}

class _GoldPriceBannerState extends State<GoldPriceBanner> {
  double? priceOunce;
  double? price18k;
  double? price24k;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGoldPrice();
  }

  Future<void> _fetchGoldPrice() async {
    try {
      // 100% free, open-source daily currency api via jsdelivr proxy globally
      final res = await http.get(Uri.parse('https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/xau.json'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final xauToMad = (data['xau']['mad'] as num).toDouble();
        
        // Standard Troy Ounce to Gram ratio
        final current24kPrice = xauToMad / 31.1034768;
        
        // 18k purity conversion (18/24)
        final current18kPrice = current24kPrice * 0.75;
        
        if (mounted) {
          setState(() {
            priceOunce = xauToMad;
            price24k = current24kPrice;
            price18k = current18kPrice;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || price18k == null) {
      return Container(
        height: 36,
        color: AppTheme.darkGreen,
        alignment: Alignment.center,
        child: const Text('Chargement du prix mondial de l\'or...', style: TextStyle(color: AppTheme.gold, fontSize: 11)),
      );
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGreen,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, color: AppTheme.gold, size: 16),
          const SizedBox(width: 6),
          const Text('Prix Or (MAD)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const Spacer(),
          const Text('Oz: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
          Text('${priceOunce!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          const Text('24k: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
          Text('${price24k!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.goldLight, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          const Text('18k: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
          Text('${price18k!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
