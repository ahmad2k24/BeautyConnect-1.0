import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/data/data.dart';
import 'package:uuid/uuid.dart';

class ViewServiceScreen extends StatefulWidget {
  final Post post;
  const ViewServiceScreen({super.key, required this.post});

  @override
  State<ViewServiceScreen> createState() => _ViewServiceScreenState();
}

class _ViewServiceScreenState extends State<ViewServiceScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final ServiceRepository _serviceRepo = ServiceRepository();
  final ChatRepository _chatRepo = ChatRepository(
    supabase: SupabaseConfig.client,
  );

  final String vendorProfilePic =
      "https://i.pravatar.cc/150?img=47"; // Dummy profile picture

  final String userId = SupabaseConfig.client.auth.currentUser!.id;

  Vendor? vendorProfile;
  Client? clientProfile;
  Future<void> _fetchVendorProfile() async {
    try {
      vendorProfile = await _serviceRepo.fetchVendorProfile(
        widget.post.vendorId,
      );
      setState(() {});
    } catch (e) {
      print("Error fetching vendor profile: $e");
    }
  }

  Future<void> _fetchClientProfile() async {
    try {
      clientProfile = await _serviceRepo.fetchClientProfile(userId);
      setState(() {});
    } catch (e) {
      print("Error fetching client profile: $e");
    }
  }

  @override
  void initState() {
    _fetchVendorProfile();
    _fetchClientProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------- Main Content ----------
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Image Slider ----------
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.post.images?.length ?? 0,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.post.images![index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_currentPage + 1} / ${widget.post.images?.length ?? 0}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // About Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            // ---------- Vendor Info as ListTile ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListTile(
                onTap: () {},
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    vendorProfile?.vendorUrl ??
                        'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(
                  vendorProfile?.name ?? 'Unknown Vendor',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        vendorProfile?.address ?? 'No address provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---------- Vendor Services ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Available Services",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            StreamBuilder(
              stream: _serviceRepo.streamVendorPosts(widget.post.vendorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final vendorServices = snapshot.data ?? [];
                if (vendorServices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No services available.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: vendorServices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final service = vendorServices[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.pink.withOpacity(0.3),
                          ),
                          right: BorderSide(
                            color: Colors.pink.withOpacity(0.3),
                          ),
                          left: BorderSide(color: Colors.pink.withOpacity(0.3)),
                          top: BorderSide(color: Colors.pink.withOpacity(0.3)),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.post.images != null &&
                                        widget.post.images!.isNotEmpty
                                    ? widget.post.images!.first
                                    : 'https://via.placeholder.com/150',
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          service.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        ),
                        subtitle: Text(
                          widget.post.description,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          '€ ${service.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),

      // ---------- Bottom Buttons ----------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    _showContactBottomSheet(context);
                  },
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text(
                    "Contact",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookServiceScreen(post: widget.post),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: const Text(
                    "Book Service",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- Method to show Cupertino Bottom Sheet -------------------
  void _showContactBottomSheet(BuildContext context) {
    final messages = [
      "Hi! I would like to book an appointment.",
      "Hello, can I know your availability this week?",
      "I want to inquire about your services and pricing.",
      "Can I reschedule my appointment?",
      "Do you have any promotions or offers currently?",
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text(
          "Start a Conversation",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        message: const Text("Select a message to send"),
        actions: messages.map((msg) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              if (clientProfile == null || vendorProfile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Client profile not loaded yet."),
                  ),
                );
                return;
              }
              Chat? existing = await _chatRepo.findThread(
                clientProfile!.id,
                widget.post.vendorId,
              );

              if (existing != null) {
                // Navigate if thread already exists
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessageScreen(
                      otherUserId: widget.post.vendorId,
                      currentUserId: clientProfile!.id,
                    ),
                  ),
                );
              } else {
                // Create new thread

                final chat = Chat(
                  id: Uuid().v4(),
                  user1: clientProfile!.id,
                  user2: widget.post.vendorId,
                  createdAt: DateTime.now(),
                  user1Name: clientProfile!.name,
                  user2Name: vendorProfile!.name,
                  user1Avatar: clientProfile!.clientUrl!,
                  user2Avatar: vendorProfile!.vendorUrl!,
                );
                final newThread = await _chatRepo.getOrCreateThread(
                  userA: clientProfile!.id,
                  userB: widget.post.vendorId,
                  chat: chat,
                );

                // Send an initial placeholder message
                await _chatRepo.sendMessage(
                  chatId: newThread.id,
                  senderId: clientProfile!.id,
                  content: msg,
                );

                // Then navigate
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessageScreen(
                      otherUserId: widget.post.vendorId,
                      currentUserId: clientProfile!.id,
                    ),
                  ),
                );
              }

              print("Selected message: $msg");
            },
            child: Text(
              msg,
              style: const TextStyle(color: Colors.pinkAccent, fontSize: 14),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
