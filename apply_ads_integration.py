#!/usr/bin/env python3
import sys, shutil, os, re

PUBSPEC = "pubspec.yaml"
MAIN = "lib/main.dart"
HOME = "lib/screens/home_screen.dart"
MANIFEST = "android/app/src/main/AndroidManifest.xml"

FILES = [PUBSPEC, MAIN, HOME, MANIFEST]
for p in FILES:
    if not os.path.isfile(p):
        print(f"File not found: {p}")
        sys.exit(1)

def backup(path):
    b = path + ".bak_ads"
    shutil.copy(path, b)
    print(f"Backup created: {b}")

for p in FILES:
    backup(p)

def load(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

def save(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

def patch_one(src, pattern, replacement, label):
    matches = pattern.findall(src)
    if len(matches) != 1:
        print(f"[ABORT] {label}: found {len(matches)} matches, expected 1.")
        sys.exit(1)
    return pattern.sub(replacement, src, count=1)

s = load(PUBSPEC)
s = patch_one(
    s,
    re.compile(r"  open_folder: \^0\.0\.4\n"),
    "  open_folder: ^0.0.4\n  unity_ads_plugin: ^0.3.28\n",
    "pubspec dependency"
)
save(PUBSPEC, s)
print("[pubspec.yaml] patched.")

m = load(MAIN)
m = patch_one(
    m,
    re.compile(r"import 'providers/locale_provider\.dart';\n"),
    "import 'providers/locale_provider.dart';\n"
    "import 'services/ads_service.dart';\n",
    "main.dart import"
)
m = patch_one(
    m,
    re.compile(
        r"  await LocaleProvider\.initPreferences\(\);\s*"
        r"runApp\(const MyApp\(\)\);"
    ),
    "  await LocaleProvider.initPreferences();\n\n"
    "  AdsService.init();\n\n"
    "  runApp(const MyApp());",
    "main.dart ads init call"
)
save(MAIN, m)
print("[main.dart] patched.")

man = load(MANIFEST)
man = patch_one(
    man,
    re.compile(r'<uses-permission android:name="android\.permission\.READ_MEDIA_IMAGES"/>\n'),
    '<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>\n'
    '    <uses-permission android:name="android.permission.INTERNET"/>\n',
    "manifest INTERNET permission"
)
man = patch_one(
    man,
    re.compile(r'\s*android:taskAffinity=""\n'),
    "\n",
    "manifest taskAffinity removal"
)
save(MANIFEST, man)
print("[AndroidManifest.xml] patched.")

h = load(HOME)

h = patch_one(
    h,
    re.compile(r"import '\.\./utils/app_strings\.dart';\n"),
    "import '../utils/app_strings.dart';\n"
    "import '../services/ads_service.dart';\n"
    "import 'package:flutter/foundation.dart' show kIsWeb;\n"
    "import 'package:unity_ads_plugin/unity_ads_plugin.dart';\n",
    "home imports"
)

h = patch_one(
    h,
    re.compile(
        r"onPressed: \(\) => Navigator\.pop\(context\),\s*"
        r"icon: const Icon\(\s*"
        r"Icons\.check_rounded,"
    ),
    "onPressed: () {\n"
    "                Navigator.pop(context);\n"
    "                AdsService.showInterstitial();\n"
    "              },\n"
    "              icon: const Icon(\n"
    "                Icons.check_rounded,",
    "home interstitial hook"
)

h = patch_one(
    h,
    re.compile(
        r"(onChanged: \(value\) \{\s*"
        r"setState\(\(\) \{\s*"
        r"_globalConfig\.removeLogoBg = value;\s*"
        r"\}\);\s*"
        r"_generateLogoPreview\(\);\s*)"
        r"(\},)"
    ),
    r"\1"
    "\n                                    if (value) {\n"
    "                                      AdsService.showRewarded();\n"
    "                                    }\n                                  "
    r"\2",
    "home rewarded hook"
)

h = patch_one(
    h,
    re.compile(
        r"(body: SafeArea\(\s*"
        r"child: Column\(\s*"
        r"children: \[\s*"
        r"Expanded\(\s*"
        r"child: SingleChildScrollView\(.*?\n"
        r"                        \],\s*"
        r"                      \),\s*"
        r"                    \),\s*"
        r"                  \),\s*)"
        r"(\s*\],\s*"
        r"              \),\s*"
        r"            \),\s*"
        r"          \),\s*"
        r"        \);\s*"
        r"      \},\s*"
        r"    \);\s*"
        r"  \}\s*"
        r"\n\s*Widget _uiSwitchRow)",
        re.DOTALL
    ),
    r"\1"
    "                  _buildBannerAd(),\n"
    r"\2",
    "home banner insertion point"
)

h = patch_one(
    h,
    re.compile(r"\n  Widget _uiSwitchRow\(\{"),
    "\n"
    "  Widget _buildBannerAd() {\n"
    "    if (kIsWeb) return const SizedBox.shrink();\n"
    "    try {\n"
    "      if (!(Platform.isAndroid || Platform.isIOS)) {\n"
    "        return const SizedBox.shrink();\n"
    "      }\n"
    "    } catch (_) {\n"
    "      return const SizedBox.shrink();\n"
    "    }\n"
    "    return ValueListenableBuilder<bool>(\n"
    "      valueListenable: AdsService.bannerAvailable,\n"
    "      builder: (context, available, _) {\n"
    "        if (!available) return const SizedBox.shrink();\n"
    "        return SizedBox(\n"
    "          height: 50,\n"
    "          child: UnityBannerAd(\n"
    "            placementId: AdsService.bannerPlacementId,\n"
    "            onLoad: (placementId) {},\n"
    "            onFailed: (placementId, error, message) {\n"
    "              AdsService.bannerAvailable.value = false;\n"
    "            },\n"
    "          ),\n"
    "        );\n"
    "      },\n"
    "    );\n"
    "  }\n"
    "\n"
    "  Widget _uiSwitchRow({",
    "home banner helper method"
)

save(HOME, h)
print("[home_screen.dart] patched.")

print("\nAll patches applied successfully.")
print("\nNow run:")
print(f"  dart format {HOME} {MAIN}")
print(f"  flutter analyze {HOME} {MAIN}")
