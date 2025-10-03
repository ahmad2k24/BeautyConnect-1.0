import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookServiceScreen extends StatefulWidget {
  final Post post; // base service price

  const BookServiceScreen({super.key, required this.post});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedDayIndex = 0;
  TimeOfDay? _selectedTime;

  // generate list of 30 days including today
  List<DateTime> get _days =>
      List.generate(31, (i) => DateTime.now().add(Duration(days: i)));

  String get formattedDate =>
      DateFormat('EEE, MMM d').format(_days[_selectedDayIndex]);

  double get _priceAsDouble => widget.post.price is double
      ? widget.post.price as double
      : double.tryParse(widget.post.price.toString()) ?? 0.0;

  // Platform keeps 15%
  String get serviceCharge => (_priceAsDouble * 0.15).toStringAsFixed(2);

  // Provider gets 85%
  String get providerGets => (_priceAsDouble * 0.85).toStringAsFixed(2);

  Future<void> _pickTime(FormFieldState<TimeOfDay?> state) async {
    final now = TimeOfDay.now();

    final picked = await showTimePicker(context: context, initialTime: now);

    if (picked != null) {
      final selectedDate = _days[_selectedDayIndex];
      final selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        picked.hour,
        picked.minute,
      );

      // Prevent past times for today
      if (DateUtils.isSameDay(selectedDate, DateTime.now()) &&
          selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You cannot select a past time")),
        );
        return;
      }

      setState(() {
        _selectedTime = picked;
      });

      state.didChange(picked); // update form field state
    }
  }

  void _checkout() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewCheckoutScreen(
          post: widget.post,
          bookingDateTime: DateTime(
            _days[_selectedDayIndex].year,
            _days[_selectedDayIndex].month,
            _days[_selectedDayIndex].day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          ),
          price: _priceAsDouble,
          serviceFee: _priceAsDouble * 0.15,
          providerGets: _priceAsDouble * 0.85,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text("Book Service")),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------- DATE PICKER -----------------
              const Text(
                "Select a Date",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: RangeMaintainingScrollPhysics(),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = index == _selectedDayIndex;

                    // Determine colors based on theme & selection
                    final bgColor = isSelected
                        ? (isDark ? Colors.pinkAccent.shade200 : Colors.pink)
                        : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200);

                    final borderColor = isSelected
                        ? (isDark ? Colors.pinkAccent : Colors.pink)
                        : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300);

                    final dayTextColor = isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54);

                    final dateTextColor = isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat("EEE").format(day),
                              style: TextStyle(
                                fontSize: 14,
                                color: dayTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.day.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: dateTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ----------------- TIME PICKER FIELD -----------------
              const Text(
                "Select a Time",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 10),
              FormField<TimeOfDay?>(
                validator: (value) =>
                    value == null ? "Please select a booking time" : null,
                builder: (state) {
                  return InkWell(
                    onTap: () => _pickTime(state),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        errorText: state.errorText,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.pinkAccent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : "Pick a Time",
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedTime != null
                                  ? isDark
                                        ? Colors.white
                                        : Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // ----------------- PAYMENT SUMMARY -----------------
              const Text(
                "Payment Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Service Price",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey : Colors.black54,
                    ),
                  ),
                  Text(
                    "€${_priceAsDouble.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Platform Service Fee (15%)",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey : Colors.black54,
                    ),
                  ),
                  Text(
                    "€$serviceCharge",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Provider Receives",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey : Colors.black54,
                    ),
                  ),
                  Text(
                    "€$providerGets",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              const Divider(), SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total (You Pays)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  Text(
                    "€${_priceAsDouble.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ----------------- CHECKOUT -----------------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _checkout,
            child: const Text(
              "Checkout",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
