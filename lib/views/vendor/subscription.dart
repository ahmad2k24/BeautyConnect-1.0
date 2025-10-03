import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beauty_connect/data/repositories/payment_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isDark;

  const SubscriptionScreen({super.key, this.isDark = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? subscriptionData;
  bool loading = true;
  final SupabaseClient _client = Supabase.instance.client;
  final PaymentRepository paymentRepository = PaymentRepository();

  @override
  void initState() {
    super.initState();
    fetchSubscription();
  }

  Future<void> fetchSubscription() async {
    setState(() {
      loading = true;
    });

    final userId = _client.auth.currentUser!.id;

    try {
      final response = await _client
          .from('subscriptions')
          .select('subscription_id, subscription_expiry, status')
          .eq('user_id', userId)
          .order('subscription_expiry', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        setState(() {
          subscriptionData = null;
          loading = false;
        });
        return;
      }

      final data = response;
      String rawStatus = (data['status'] ?? '').toString().toLowerCase();

      final expiryDate = DateTime.parse(data['subscription_expiry']).toUtc();
      final now = DateTime.now().toUtc();

      int remainingDays = expiryDate.isAfter(now)
          ? expiryDate.difference(now).inDays
          : 0;

      String displayStatus;
      if (rawStatus == 'pending') {
        displayStatus = 'Pending';
      } else if (rawStatus == 'active' && remainingDays > 0) {
        displayStatus = 'Active';
      } else {
        displayStatus = 'Expired';
      }

      setState(() {
        subscriptionData = {
          'title': 'Premium 5€ Subscription',
          'description': 'Access all premium features for 30 days.',
          'price': '5€',
          'duration': '30 days',
          'status': displayStatus,
          'remaining_days': remainingDays,
          'subscription_id': data['subscription_id'],
        };
        loading = false;
      });
    } catch (e) {
      print('Error fetching subscription: $e');
      setState(() {
        subscriptionData = null;
        loading = false;
      });
    }
  }

  Future<void> cancelSubscription() async {
    final userId = _client.auth.currentUser!.id;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Update status in Supabase
      await _client
          .from('subscriptions')
          .update({'status': 'canceled', 'expired': true})
          .eq('user_id', userId);

      // Refresh subscription
      await fetchSubscription();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription canceled successfully')),
      );
    } catch (e) {
      print('Error canceling subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel subscription')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.pinkAccent;
    final bgColor = widget.isDark ? Colors.grey[900] : Colors.grey[100];
    final cardColor = widget.isDark ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.grey[900];
    final subtitleColor = widget.isDark ? Colors.grey[300] : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscriptionData?['title'] ?? 'No Subscription',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subscriptionData?['description'] ??
                                'No active subscription.',
                            style: TextStyle(
                              fontSize: 16,
                              color: subtitleColor,
                            ),
                          ),
                          if (subscriptionData != null) ...[
                            const SizedBox(height: 24),
                            _buildDetailRow(
                              label: 'Price:',
                              value: subscriptionData!['price'],
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              label: 'Duration:',
                              value: subscriptionData!['duration'],
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              label: 'Remaining Days:',
                              value: subscriptionData!['remaining_days']
                                  .toString(),
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            ),
                            const SizedBox(height: 12),
                            _buildStatusRow(
                              status: subscriptionData!['status'],
                              isDark: widget.isDark,
                            ),
                            const SizedBox(height: 24),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final status = subscriptionData?['status'];
                                final userId = _client.auth.currentUser!.id;

                                if (status == 'Active') {
                                  // Call cancel subscription
                                  await cancelSubscription();
                                } else {
                                  // Subscribe
                                  await paymentRepository.buy5EuroSubscription(
                                    userId: userId,
                                  );
                                  await fetchSubscription();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                subscriptionData?['status'] == 'Active'
                                    ? 'Cancel Subscription'
                                    : 'Subscribe Now',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color? textColor,
    required Color? subtitleColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({required String status, required bool isDark}) {
    final statusColor = status == 'Active'
        ? Colors.greenAccent[400]
        : status == 'Pending'
        ? Colors.orangeAccent[400]
        : Colors.redAccent[400];
    final textColor = status == 'Active'
        ? Colors.green[800]
        : status == 'Pending'
        ? Colors.orange[800]
        : Colors.red[800];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Status:',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            status,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
