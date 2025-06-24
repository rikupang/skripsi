import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../service/get_user_profile.dart';
import 'edit_profile_screen.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool hasLoadedOnce = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final Color tealColor = const Color(0xFF009688);
  final Color lightTealColor = const Color(0xFFE0F2F1);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        isLoading = true;
      });
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final profile = await fetchUserProfile(uid);
      setState(() {
        userData = profile;
        isLoading = false;
        hasLoadedOnce = true;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadProfileData(isRefresh: true);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && !hasLoadedOnce) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFoldingCube(
            color: tealColor,
            size: 50.0,
          ),
        ),
      );
    }

    if (userData == null && hasLoadedOnce) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          color: tealColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load profile',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          color: tealColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile Header Section with Curved Background
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Teal background with wave shape
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: tealColor,
                      ),
                    ),
                    // White curved shape
                    Positioned(
                      bottom: -1,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                      ),
                    ),
                    // Profile picture
                    Positioned(
                      bottom: -20,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: lightTealColor,
                              backgroundImage: userData!['profilePictureUrl'] != null
                                  ? NetworkImage(userData!['profilePictureUrl'])
                                  : null,
                              child: userData!['profilePictureUrl'] == null
                                  ? Icon(Icons.person, size: 65, color: tealColor.withOpacity(0.6))
                                  : null,
                            ),
                            Positioned(
                              bottom: 3,
                              right: 3,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: tealColor, width: 2),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: tealColor,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Name and username section
                Container(
                  margin: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Text(
                        userData!['fullName'] ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${userData!['username'] ?? 'username'} ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '| ${userData!['phone'] ?? '+01 234 567 89'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Profile Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileItem(Icons.email_outlined, "Email", userData!['email']),
                      _buildProfileItem(Icons.cake_outlined, "Age", userData!['age']),
                      _buildProfileItem(Icons.person_outline, "Gender", userData!['gender']),
                      _buildProfileItem(Icons.phone_outlined, "Phone", userData!['phone']),
                      _buildProfileItem(Icons.location_on_outlined, "Address", userData!['address']),
                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfilePage(userData: userData!),
                                  ),
                                );
                                await _loadProfileData(isRefresh: true); // Refresh after return
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: tealColor,
                                backgroundColor: Colors.white,
                                elevation: 0,
                                side: BorderSide(color: tealColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                "Edit Profile",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: tealColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                "Logout",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightTealColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: tealColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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