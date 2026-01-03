import 'package:flutter/material.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:mydiary/calendar_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final _otherFeelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final FocusNode _otherFeelFocus = FocusNode();
  final List<String> _feelings = ['Happy', 'Sad', 'Excited', 'Angry', 'Anxious', 'Calm', 'Other'];
  String? _selectedFeeling;

  List<Map<String, dynamic>> _allDiaries = [];
  List<Map<String, dynamic>> _diaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _otherFeelCtrl.dispose();
    _descCtrl.dispose();
    _otherFeelFocus.dispose();
    super.dispose();
  }
// Inside homepage.dart
  // Fetch all diaries from the database
  Future<void> _refresh() async {
    _allDiaries = await SQLHelper.getDiaries();
    setState(() {
      _diaries = _allDiaries;
      _loading = false;
    });
  }

// Inside homepage.dart
  // Pick an image using the camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

// Inside homepage.dart
  // Start voice recognition for diary input
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'listening') setState(() => _isListening = true);
        if (status == 'notListening' || status == 'done') setState(() => _isListening = false);
      },
      onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech error: ${e.toString()}')));
      },
    );
    if (available) {
      try {
        _speech.listen(onResult: (result) {
          setState(() {
            _descCtrl.text = result.recognizedWords;
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech listen failed: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available or permission denied')));
    }
  }

  // Stop voice recognition
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // Show form for new or update diary
  Future<void> _showForm([int? id]) async {
    if (id != null) {
      final e = await SQLHelper.getDiary(id);
      final feeling = e['feeling'] as String? ?? '';
      if (_feelings.contains(feeling)) {
        _selectedFeeling = feeling;
        _otherFeelCtrl.text = '';
      } else {
        _selectedFeeling = 'Other';
        _otherFeelCtrl.text = feeling;
      }
      _descCtrl.text = e['description'] ?? '';
      _image = (e['image_path'] != null && (e['image_path'] as String).isNotEmpty) ? File(e['image_path']) : null;
    } else {
      _selectedFeeling = null;
      _otherFeelCtrl.clear();
      _descCtrl.clear();
      _image = null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(id == null ? 'New Entry' : 'Update Entry', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedFeeling,
                items: _feelings.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() {
                  _selectedFeeling = v;
                  if (v == 'Other') {
                    _otherFeelCtrl.clear();
                    Future.microtask(() => _otherFeelFocus.requestFocus());
                  }
                }),
                decoration: const InputDecoration(labelText: 'Feeling'),
              ),
              if (_selectedFeeling == 'Other') ...[
                const SizedBox(height: 8),
                TextField(controller: _otherFeelCtrl, focusNode: _otherFeelFocus, decoration: const InputDecoration(labelText: 'Custom feeling')),
              ],
              const SizedBox(height: 8),
              TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera),
                label: const Text('Capture Photo'),
                onPressed: _pickImage,
              ),
              if (_image != null) ...[
                const SizedBox(height: 12),
                SizedBox(height: 200, child: Image.file(_image!, fit: BoxFit.contain)),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                label: Text(_isListening ? 'Stop Listening' : 'Start Speaking'),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text(id == null ? 'Create' : 'Update'),
                onPressed: () async {
                  final feelingStr = (_selectedFeeling == 'Other') ? _otherFeelCtrl.text.trim() : (_selectedFeeling ?? _otherFeelCtrl.text.trim());
                  if (feelingStr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or enter a feeling')));
                    return;
                  }
                  if (id == null) {
                    await SQLHelper.createDiary(feelingStr, _descCtrl.text.trim(), imagePath: _image?.path);
                  } else {
                    await SQLHelper.updateDiary(id, feelingStr, _descCtrl.text.trim(), imagePath: _image?.path);
                  }
                  Navigator.pop(ctx);
                  _refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Delete a diary entry
  Future<void> _delete(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyDiary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/theme'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('loggedIn', false);
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  Expanded(
                    child: _diaries.isEmpty
                        ? const Center(child: Text('No diary entries found.'))
                        : ListView.builder(
                            itemCount: _diaries.length,
                            itemBuilder: (ctx, i) {
                              final diary = _diaries[i];
                              return Dismissible(
                                key: ValueKey(diary['id']),
                                background: Container(
                                  color: Colors.red,
                                  child: const Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 16),
                                      child: Icon(Icons.delete, color: Colors.white),
                                    ),
                                  ),
                                ),
                                onDismissed: (_) => _delete(diary['id']),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                  child: ListTile(
                                    onTap: () => _showForm(diary['id']),
                                    leading: (diary['image_path'] != null && (diary['image_path'] as String).isNotEmpty)
                                        ? CircleAvatar(radius: 24, backgroundImage: FileImage(File(diary['image_path'])))
                                        : const CircleAvatar(radius: 24, child: Icon(Icons.book)),
                                    title: Text(diary['feeling']),
                                    subtitle: Text(diary['description']),
                                    trailing: Text(diary['date'].toString().substring(11, 16)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
