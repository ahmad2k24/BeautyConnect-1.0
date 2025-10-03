import 'dart:math';
import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/core/deep_links.dart';
import 'package:beauty_connect/data/data.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantProfile extends StatefulWidget {
  final Vendor vendor;
  const MerchantProfile({super.key, required this.vendor});

  @override
  State<MerchantProfile> createState() => _MerchantProfileState();
}

class _MerchantProfileState extends State<MerchantProfile>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _stripeData;
  Map<String, dynamic>? _merchantDetails;
  final PaymentRepository _paymentRepository = PaymentRepository();

  // Flip animation controller
  late AnimationController _controller;
  bool _showFrontSide = true;
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _fetchStripeDetails();
    _deepLinkService.initDeepLinkListener();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showFrontSide = !_showFrontSide;
  }

  Future<void> _fetchStripeDetails() async {
    setState(() => _loading = true);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _stripeData = null;
      });
      return;
    }

    final response = await supabase
        .from('accounts')
        .select('account_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null && response['account_id'] != null) {
      final details = await fetchMerchantFullInfo(response['account_id']);
      setState(() {
        _stripeData = response;
        _merchantDetails = details;
        _loading = false;
      });
    } else {
      setState(() {
        _stripeData = null;
        _merchantDetails = null;
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchMerchantFullInfo(String accountId) async {
    final res = await Supabase.instance.client.functions.invoke(
      'fetch_merchant',
      body: {'merchant_account_id': accountId},
    );

    if (res.status != 200) {
      throw Exception('Function failed: ${res.data}');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> _createStripeAccount() async {
    setState(() => _loading = true);

    try {
      await _paymentRepository.startVendorOnboarding(
        context: context,
        userId: supabase.auth.currentUser!.id,
        email: widget.vendor.email,
        country: widget.vendor.country,
      );

      await _fetchStripeDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stripe account created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  Future<void> _updateVerifiedStatus(String accountId, bool status) async {
    try {
      await supabase
          .from('accounts')
          .update({'verified': status})
          .eq('account_id', accountId);

      debugPrint(
        "✅ Verified status updated to $status for account: $accountId",
      );
    } catch (e) {
      debugPrint("❌ Error updating verified status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final capabilities =
        _merchantDetails?['capabilities'] as Map<String, dynamic>?;

    final cardPaymentsActive = capabilities?['card_payments'] == 'active';
    final transfersActive = capabilities?['transfers'] == 'active';

    final isEligible = cardPaymentsActive && transfersActive;

    if (!isEligible && _stripeData?['account_id'] != null) {
      // Mark as NOT verified in Supabase
      _updateVerifiedStatus(_stripeData!['account_id'], false);
    } else if (isEligible && _stripeData?['account_id'] != null) {
      // Mark as verified
      _updateVerifiedStatus(_stripeData!['account_id'], true);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Merchant Profile"),
        backgroundColor: AppTheme.primaryPink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: (_stripeData == null || !isEligible)
            ? Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _createStripeAccount,
                  child: const Text(
                    "Create Merchant Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            : _merchantDetails == null
            ? const Center(child: CircularProgressIndicator())
            : _buildMerchantDetails(),
      ),
    );
  }

  Widget _buildMerchantDetails() {
    final balance = _merchantDetails?['balance'] as Map<String, dynamic>?;

    String availableBalance =
        (balance?['available'] != null &&
            (balance!['available'] as List).isNotEmpty)
        ? "${((balance['available'][0]['amount'] as int) / 100).toStringAsFixed(2)} ${balance['available'][0]['currency'].toUpperCase()}"
        : "—";

    String pendingBalance =
        (balance?['pending'] != null &&
            (balance!['pending'] as List).isNotEmpty)
        ? "${((balance['pending'][0]['amount'] as int) / 100).toStringAsFixed(2)} ${balance['pending'][0]['currency'].toUpperCase()}"
        : "—";

    return Column(
      children: [
        // Flip Card
        GestureDetector(
          onTap: _toggleCard,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * pi;
              final isFront = angle < pi / 2;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isFront
                    ? _buildCardFront(availableBalance, pendingBalance)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildCardBack(),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSectionCard("Company Info", Icons.business, [
                  _infoTile(
                    "Name",
                    _merchantDetails?['company']?['name'] == true
                        ? "Provided"
                        : "Not Provided",
                  ),
                  _infoTile(
                    "Tax ID",
                    _merchantDetails?['company']?['tax_id_provided'] == true
                        ? "Provided"
                        : "Not Provided",
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard("Individual Info", Icons.person, [
                  _infoTile(
                    "First Name",
                    _merchantDetails?['individual']?['first_name'],
                  ),
                  _infoTile(
                    "Last Name",
                    _merchantDetails?['individual']?['last_name'],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard("Capabilities", Icons.verified, [
                  if ((_merchantDetails?['capabilities'] ?? {}).isEmpty)
                    const ListTile(title: Text("No capabilities found"))
                  else
                    ...(_merchantDetails?['capabilities']
                            as Map<String, dynamic>)
                        .entries
                        .map(
                          (e) => ListTile(
                            leading: Icon(
                              e.value == "active"
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: e.value == "active"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(e.key),
                            trailing: Text(e.value.toString()),
                          ),
                        ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(String available, String pending) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPink, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Merchant Balance",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            Text(
              "Available: $available",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Pending: $pending",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "Tap to flip →",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Merchant Account",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            Text(
              "ID: ${_merchantDetails?['id'] ?? '—'}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Email: ${_merchantDetails?['email'] ?? '—'}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Country: ${_merchantDetails?['country'] ?? '—'}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "Tap to flip →",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryPink),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(value?.toString() ?? "—"),
    );
  }
}
