#!/usr/bin/env python3
import sys, shutil, os

HOME = "lib/screens/home_screen.dart"
if not os.path.isfile(HOME):
    print(f"File not found: {HOME}")
    sys.exit(1)

backup = HOME + ".bak_final"
shutil.copy(HOME, backup)
print(f"Backup created: {backup}")

with open(HOME, "r", encoding="utf-8") as f:
    h = f.read()

def apply_one(text, old, new, label):
    count = text.count(old)
    if count != 1:
        print(f"[ABORT] {label}: found {count} times, expected 1.")
        sys.exit(1)
    return text.replace(old, new, 1)

old_banner = (
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
    "            onFailed: (placementId, error, message) {},\n"
    "          ),\n"
    "        );\n"
    "      },\n"
    "    );\n"
    "  }\n"
)
new_banner = (
    "  Widget _buildBannerAd() {\n"
    "    if (kIsWeb) return const SizedBox.shrink();\n"
    "    try {\n"
    "      if (!(Platform.isAndroid || Platform.isIOS)) {\n"
    "        return const SizedBox.shrink();\n"
    "      }\n"
    "    } catch (_) {\n"
    "      return const SizedBox.shrink();\n"
    "    }\n"
    "    return SizedBox(\n"
    "      width: double.infinity,\n"
    "      height: 50,\n"
    "      child: UnityBannerAd(\n"
    "        placementId: AdsService.bannerPlacementId,\n"
    "        onLoad: (placementId) {},\n"
    "        onFailed: (placementId, error, message) {},\n"
    "      ),\n"
    "    );\n"
    "  }\n"
)

if h.count(old_banner) == 1:
    h = apply_one(h, old_banner, new_banner, "banner width fix")
    print("Banner width fix applied.")
elif "width: double.infinity,\n      height: 50," in h:
    print("Banner width fix already applied previously — skipping.")
else:
    print("[ABORT] _buildBannerAd anchor not found.")
    sys.exit(1)

old_switch_style = (
    "          child: Text(\n"
    "            title,\n"
    "            maxLines: 2,\n"
    "            overflow: TextOverflow.ellipsis,\n"
    "            style: TextStyle(\n"
    "              fontSize: 13,\n"
    "              fontWeight: FontWeight.w700,\n"
    "              color: textColor,\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "        Switch("
)
new_switch_style = (
    "          child: Text(\n"
    "            title,\n"
    "            maxLines: 2,\n"
    "            overflow: TextOverflow.ellipsis,\n"
    "            style: TextStyle(\n"
    "              fontSize: 14,\n"
    "              fontWeight: FontWeight.w700,\n"
    "              color: textColor,\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "        Switch("
)
h = apply_one(h, old_switch_style, new_switch_style, "_uiSwitchRow font size")

old_slider_title_style = (
    "          child: Text(\n"
    "            title,\n"
    "            maxLines: 1,\n"
    "            overflow: TextOverflow.ellipsis,\n"
    "            style: TextStyle(\n"
    "              fontSize: 11,\n"
    "              fontWeight: FontWeight.w700,\n"
    "              color: textColor,\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "        const SizedBox(width: 6),"
)
new_slider_title_style = (
    "          child: Text(\n"
    "            title,\n"
    "            maxLines: 1,\n"
    "            overflow: TextOverflow.ellipsis,\n"
    "            style: TextStyle(\n"
    "              fontSize: 12,\n"
    "              fontWeight: FontWeight.w700,\n"
    "              color: textColor,\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "        const SizedBox(width: 6),"
)
h = apply_one(h, old_slider_title_style, new_slider_title_style, "_uiCompactSlider title font size")

old_slider_value_style = (
    "          child: Text(\n"
    "            display,\n"
    "            textAlign: TextAlign.end,\n"
    "            style: TextStyle(\n"
    "              fontSize: 10,\n"
    "              fontWeight: FontWeight.w700,\n"
    "              color: color,\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "      ],\n"
    "    );\n"
    "  }\n"
    "}\n"
)
new_slider_value_style = (
    "          child: Text(\n"
    "            display,\n"
    "            textAlign: TextAlign.end,\n"
    "            style: TextStyle(\n"
    "              fontSize: 11,\n"
    "              fontWeight: FontWeight.w700,\n"
    "              color: color,\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "      ],\n"
    "    );\n"
    "  }\n"
    "}\n"
)
h = apply_one(h, old_slider_value_style, new_slider_value_style, "_uiCompactSlider value font size")

with open(HOME, "w", encoding="utf-8") as f:
    f.write(h)

print("home_screen.dart patched successfully.")
