import 'package:beauty_connect/data/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorAppointments extends StatefulWidget {
  const VendorAppointments({super.key});

  @override
  State<VendorAppointments> createState() => _VendorAppointmentsState();
}

class _VendorAppointmentsState extends State<VendorAppointments> {
  final BookingRepository bookingRepo = BookingRepository();

  final ServiceRepository serviceRepo = ServiceRepository();

  String selectedStatusFilter = "All"; // Default filter

  final List<String> statusFilters = [
    "All",
    "Pending",
    "Active",
    "Canceled",
    "Completed",
  ];

  // Fetch client profile
  Future<Client?> fetchClientProfile(String clientId) async {
    try {
      final response = await serviceRepo.fetchClientProfile(clientId);
      return response;
    } catch (e) {
      debugPrint("Error fetching client profile: $e");
      return null;
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(Booking booking, String newStatus) async {
    try {
      await bookingRepo.updateBookingStatus(booking.id!, newStatus);
      setState(() {}); // Refresh UI
    } catch (e) {
      debugPrint("Error updating booking status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
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
                      side: const BorderSide(color: Colors.pinkAccent),
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
              stream: bookingRepo.streamVendorBookings(),
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

                    return FutureBuilder<Client?>(
                      future: fetchClientProfile(booking.clientId),
                      builder: (context, clientSnapshot) {
                        final client = clientSnapshot.data;
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

                                          // ---------------- Client Info ----------------
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundImage:
                                                    client != null &&
                                                        client.clientUrl != null
                                                    ? NetworkImage(
                                                        client.clientUrl!,
                                                      )
                                                    : null,
                                                child:
                                                    client == null ||
                                                        client.clientUrl == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        size: 28,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      client?.name ?? "Client",
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .pinkAccent,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      client?.address ??
                                                          "Address not available",
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: isDark
                                                                ? Colors
                                                                      .grey[300]
                                                                : Colors
                                                                      .grey[700],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Date & Time Row
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
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ---------------- Status chip tappable ----------------
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoActionSheet(
                                            title: const Text("Update Status"),
                                            actions: [
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  updateBookingStatus(
                                                    booking,
                                                    "Active",
                                                  );
                                                },
                                                child: const Text("Active"),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  updateBookingStatus(
                                                    booking,
                                                    "Pending",
                                                  );
                                                },
                                                child: const Text("Pending"),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  updateBookingStatus(
                                                    booking,
                                                    "Completed",
                                                  );
                                                },
                                                child: const Text("Completed"),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  updateBookingStatus(
                                                    booking,
                                                    "Canceled",
                                                  );
                                                },
                                                child: const Text("Canceled"),
                                              ),
                                            ],
                                            cancelButton:
                                                CupertinoActionSheetAction(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("Cancel"),
                                                ),
                                          ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          booking.status.toLowerCase() ==
                                              'pending'
                                          ? Colors.orange.withOpacity(0.2)
                                          : booking.status.toLowerCase() ==
                                                'completed'
                                          ? Colors.green.withOpacity(0.2)
                                          : booking.status.toLowerCase() ==
                                                'active'
                                          ? Colors.blue.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      border: Border.all(
                                        color:
                                            booking.status.toLowerCase() ==
                                                'pending'
                                            ? Colors.orange
                                            : booking.status.toLowerCase() ==
                                                  'completed'
                                            ? Colors.green
                                            : booking.status.toLowerCase() ==
                                                  'active'
                                            ? Colors.blue
                                            : Colors.red,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      booking.status,
                                      style: TextStyle(
                                        color:
                                            booking.status.toLowerCase() ==
                                                'pending'
                                            ? Colors.orange.shade800
                                            : booking.status.toLowerCase() ==
                                                  'completed'
                                            ? Colors.green.shade800
                                            : booking.status.toLowerCase() ==
                                                  'active'
                                            ? Colors.blue.shade800
                                            : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
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
