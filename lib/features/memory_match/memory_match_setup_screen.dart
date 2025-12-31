import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_constants.dart';
import '../../core/services/storage_service.dart';
import 'memory_match_screen.dart';
import '../../core/widgets/gradient_button.dart';

class MemoryMatchSetupScreen extends StatefulWidget {
  const MemoryMatchSetupScreen({super.key});

  @override
  State<MemoryMatchSetupScreen> createState() => _MemoryMatchSetupScreenState();
}

class _MemoryMatchSetupScreenState extends State<MemoryMatchSetupScreen> {
  int _selectedPairs = 6;
  bool _useCustomImages = false;
  List<File> _customImages = [];
  List<Map<String, dynamic>> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadSettings();
  }

  void _loadPresets() {
    final storage = Provider.of<StorageService>(context, listen: false);
    final jsonStr = storage.getMemoryMatchPresets();
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      setState(() {
        _presets = decoded.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error loading presets: $e');
    }
  }

  void _loadSettings() {
    final storage = Provider.of<StorageService>(context, listen: false);
    final settingsJson = storage.getMemoryMatchSettings();
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        setState(() {
          _selectedPairs = settings['pairs'] ?? 6;
          _useCustomImages = settings['useCustom'] ?? false;
        });
      } catch (e) {
        debugPrint('Error loading memory match settings: $e');
      }
    }
  }

  Future<void> _savePreset(String name) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final newPreset = {
      'name': name,
      'pairs': _selectedPairs,
      'images': _customImages.map((f) => f.path).toList(),
    };
    _presets.add(newPreset);
    await storage.saveMemoryMatchPresets(jsonEncode(_presets));
    setState(() {});
  }

  Future<void> _deletePreset(int index) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    _presets.removeAt(index);
    await storage.saveMemoryMatchPresets(jsonEncode(_presets));
    setState(() {});
  }

  Future<void> _clearPresets() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    _presets.clear();
    await storage.saveMemoryMatchPresets('[]');
    setState(() {});
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _customImages = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      });
    }
  }

  void _startGame() {
    if (_useCustomImages && _customImages.length < _selectedPairs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least $_selectedPairs images.'),
        ),
      );
      return;
    }

    // Save settings
    final storage = Provider.of<StorageService>(context, listen: false);
    final settings = {'pairs': _selectedPairs, 'useCustom': _useCustomImages};
    storage.saveMemoryMatchSettings(jsonEncode(settings));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryMatchScreen(
          numberOfPairs: _selectedPairs,
          customImagePaths: _useCustomImages
              ? _customImages.map((f) => f.path).toList()
              : null,
        ),
      ),
    );
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _selectedPairs = preset['pairs'];
      _useCustomImages = true;
      _customImages = (preset['images'] as List)
          .map((path) => File(path))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Match Setup')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GradientButton(
              title: 'Start Game',
              icon: Icons.grid_view_rounded,
              color: const Color(0xFF6200EE),
              onTap: _startGame,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '1. Select Number of Pairs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: AppConstants.memoryMatchOptions.map((pairs) {
                        return ChoiceChip(
                          label: Text('$pairs Pairs'),
                          selected: _selectedPairs == pairs,
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _selectedPairs = pairs);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '2. Choose Card Style',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Use Custom Images'),
                      subtitle: const Text(
                        'Choose your own photos for the cards',
                      ),
                      value: _useCustomImages,
                      onChanged: (val) =>
                          setState(() => _useCustomImages = val),
                    ),
                    if (_useCustomImages) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(
                          'Select $_selectedPairs Images (${_customImages.length} selected)',
                        ),
                      ),
                      if (_customImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _customImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _customImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_customImages.length >= _selectedPairs)
                          TextButton.icon(
                            onPressed: () {
                              final controller = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Save Preset'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      labelText: 'Preset Name',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (controller.text.isNotEmpty) {
                                          _savePreset(controller.text);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save as Preset'),
                          ),
                      ],
                    ],
                    if (_presets.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '3. Quick Presets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear All Presets'),
                                  content: const Text(
                                    'Are you sure you want to delete all saved presets?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _clearPresets();
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Clear All',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Clear All',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._presets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final preset = entry.value;
                        final List<String> paths = (preset['images'] as List)
                            .cast<String>();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _applyPreset(preset),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(
                                    preset['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('${preset['pairs']} pairs'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () => _deletePreset(index),
                                      ),
                                      const Icon(
                                        Icons.play_circle_fill,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 60,
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 12,
                                  ),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: paths.length > 6
                                        ? 6
                                        : paths.length,
                                    itemBuilder: (context, i) {
                                      return Container(
                                        width: 48,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          image: DecorationImage(
                                            image: FileImage(File(paths[i])),
                                            fit: BoxFit.cover,
                                          ),
                                          border: Border.all(
                                            color: Colors.black12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
