import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/switcher/client_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PreviewCheckoutScreen extends StatefulWidget {
  final Post post;
  final DateTime bookingDateTime;
  final double price;
  final double serviceFee;
  final double providerGets;

  const PreviewCheckoutScreen({
    super.key,
    required this.post,
    required this.bookingDateTime,
    required this.price,
    required this.serviceFee,
    required this.providerGets,
  });

  @override
  State<PreviewCheckoutScreen> createState() => _PreviewCheckoutScreenState();
}

class _PreviewCheckoutScreenState extends State<PreviewCheckoutScreen> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final date = DateFormat("EEE, MMM d, yyyy").format(widget.bookingDateTime);
    final time = DateFormat("hh:mm a").format(widget.bookingDateTime);

    final PaymentRepository paymentRepo = PaymentRepository();
    final BookingRepository bookingRepo = BookingRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout Preview"),
        backgroundColor: isDark ? Colors.black : Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.6)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  color: isDark
                      ? Colors.pinkAccent.shade100
                      : Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      "Receipt",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vendor Details
                      Text(
                        "Vendor Details",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildRow("Name", widget.post.vendorName, theme),
                      _buildRow("Duration", widget.post.duration, theme),

                      const SizedBox(height: 12),

                      // Booking Details
                      Text(
                        "Booking Details",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow("Date", date, theme),
                      _buildRow("Time", time, theme),

                      const SizedBox(height: 20),
                      Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),

                      // Payment Summary
                      Text(
                        "Payment Summary",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        "Service Price",
                        "€${widget.price.toStringAsFixed(2)}",
                        theme,
                        faded: true,
                      ),
                      _buildRow(
                        "Platform Fee (15%)",
                        "€${widget.serviceFee.toStringAsFixed(2)}",
                        theme,
                        faded: true,
                      ),
                      _buildRow(
                        "Provider Receives",
                        "€${widget.providerGets.toStringAsFixed(2)}",
                        theme,
                        faded: true,
                      ),

                      const SizedBox(height: 8),
                      Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      _buildRow(
                        "Total (You Pay)",
                        "€${widget.price.toStringAsFixed(2)}",
                        theme,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Proceed Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              final SupabaseClient client = Supabase.instance.client;
              if (client.auth.currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User not logged in.")),
                );
                return;
              }
              final String bookingId = Uuid().v4();
              final booking = Booking(
                id: bookingId,
                clientId: client.auth.currentUser!.id,
                vendorId: widget.post.vendorId,
                service: widget.post.title,
                description: widget.post.description,
                price: widget.post.price,
                duration: widget.post.duration,
                status: 'Pending',
              );
              final String merchantId = await paymentRepo
                  .fetchMerchantAccountId(widget.post.vendorId);

              final int amountInCents = (widget.price * 100).round();
              if (merchantId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Merchant account not found. Cannot proceed with payment.",
                    ),
                  ),
                );
                return;
              }
              await paymentRepo.payMerchant(
                amountInCents: amountInCents,
                currency: 'eur',
                merchantAccountId: merchantId,
              );

              await bookingRepo.createBooking(booking);
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ClientLayout()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Booking confirmed!")),
                );
              }
            },
            child: isLoading
                ? SizedBox(
                    height: 15,
                    width: 15,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    "Proceed to Payment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    ThemeData theme, {
    bool faded = false,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: faded ? Colors.grey : theme.colorScheme.onSurface,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: faded ? Colors.grey : theme.colorScheme.onSurface,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
