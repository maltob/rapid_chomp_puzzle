import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_constants.dart';
import 'jigsaw_piece.dart';
import 'jigsaw_playground.dart';
import '../../core/widgets/gradient_button.dart';

class JigsawSetupScreen extends StatefulWidget {
  const JigsawSetupScreen({super.key});

  @override
  State<JigsawSetupScreen> createState() => _JigsawSetupScreenState();
}

class _JigsawSetupScreenState extends State<JigsawSetupScreen> {
  File? _selectedImage;
  int _selectedSize = 8;
  bool _isEasyMode = true;
  JigsawPieceType _selectedType = JigsawPieceType.rounded;
  List<String> _recentImages = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final storage = Provider.of<StorageService>(context, listen: false);
    _recentImages = storage.getRecentJigsawImages();

    final settingsJson = storage.getJigsawSettings();
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        setState(() {
          _selectedSize = settings['size'] ?? 8;
          _isEasyMode = settings['easyMode'] ?? true;
          _selectedType = JigsawPieceType
              .values[settings['type'] ?? JigsawPieceType.rounded.index];
        });
      } catch (e) {
        debugPrint('Error loading jigsaw settings: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  void _startGame() {
    if (_selectedImage == null) return;

    // Save settings
    final storage = Provider.of<StorageService>(context, listen: false);
    final settings = {
      'size': _selectedSize,
      'easyMode': _isEasyMode,
      'type': _selectedType.index,
    };
    storage.saveJigsawSettings(jsonEncode(settings));
    storage.addRecentJigsawImage(_selectedImage!.path);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JigsawPlayground(
          imageFile: _selectedImage!,
          piecesCount: _selectedSize,
          isEasyMode: _isEasyMode,
          pieceType: _selectedType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jigsaw Setup')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientButton(
                title: 'Start Puzzle',
                icon: Icons.extension_rounded,
                color: const Color(0xFF03DAC6),
                onTap: _selectedImage != null ? _startGame : null,
              ),
              const SizedBox(height: 32),
              const Text(
                '1. Choose an Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_recentImages.isNotEmpty) ...[
                const Text(
                  'Recent:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentImages.length,
                    itemBuilder: (context, index) {
                      final path = _recentImages[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = File(path);
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedImage?.path == path
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedImage != null)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () =>
                              setState(() => _selectedImage = null),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Image from Gallery'),
                ),
              const SizedBox(height: 32),
              const Text(
                '2. Select Puzzle Size',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: AppConstants.jigsawSizes.map((size) {
                  return ChoiceChip(
                    label: Text('$size pieces'),
                    selected: _selectedSize == size,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSize = size);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text(
                '3. Select Piece Style',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Classical Bulbous'),
                    selected: _selectedType == JigsawPieceType.traditional,
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                          () => _selectedType = JigsawPieceType.traditional,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Modern Rounded'),
                    selected: _selectedType == JigsawPieceType.rounded,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = JigsawPieceType.rounded);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                '4. Select Game Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: Text(_isEasyMode ? 'Easy Mode' : 'Normal Mode'),
                  subtitle: Text(
                    _isEasyMode
                        ? 'Show background hint'
                        : 'Empty board, preview in corner',
                  ),
                  value: _isEasyMode,
                  onChanged: (value) => setState(() => _isEasyMode = value),
                  secondary: Icon(
                    _isEasyMode ? Icons.child_care : Icons.fitness_center,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
