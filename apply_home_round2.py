#!/usr/bin/env python3
import sys, shutil, os, re

HOME = "lib/screens/home_screen.dart"
if not os.path.isfile(HOME):
    print(f"File not found: {HOME}")
    sys.exit(1)

backup = HOME + ".bak_ui3"
shutil.copy(HOME, backup)
print(f"Backup created: {backup}")

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

h = load(HOME)

# Top 3 buttons: filled brand-color style (matches Save button) + larger text
h = patch_one(
    h,
    re.compile(
        r"return Expanded\(\s*"
        r"child: Material\(\s*"
        r"color: Colors\.white\.withAlpha\(235\),\s*"
        r"borderRadius: BorderRadius\.circular\(13\),\s*"
        r"elevation: 2,\s*"
        r"child: InkWell\(\s*"
        r"borderRadius: BorderRadius\.circular\(13\),\s*"
        r"onTap: onTap,\s*"
        r"child: Padding\(\s*"
        r"padding: EdgeInsets\.symmetric\(\s*"
        r"vertical: compact \? 8 : 10,\s*"
        r"horizontal: compact \? 3 : 6,\s*"
        r"\),\s*"
        r"child: Row\(\s*"
        r"mainAxisAlignment:\s*"
        r"MainAxisAlignment\.center,\s*"
        r"children: \[\s*"
        r"if \(!textOnly\) \.\.\.\[\s*"
        r"Icon\(\s*"
        r"icon,\s*"
        r"color: color,\s*"
        r"size: compact \? 17 : 20,\s*"
        r"\),\s*"
        r"SizedBox\(width: compact \? 3 : 6\),\s*"
        r"\],\s*"
        r"Flexible\(\s*"
        r"child: Text\(\s*"
        r"title,\s*"
        r"maxLines: 1,\s*"
        r"overflow: TextOverflow\.ellipsis,\s*"
        r"textAlign: TextAlign\.center,\s*"
        r"style: TextStyle\(\s*"
        r"color:\s*"
        r"const Color\(0xFF263238\),\s*"
        r"fontSize: compact \? 10 : 11\.5,\s*"
        r"fontWeight: FontWeight\.w700,\s*"
        r"\),\s*"
        r"\),\s*"
        r"\),\s*"
        r"\],\s*"
        r"\),\s*"
        r"\),\s*"
        r"\),\s*"
        r"\),\s*"
        r"\);"
    ),
    "return Expanded(\n"
    "                                  child: Material(\n"
    "                                    color: color,\n"
    "                                    borderRadius: BorderRadius.circular(13),\n"
    "                                    elevation: 4,\n"
    "                                    shadowColor: color.withAlpha(90),\n"
    "                                    child: InkWell(\n"
    "                                      borderRadius: BorderRadius.circular(13),\n"
    "                                      onTap: onTap,\n"
    "                                      child: Padding(\n"
    "                                        padding: EdgeInsets.symmetric(\n"
    "                                          vertical: compact ? 9 : 11,\n"
    "                                          horizontal: compact ? 3 : 6,\n"
    "                                        ),\n"
    "                                        child: Row(\n"
    "                                          mainAxisAlignment:\n"
    "                                              MainAxisAlignment.center,\n"
    "                                          children: [\n"
    "                                            if (!textOnly) ...[\n"
    "                                              Icon(\n"
    "                                                icon,\n"
    "                                                color: Colors.white,\n"
    "                                                size: compact ? 18 : 21,\n"
    "                                              ),\n"
    "                                              SizedBox(width: compact ? 3 : 6),\n"
    "                                            ],\n"
    "                                            Flexible(\n"
    "                                              child: Text(\n"
    "                                                title,\n"
    "                                                maxLines: 1,\n"
    "                                                overflow: TextOverflow.ellipsis,\n"
    "                                                textAlign: TextAlign.center,\n"
    "                                                style: TextStyle(\n"
    "                                                  color: Colors.white,\n"
    "                                                  fontSize: compact ? 12 : 13.5,\n"
    "                                                  fontWeight: FontWeight.w800,\n"
    "                                                ),\n"
    "                                              ),\n"
    "                                            ),\n"
    "                                          ],\n"
    "                                        ),\n"
    "                                      ),\n"
    "                                    ),\n"
    "                                  ),\n"
    "                                );",
    "top-button filled style redesign"
)

# Stack the two tools-box switches (removeLogoBg on top, applyToAll below)
h = patch_one(
    h,
    re.compile(
        r"Row\(\s*"
        r"children: \[\s*"
        r"Expanded\(\s*"
        r"child: _uiSwitchRow\(\s*"
        r"icon: Icons\.select_all_rounded,\s*"
        r"title: AppStrings\.get\(\s*"
        r"context,\s*"
        r"'applyToAllTitle',\s*"
        r"\),\s*"
        r"value: _applyToAll,\s*"
        r"color: primary,\s*"
        r"textColor: textColor,\s*"
        r"onChanged: \(value\) \{\s*"
        r"setState\(\(\) \{\s*"
        r"_applyToAll = value;\s*"
        r"\}\);\s*"
        r"\},\s*"
        r"\),\s*"
        r"\),\s*"
        r"const SizedBox\(width: 8\),\s*"
        r"Expanded\(\s*"
        r"child: _uiSwitchRow\(\s*"
        r"icon: Icons\.auto_fix_high_rounded,\s*"
        r"title: AppStrings\.get\(\s*"
        r"context,\s*"
        r"'removeLogoBg',\s*"
        r"\),\s*"
        r"value: _globalConfig\.removeLogoBg,\s*"
        r"color: accent,\s*"
        r"textColor: textColor,\s*"
        r"onChanged: \(value\) \{\s*"
        r"setState\(\(\) \{\s*"
        r"_globalConfig\.removeLogoBg = value;\s*"
        r"\}\);\s*"
        r"_generateLogoPreview\(\);\s*"
        r"\},\s*"
        r"\),\s*"
        r"\),\s*"
        r"\],\s*"
        r"\),"
    ),
    "_uiSwitchRow(\n"
    "                                  icon: Icons.auto_fix_high_rounded,\n"
    "                                  title: AppStrings.get(\n"
    "                                    context,\n"
    "                                    'removeLogoBg',\n"
    "                                  ),\n"
    "                                  value: _globalConfig.removeLogoBg,\n"
    "                                  color: accent,\n"
    "                                  textColor: textColor,\n"
    "                                  onChanged: (value) {\n"
    "                                    setState(() {\n"
    "                                      _globalConfig.removeLogoBg = value;\n"
    "                                    });\n"
    "                                    _generateLogoPreview();\n"
    "                                  },\n"
    "                                ),\n"
    "                                const SizedBox(height: 8),\n"
    "                                _uiSwitchRow(\n"
    "                                  icon: Icons.select_all_rounded,\n"
    "                                  title: AppStrings.get(\n"
    "                                    context,\n"
    "                                    'applyToAllTitle',\n"
    "                                  ),\n"
    "                                  value: _applyToAll,\n"
    "                                  color: primary,\n"
    "                                  textColor: textColor,\n"
    "                                  onChanged: (value) {\n"
    "                                    setState(() {\n"
    "                                      _applyToAll = value;\n"
    "                                    });\n"
    "                                  },\n"
    "                                ),",
    "switches stacked order"
)

save(HOME, h)
print("home_screen.dart patched successfully (button style + switch order).")
