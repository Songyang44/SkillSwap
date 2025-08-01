import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/user_profile_page.dart'; 

class SkillSearchPage extends StatefulWidget {
  const SkillSearchPage({Key? key}) : super(key: key);

  @override
  State<SkillSearchPage> createState() => _SkillSearchPageState();
}

class _SkillSearchPageState extends State<SkillSearchPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  Future<void> _searchSkills(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      // 搜索技能
      final skills = await supabase
          .from('skills')
          .select('id, name, level, tags, user_id')
          .ilike('name', '%$query%');

      final List<Map<String, dynamic>> enrichedResults = [];

      for (var skill in skills) {
        final userId = skill['user_id'];
        final user = await supabase
            .from('user')
            .select('id, name, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        if (user != null) {
          enrichedResults.add({
            'skill': skill,
            'user': user,
          });
        }
      }

      setState(() {
        searchResults = enrichedResults;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(color: Colors.blue),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Skills')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search skills...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: _searchSkills,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ] else if (searchResults.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(child: Text('No results')),
          ] else
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final skill = searchResults[index]['skill'];
                  final user = searchResults[index]['user'];

                  final tags = skill['tags'] is List
                      ? List<String>.from(skill['tags'])
                      : <String>[];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: user['avatar_url'] != null
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: user['avatar_url'] == null
                            ? const Icon(Icons.person, size: 28)
                            : null,
                      ),
                      title: Text('${user['name']} - ${skill['name']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Level: ${skill['level'] ?? 'N/A'}'),
                          Wrap(
                            children: tags.map(_buildTag).toList(),
                          ),
                        ],
                      ),
                      onTap: () {
                        final userId = user['id'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(userId: userId),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
