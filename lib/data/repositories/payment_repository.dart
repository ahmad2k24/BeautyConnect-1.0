import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final supabase = Supabase.instance.client;
  Future<String> createPaymentIntent({
    required int amountInCents,
    required String currency,
    required String merchantAccountId,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'send_payment',
      body: {
        'amount': amountInCents,
        'currency': currency,
        'merchant_account_id': merchantAccountId,
      },
    );

    if (res.status != 200) {
      throw Exception('Function call failed: ${res.data}');
    }

    // ✅ res.data is already a Map
    final data = res.data as Map<String, dynamic>;
    return data['clientSecret'] as String;
  }

  Future<void> payMerchant({
    required int amountInCents,
    required String currency,
    required String merchantAccountId,
  }) async {
    try {
      // 1. Create PaymentIntent
      final clientSecret = await createPaymentIntent(
        amountInCents: amountInCents,
        currency: currency,
        merchantAccountId: merchantAccountId,
      );

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.system,
          merchantDisplayName: 'Beauty Connect',
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // ✅ Payment succeeded
      print("Payment completed successfully!");
    } catch (e) {
      // Payment failed or canceled
      print("Payment failed or canceled: $e");
      rethrow; // optionally propagate the error
    }
  }

  //fetch merchant account details
  Future<Map<String, dynamic>> fetchMerchantFullInfo(
    String merchantAccountId,
  ) async {
    final res = await Supabase.instance.client.functions.invoke(
      'fetch_merchant',
      body: {'merchant_account_id': merchantAccountId},
    );

    if (res.status != 200) {
      throw Exception('Function failed: ${res.data}');
    }

    // res.data is already a Map<String,dynamic>
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Fetch connected merchant Stripe account ID from accounts table
  Future<String> fetchMerchantAccountId(String merchantUserId) async {
    final response = await supabase
        .from('accounts')
        .select('account_id')
        .eq('user_id', merchantUserId)
        .maybeSingle();

    if (response == null || response['account_id'] == null) {
      throw Exception("No connected Stripe account found for this merchant.");
    }

    return response['account_id'] as String;
  }
}
