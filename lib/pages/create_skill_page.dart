import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateSkillPage extends StatefulWidget {
  @override
  _CreateSkillPageState createState() => _CreateSkillPageState();
}

class _CreateSkillPageState extends State<CreateSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  final List<String> _tags = [];
  int _level = 3;
  String _newTag = '';

  Future<void> _submitSkill() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please log in first.')));
      return;
    }

    try {
      final result = await Supabase.instance.client.from('skills').insert({
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'icon': _iconController.text.trim(),
        'level': _level,
        'tags': _tags,
      }).select();
      if (result == null) {
        print('❌ 插入失败（无返回）');
      } else {
        print('✅ 插入结果: $result');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Skill added successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Skill')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Skill Name *'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _iconController,
                decoration: InputDecoration(labelText: 'Icon (e.g. 🔧)'),
              ),
              SizedBox(height: 16),
              Text('Skill Level: $_level'),
              Slider(
                value: _level.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_level',
                onChanged: (value) {
                  setState(() => _level = value.toInt());
                },
              ),
              SizedBox(height: 16),
              Text('Tags:'),
              Wrap(
                spacing: 8,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    )
                    .toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(hintText: 'Add a tag'),
                      onChanged: (val) => _newTag = val,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (_newTag.trim().isNotEmpty) {
                        setState(() => _tags.add(_newTag.trim()));
                        _newTag = '';
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitSkill,
                child: Text('Submit Skill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
