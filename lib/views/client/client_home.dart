import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  final ServiceRepository _serviceRepo = ServiceRepository();

  // Define available services (replace with dynamic fetch if needed)
  final List<String> _services = [
    'Haircut',
    'Manicure',
    'Pedicure',
    'Facial',
    'Massage',
    'Makeup',
    'Waxing',
    'Styling',
  ];

  late final Stream<List<Post>> _postStream;
  final double _maxPrice = 100;
  final double _maxDuration = 60;

  String _search = '';

  double? _selectedMaxPrice;
  double? _selectedMaxDuration;
  List<String> _selectedServices = [];
  void _resetFilters() {
    setState(() {
      _selectedMaxPrice = null;
      _selectedMaxDuration = null;
      _selectedServices = [];
      _search = '';
    });
  }

  void _openCupertinoFilterMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Filter By"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openPriceFilter();
            },
            child: const Text("Price"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openDurationFilter();
            },
            child: const Text("Duration"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openServiceFilter();
            },
            child: const Text("Services"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _resetFilters();
            },
            child: const Text("Reset Filters"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDefaultAction: true,
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  /// Price Filter
  void _openPriceFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Filter by Price"),
        message: Text("Up to €${_maxPrice.toStringAsFixed(0)}"),
        actions: List.generate(5, (i) {
          final price = (i + 1) * 100;
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedMaxPrice = price.toDouble();
              });
              Navigator.pop(ctx);
            },
            child: Text("≤ €$price"),
          );
        }),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDefaultAction: true,
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  /// Duration Filter
  void _openDurationFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Filter by Duration"),
        message: Text("Up to ${_maxDuration.toStringAsFixed(0)} minutes"),
        actions: [30, 60, 90, 120].map((min) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedMaxDuration = min.toDouble();
              });
              Navigator.pop(ctx);
            },
            child: Text("≤ $min minutes"),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDefaultAction: true,
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  /// Service Filter
  void _openServiceFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Filter by Services"),
        message: const Text("Select one service"),
        actions: _services.map((service) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedServices = [service];
              });
              Navigator.pop(ctx);
            },
            child: Text(service),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDefaultAction: true,
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _postStream = _serviceRepo.streamAllPosts(
      SupabaseConfig.client.auth.currentUser!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themePink = Colors.pinkAccent;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: StreamBuilder(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No services available"));
          }

          List<Post> filtered = snapshot.data!.where((s) {
            final query = _search.toLowerCase();
            return s.title.toLowerCase().contains(query) ||
                s.vendorName.toLowerCase().contains(query) ||
                s.services.any((srv) => srv.toLowerCase().contains(query));
          }).toList();

          if (_selectedMaxPrice != null) {
            filtered = filtered
                .where(
                  (p) => (double.tryParse(p.price) ?? 0) <= _selectedMaxPrice!,
                )
                .toList();
          }

          if (_selectedMaxDuration != null) {
            filtered = filtered
                .where(
                  (p) =>
                      (double.tryParse(p.duration.toString()) ?? 0) <=
                      _selectedMaxDuration!,
                )
                .toList();
          }

          if (_selectedServices.isNotEmpty) {
            filtered = filtered
                .where(
                  (p) => p.services.any((s) => _selectedServices.contains(s)),
                )
                .toList();
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                expandedHeight: 120,
                title: Text(
                  "Beauty Connect",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.primaryPink : Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _openCupertinoFilterMenu,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Material(
                      color: Colors.transparent,
                      child: TextField(
                        onChanged: (val) => setState(() => _search = val),
                        decoration: InputDecoration(
                          labelText: 'Search services...',
                          labelStyle: const TextStyle(color: Colors.white),
                          suffixIcon: Icon(
                            CupertinoIcons.search,
                            color: isDark ? themePink : Colors.white,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppTheme.primaryPink,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              filtered.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          "No services matched",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final post = filtered[i];
                          return _ServiceCard(
                            title: post.title,
                            vendor: post.vendorName,
                            price: post.price,
                            imageUrl:
                                post.images != null && post.images!.isNotEmpty
                                ? post.images!.first
                                : 'https://via.placeholder.com/150',
                            services: post.services,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewServiceScreen(post: post),
                              ),
                            ),
                          );
                        }, childCount: filtered.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              childAspectRatio: 0.75,
                            ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String vendor;
  final String price;
  final String imageUrl;
  final List<String> services; // ✅ New field
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.vendor,
    required this.price,
    required this.imageUrl,
    required this.services, // ✅ New field
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themePink = Colors.pinkAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Price badge
            Stack(
              children: [
                // Service image
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: ClipRRect(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),

                // Price badge
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themePink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "€$price",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vendor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // ✅ spacing before services
                  Wrap(
                    spacing: 6,
                    runSpacing: -8,
                    children: services.take(2).map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: themePink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: themePink, width: 0.8),
                        ),
                        child: Text(
                          service,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: themePink,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
