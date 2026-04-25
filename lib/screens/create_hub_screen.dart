import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../models/stash_card.dart';

class CreateHubScreen extends StatefulWidget {
  final StorageService storageService;
  final CardType? initialType;

  const CreateHubScreen({super.key, required this.storageService, this.initialType});

  @override
  State<CreateHubScreen> createState() => _CreateHubScreenState();
}

class _CreateHubScreenState extends State<CreateHubScreen> {
  final _contentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController(); 
  final List<TextEditingController> _listItemCtrls = [TextEditingController()];
  final List<bool> _listItemChecked = [false]; 
  String? _attachedFilePath;
  String? _attachedImagePath;

  void _save() async {
    final type = widget.initialType ?? CardType.note;
    String content = "";
    String title = _titleCtrl.text.trim();

    if (type == CardType.list) {
      // List items with [ ] or [x] prefix
      content = List.generate(_listItemCtrls.length, (i) {
        final text = _listItemCtrls[i].text.trim();
        if (text.isEmpty) return null;
        return "${_listItemChecked[i] ? '[x]' : '[ ]'} $text";
      }).where((t) => t != null).join("\n");
      if (title.isEmpty && content.isNotEmpty) title = "To-Do List";
    } else if (type == CardType.quote) {
      content = _contentCtrl.text.trim();
      if (_authorCtrl.text.trim().isNotEmpty) {
        content = "\"$content\"\n— ${_authorCtrl.text.trim()}";
      } else {
        content = "\"$content\"";
      }
      if (title.isEmpty) title = "Quote";
    } else {
      content = _contentCtrl.text.trim();
      if (_attachedFilePath != null && content.isEmpty) {
        content = "Attached: ${_attachedFilePath!.split('/').last}";
      }
      if (title.isEmpty) title = content.isNotEmpty ? content.split('\n')[0] : "Untitled";
    }

    if (content.isEmpty && title.isEmpty && _attachedImagePath == null) return;

    final card = StashCard(
      id: const Uuid().v4(),
      type: type,
      title: title,
      content: content,
      category: null,
      dateAdded: DateTime.now(),
      imagePath: _attachedImagePath,
    );

    await widget.storageService.addCard(card);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null) {
      setState(() {
        _attachedFilePath = result.files.single.path;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachedImagePath = image.path;
      });
    }
  }

  void _addListItem() {
    setState(() {
      _listItemCtrls.add(TextEditingController());
      _listItemChecked.add(false);
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    for (var c in _listItemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = widget.initialType ?? CardType.note;
    final typeStr = type.toString().split('.').last;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54, size: 26),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Stash new $typeStr',
          style: const TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _save,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16)
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_attachedImagePath != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: Image.file(File(_attachedImagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                     ),
                   ),
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: type == CardType.quote ? 'Quote Subject (Optional)' : 'Title (Optional)',
                    hintStyle: const TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(color: Colors.white12),
                if (type == CardType.list) _buildListCreator()
                else if (type == CardType.quote) _buildQuoteCreator()
                else if (type == CardType.video || type == CardType.link) _buildLinkCreator()
                else _buildDefaultCreator(),

                if (type == CardType.note)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 20),
                      label: const Text('Add Image'),
                      style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCreator() {
    return TextField(
      controller: _contentCtrl,
      maxLines: null,
      autofocus: true,
      style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
      decoration: const InputDecoration(
        hintText: 'Start typing here...',
        hintStyle: TextStyle(color: Colors.white24),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildLinkCreator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _contentCtrl,
          maxLines: 1,
          autofocus: true,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
          decoration: const InputDecoration(
            hintText: 'Paste URL here...',
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 12),
        const Text('OR', style: TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file, size: 18),
          label: Text(_attachedFilePath != null ? 'File Attached' : 'Attach from Device'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            foregroundColor: Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_attachedFilePath != null)
           Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Text(_attachedFilePath!.split('/').last, style: const TextStyle(color: Colors.white38, fontSize: 12)),
           ),
      ],
    );
  }

  Widget _buildQuoteCreator() {
    return Column(
      children: [
        TextField(
          controller: _contentCtrl,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(fontSize: 22, color: Colors.white, height: 1.4, fontStyle: FontStyle.italic, fontFamily: 'Georgia'),
          decoration: const InputDecoration(
            hintText: '"Enter the quote here..."',
            hintStyle: TextStyle(color: Colors.white24, fontSize: 20),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _authorCtrl,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
          decoration: const InputDecoration(
            hintText: '— Author',
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _buildListCreator() {
    return Column(
      children: [
        ...List.generate(_listItemCtrls.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _listItemChecked[index],
                  onChanged: (val) {
                    setState(() => _listItemChecked[index] = val ?? false);
                  },
                  activeColor: Theme.of(context).primaryColor,
                  side: const BorderSide(color: Colors.white24),
                ),
                Expanded(
                  child: TextField(
                    controller: _listItemCtrls[index],
                    autofocus: index == _listItemCtrls.length - 1,
                    style: const TextStyle(color: Colors.white70),
                    decoration: const InputDecoration(
                      hintText: 'To-do item...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) _addListItem();
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addListItem,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Item'),
          style: TextButton.styleFrom(foregroundColor: Colors.white38),
        )
      ],
    );
  }
}
