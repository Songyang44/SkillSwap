import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_swap/pages/home_page.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _communicationDetailController =
      TextEditingController();

  final List<String> skillsIHaves = ['Flutter', 'Firebase', 'Figma'];
  final List<String> skillsIWant = ['Node.js', 'UI/UX', 'Rust'];

  List<String> selectedIHaves = [];
  List<String> selectedIWant = [];

  String communicationMethod = 'online';
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final fileBytes = await image.readAsBytes();
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      final storagePath = 'posts/$userId/$fileName';

      final storage = Supabase.instance.client.storage;
      await storage
          .from('postimages')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = storage.from('postimages').getPublicUrl(storagePath);
      print('✅ 上传成功，URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ 上传失败: $e');
      return null;
    }
  }

  void toggleTag(List<String> selected, String tag) {
    setState(() {
      if (selected.contains(tag)) {
        selected.remove(tag);
      } else {
        selected.add(tag);
      }
    });
  }

  Widget buildTag(String tag, List<String> selected, VoidCallback onTap) {
    final isSelected = selected.contains(tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildSkillSection(
    String title,
    List<String> tags,
    List<String> selected, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isRequired) Text('*', style: TextStyle(color: Colors.red)),
          ],
        ),
        Wrap(
          children: tags
              .map(
                (tag) =>
                    buildTag(tag, selected, () => toggleTag(selected, tag)),
              )
              .toList(),
        ),
        TextButton.icon(
          onPressed: () => addCustomTag(
            tagList: tags,
            selectedList: selected,
            title: title,
            onChanged: () {},
          ),
          icon: Icon(Icons.add, color: Colors.blue),
          label: Text('Custom', style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }

  Widget buildCommunicationOption(String label, String value) {
    final isSelected = communicationMethod == value;
    return GestureDetector(
      onTap: () => setState(() => communicationMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> buildPostData(String? imageUrl) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please login first')));
      return null;
    }

    final response = await Supabase.instance.client
        .from('user')
        .select()
        .eq('id', user.id)
        .single();

    final userInfo = response as Map<String, dynamic>;
    print('✅ userInfo fetched: $userInfo');

    return {
      'user_id': userInfo['id'],
      'username': userInfo['name'],
      'location': userInfo['location'],
      'avatar_url': userInfo['avatar_url'],
      'description': _descriptionController.text.trim(),
      'skills_i_have': selectedIHaves,
      'skills_i_want': selectedIWant,
      'communication_method': communicationMethod,
      'communication_detail': _communicationDetailController.text.trim(),
      'images': imageUrl != null ? [imageUrl] : null,
    };
  }

  Future<void> handleSubmit({bool isDraft = false}) async {
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await uploadImage(_selectedImage!);
    }

    final data = await buildPostData(imageUrl);
    if (data == null) return;

    try {
      await Supabase.instance.client.from('posts').insert({
        ...data,
        'images': imageUrl != null ? [imageUrl] : [], // ✅ 强制为数组
        'is_draft': isDraft,
        'created_at': DateTime.now().toIso8601String(), // ✅ 可选：若数据库已默认值
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Draft saved' : 'Published successfully'),
        ),
      );

      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => HomePage()),
      //   (route) => false,
      // );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    }
  }

  Future<void> addCustomTag({
    required List<String> tagList,
    required List<String> selectedList,
    required String title,
    required VoidCallback onChanged,
  }) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add custom $title tag'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter custom skill'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTag = controller.text.trim();
              if (newTag.isNotEmpty && !tagList.contains(newTag)) {
                setState(() {
                  tagList.add(newTag);
                  selectedList.add(newTag);
                });
                onChanged();
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skill show',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Center(
                        child: Icon(Icons.add, size: 40, color: Colors.grey),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Details *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'e.g. I built a small AI image recognition project in Flutter...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            buildSkillSection(
              'What I can *',
              skillsIHaves,
              selectedIHaves,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            buildSkillSection(
              'What I want *',
              skillsIWant,
              selectedIWant,
              isRequired: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Contact *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildCommunicationOption('Online', 'online'),
                buildCommunicationOption('Offline', 'offline'),
                buildCommunicationOption('Both', 'both'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _communicationDetailController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'like Zoom link: https://...\nor meet at XX Cafe 2pm every Sunday',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => handleSubmit(isDraft: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save as draft',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => handleSubmit(isDraft: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Publish'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
