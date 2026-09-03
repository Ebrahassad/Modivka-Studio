import re

with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# إضافة استيراد image_picker إذا لم يكن موجوداً
if 'import \'package:image_picker/image_picker.dart\';' not in code:
    code = "import 'package:image_picker/image_picker.dart';\n" + code

# دالة الكاميرا والتراكم المحدثة
camera_and_picker_methods = '''  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _targetImages.add(File(photo.path));
        _imageConfigs.add(
          IndividualConfig(
            xRatio: _globalConfig.customXRatio,
            yRatio: _globalConfig.customYRatio,
            scaleRatio: _globalConfig.scaleRatio,
            opacity: _globalConfig.opacity,
          ),
        );
        _selectedIndex = _targetImages.length - 1;
      });
    }
  }

  Future<void> _pickTargetImages() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      final newFiles = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();

      setState(() {
        final int startIndex = _targetImages.length;
        _targetImages.addAll(newFiles);
        _imageConfigs.addAll(
          List.generate(
            newFiles.length,
            (_) => IndividualConfig(
              xRatio: _globalConfig.customXRatio,
              yRatio: _globalConfig.customYRatio,
              scaleRatio: _globalConfig.scaleRatio,
              opacity: _globalConfig.opacity,
            ),
          ),
        );
        if (startIndex < _targetImages.length) {
          _selectedIndex = startIndex;
        }
      });
    }
  }'''

# استبدال دالة _pickTargetImages بالحزمة الجديدة المتراكمة + الكاميرا
code = re.sub(
    r'Future<void> _pickTargetImages\(\) async \{[\s\S]*?\n  \}',
    camera_and_picker_methods,
    code,
    count=1
)

# استبدال زر الخروج بزر الكاميرا في الـ AppBar
old_appbar_action = '''actions: [
                IconButton(
                  tooltip: AppStrings.get(context, 'exitTooltip'),
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      size: 21,
                      color: primary,
                    ),
                  ),
                  onPressed: () => SystemNavigator.pop(),
                )
              ]'''

new_appbar_action = '''actions: [
                IconButton(
                  tooltip: 'Camera',
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 21,
                      color: primary,
                    ),
                  ),
                  onPressed: _pickImageFromCamera,
                )
              ]'''

code = code.replace(old_appbar_action, new_appbar_action)

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("SUCCESS: Updated HomeScreen with Camera & Accumulated Images logic!")
