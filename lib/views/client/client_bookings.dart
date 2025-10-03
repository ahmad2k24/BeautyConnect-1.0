import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientBookings extends StatefulWidget {
  const ClientBookings({super.key});

  @override
  State<ClientBookings> createState() => _ClientBookingsState();
}

class _ClientBookingsState extends State<ClientBookings> {
  final BookingRepository bookingRepo = BookingRepository();

  String selectedStatusFilter = "All"; // Default filter

  final List<String> statusFilters = [
    "All",
    "Pending",
    "Active",
    "Canceled",
    "Completed",
    "Reviewed",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: isDark ? Colors.black : Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ------------------- Filter Chips -------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: statusFilters.map((status) {
                final isSelected = selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.pinkAccent,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.pinkAccent),
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedStatusFilter = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ------------------- Bookings List -------------------
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: bookingRepo.streamUserBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No bookings yet"));
                }

                // Apply filter locally
                final filteredBookings = snapshot.data!.where((booking) {
                  if (selectedStatusFilter == "All") return true;
                  return booking.status.toLowerCase() ==
                      selectedStatusFilter.toLowerCase();
                }).toList();

                if (filteredBookings.isEmpty) {
                  return const Center(
                    child: Text("No bookings match the filter"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    final bookingDateTime = booking.createdAt ?? DateTime.now();
                    final date = DateFormat(
                      'EEE, MMM d, yyyy',
                    ).format(bookingDateTime);
                    final time = DateFormat('hh:mm a').format(bookingDateTime);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? Colors.grey[900] : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black54
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              // Pink accent bar
                              Container(
                                width: 6,
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                              ),

                              // Card content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        booking.service,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.pinkAccent,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        booking.description,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildLabelValue(
                                            "Date",
                                            date,
                                            theme,
                                            isDark,
                                          ),
                                          _buildLabelValue(
                                            "Time",
                                            time,
                                            theme,
                                            isDark,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildLabelValue(
                                            "Price",
                                            "€${booking.price}",
                                            theme,
                                            isDark,
                                          ),
                                          _buildLabelValue(
                                            "Duration",
                                            booking.duration,
                                            theme,
                                            isDark,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),

                                      // ------------------- Review Button -------------------
                                      if (booking.status.toLowerCase() ==
                                          "completed")
                                        Align(
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: 350, // set desired width
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        WriteReviewScreen(
                                                          clientId:
                                                              booking.clientId,
                                                          vendorId:
                                                              booking.vendorId,
                                                          postId: booking.id!,
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.pinkAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                minimumSize: const Size.fromHeight(
                                                  45,
                                                ), // optional: increase height
                                              ),
                                              child: const Text("Write Review"),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Positioned widget should be a child of Stack, not Column
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: booking.status.toLowerCase() == 'pending'
                                    ? Colors.orange.withOpacity(0.2)
                                    : booking.status.toLowerCase() ==
                                          'completed'
                                    ? Colors.green.withOpacity(0.2)
                                    : booking.status.toLowerCase() == 'reviewed'
                                    ? Colors.indigoAccent.withOpacity(.2)
                                    : Colors.red.withOpacity(0.2),
                                border: Border.all(
                                  color:
                                      booking.status.toLowerCase() == 'pending'
                                      ? Colors.orange
                                      : booking.status.toLowerCase() ==
                                            'completed'
                                      ? Colors.green
                                      : booking.status.toLowerCase() ==
                                            'reviewed'
                                      ? Colors.indigoAccent
                                      : Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                booking.status,
                                style: TextStyle(
                                  color:
                                      booking.status.toLowerCase() == 'pending'
                                      ? Colors.orange.shade800
                                      : booking.status.toLowerCase() ==
                                            'completed'
                                      ? Colors.green.shade800
                                      : booking.status.toLowerCase() ==
                                            'reviewed'
                                      ? Colors.indigoAccent
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(
    String label,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
