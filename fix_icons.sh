#!/bin/bash

# Define the base icon and target directory
BASE_ICON="SpendVolt/Assets.xcassets/AppIcon.appiconset/icon.png"
ICON_SET="SpendVolt/Assets.xcassets/AppIcon.appiconset"

# Ensure the base icon exists
if [ ! -f "$BASE_ICON" ]; then
    echo "Base icon not found at $BASE_ICON"
    exit 1
fi

# Function to resize icon
resize_icon() {
    local size=$1
    local name=$2
    sips -z $size $size "$BASE_ICON" --out "$ICON_SET/$name.png" > /dev/null
}

echo "Generating icons..."

# Generate all required sizes for iPhone, iPad and App Store
resize_icon 20 "icon-20"
resize_icon 40 "icon-20@2x"
resize_icon 60 "icon-20@3x"
resize_icon 29 "icon-29"
resize_icon 58 "icon-29@2x"
resize_icon 87 "icon-29@3x"
resize_icon 40 "icon-40"
resize_icon 80 "icon-40@2x"
resize_icon 120 "icon-40@3x"
resize_icon 120 "icon-60@2x"
resize_icon 180 "icon-60@3x"
resize_icon 76 "icon-76"
resize_icon 152 "icon-76@2x"
resize_icon 167 "icon-83.5@2x"
resize_icon 1024 "icon-1024"

# Generate Contents.json
cat <<EOF > "$ICON_SET/Contents.json"
{
  "images": [
    { "size": "20x20", "idiom": "iphone", "filename": "icon-20@2x.png", "scale": "2x" },
    { "size": "20x20", "idiom": "iphone", "filename": "icon-20@3x.png", "scale": "3x" },
    { "size": "29x29", "idiom": "iphone", "filename": "icon-29@2x.png", "scale": "2x" },
    { "size": "29x29", "idiom": "iphone", "filename": "icon-29@3x.png", "scale": "3x" },
    { "size": "40x40", "idiom": "iphone", "filename": "icon-40@2x.png", "scale": "2x" },
    { "size": "40x40", "idiom": "iphone", "filename": "icon-40@3x.png", "scale": "3x" },
    { "size": "60x60", "idiom": "iphone", "filename": "icon-60@2x.png", "scale": "2x" },
    { "size": "60x60", "idiom": "iphone", "filename": "icon-60@3x.png", "scale": "3x" },
    { "size": "20x20", "idiom": "ipad", "filename": "icon-20.png", "scale": "1x" },
    { "size": "20x20", "idiom": "ipad", "filename": "icon-20@2x.png", "scale": "2x" },
    { "size": "29x29", "idiom": "ipad", "filename": "icon-29.png", "scale": "1x" },
    { "size": "29x29", "idiom": "ipad", "filename": "icon-29@2x.png", "scale": "2x" },
    { "size": "40x40", "idiom": "ipad", "filename": "icon-40.png", "scale": "1x" },
    { "size": "40x40", "idiom": "ipad", "filename": "icon-40@2x.png", "scale": "2x" },
    { "size": "76x76", "idiom": "ipad", "filename": "icon-76.png", "scale": "1x" },
    { "size": "76x76", "idiom": "ipad", "filename": "icon-76@2x.png", "scale": "2x" },
    { "size": "83.5x83.5", "idiom": "ipad", "filename": "icon-83.5@2x.png", "scale": "2x" },
    { "size": "1024x1024", "idiom": "ios-marketing", "filename": "icon-1024.png", "scale": "1x" }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
EOF

echo "App icon set generated successfully."

