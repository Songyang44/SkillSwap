import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/signin_page.dart';
import '../models/user.dart';
import '../pages/create_skill_page.dart';
import '../widgets/skill_card.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userInfo;
  List<Skill> skills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('user')
          .select()
          .eq('id', user.id)
          .single();

      final skillRes = await Supabase.instance.client
          .from('skills')
          .select()
          .eq('user_id', user.id);

      final skillList = (skillRes as List)
          .map((s) => Skill.fromJson(s as Map<String, dynamic>))
          .toList();

      setState(() {
        userInfo = response;
        skills = skillList;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to fetch user info or skills: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('user')
          .update({'name': newUsername})
          .eq('id', user.id);

      await fetchUserInfo();
    } catch (e) {
      print('❌ Failed to update username: $e');
    }
  }

  Future<void> updateLocationFromDevice() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 请求权限
    final permission = await Permission.location.request();
    if (!permission.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location permission is required to obtain the location')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.first;
      final city = placemark.locality ?? placemark.subAdministrativeArea;
      final country = placemark.country;

      final locationStr = [city, country].where((s) => s != null).join(', ');

      await Supabase.instance.client
          .from('user')
          .update({'location': locationStr})
          .eq('id', user.id);

      await fetchUserInfo(); // 刷新 UI

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location updated to $locationStr')));
    } catch (e) {
      print('❌ Failed to obtain location: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Positioning failed: $e')));
    }
  }

  void showEditUsernameDialog() {
    final controller = TextEditingController(text: userInfo?['name'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'New Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await updateUsername(controller.text.trim());
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    setState(() {
      userInfo = null;
      skills = [];
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final storagePath = 'avatars/$fileName';

    final fileBytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';

    try {
      final storage = Supabase.instance.client.storage;
      await storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = storage.from('avatars').getPublicUrl(storagePath);

      await Supabase.instance.client
          .from('user')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      await fetchUserInfo();
      print(' Upload Path: $storagePath');
    } catch (e) {
      print('❌ Failed to upload avatar: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload avatar: $e')));
    }
  }

  Widget _buildProfileContent() {
    final user = Supabase.instance.client.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _pickAndUploadAvatar,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: userInfo?['avatar_url'] != null
                ? NetworkImage(userInfo!['avatar_url'])
                : null,
            backgroundColor: Colors.grey.shade200,
            child: userInfo?['avatar_url'] == null
                ? Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userInfo?['name'] ?? 'Anonymous',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 18),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: showEditUsernameDialog,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userInfo?['location']?.toString().isNotEmpty == true
                  ? userInfo!['location']
                  : '未知',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 18),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: updateLocationFromDevice,
            ),
          ],
        ),

        const SizedBox(height: 32),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: skills.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200,
                child: SkillCard(skill: skills[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateSkillPage()),
                );
                fetchUserInfo();
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade100,
                child: Icon(Icons.add, size: 32, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Skill',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Not logged in')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please log in to view your personal information'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Text('Log in'),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(userInfo?['name'] ?? 'Profile'),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: signOut)],
      ),
      body: RefreshIndicator(
        onRefresh: fetchUserInfo,
        child: _buildProfileContent(),
      ),
    );
  }
}
