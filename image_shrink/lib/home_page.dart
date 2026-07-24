import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'compressor.dart';
import 'utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  File? _originalImage;
  File? _compressedImage;

  bool _compressing = false;

  int _selectedSize = 500;

  final List<int> sizes = [
    100,
    250,
    500,
    1024,
    2048,
    5120,
  ];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);

    if (file == null) return;

    setState(() {
      _originalImage = File(file.path);
      _compressedImage = null;
    });
  }

  Future<void> _compress() async {
    if (_originalImage == null) return;

    setState(() {
      _compressing = true;
    });

    final File? image = await Compressor.compressImage(
      _originalImage!,
      _selectedSize,
    );

    setState(() {
      _compressedImage = image;
      _compressing = false;
    });
  }

  Widget imageCard(
      String title,
      File? image,
      ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            if (image == null)
              Container(
                height: 220,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  size: 90,
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 10),

            if (image != null)
              Text(
                "Size : ${formatFileSize(image.lengthSync())}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Image Shrink"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo),
              label: const Text("Pick From Gallery"),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Picture"),
            ),

            const SizedBox(height: 25),

            imageCard(
              "Original Image",
              _originalImage,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              value: _selectedSize,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Target Size",
              ),

              items: sizes.map((e) {

                String text;

                if (e < 1024) {
                  text = "$e KB";
                } else {
                  text = "${e ~/ 1024} MB";
                }

                return DropdownMenuItem(
                  value: e,
                  child: Text(text),
                );

              }).toList(),

              onChanged: (value) {
                setState(() {
                  _selectedSize = value!;
                });
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                _compressing
                    ? null
                    : _compress,
                icon: const Icon(Icons.compress),
                label: const Text(
                  "Compress Image",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (_compressing)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (_compressedImage != null)
              imageCard(
                "Compressed Image",
                _compressedImage,
              ),
            const SizedBox(height: 15),

            if (_compressedImage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [

                      Text(
                        "Original : ${formatFileSize(_originalImage!.lengthSync())}",
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Compressed : ${formatFileSize(_compressedImage!.lengthSync())}",
                      ),

                      const SizedBox(height: 8),

                      Text(
                          "Reduced : ${compressionPercentage(
                            _originalImage!.lengthSync(),
                            _compressedImage!.lengthSync(),
                          ).toStringAsFixed(1)} %",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (_compressedImage != null)

              Row(

                children: [

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await saveImage(_compressedImage!);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Image saved."),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Save"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await shareImage(_compressedImage!);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                    ),
                  ),

                ],
              )

          ],
        ),
      ),
    );
  }
}