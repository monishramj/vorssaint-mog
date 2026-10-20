#!/bin/zsh
# mog: downloads Apple's and Beats' public AR models (USDZ) for the connect notice's turning device icon.
# They are their makers' copyright: kept on this Mac only, never committed. The app falls back to still art without them.
set -euo pipefail
dir="$HOME/Library/Application Support/vorssaint-mog/models"
mkdir -p "$dir"
fetch() { [[ -s "$dir/$1" ]] || curl -fsSL --retry 2 -o "$dir/$1" "$2"; echo "✓ $1"; }
fetch airpods-pro.usdz "https://www.apple.com/105/media/us/airpods-pro/2025/7acffb13-4adb-40b1-9393-8f1c99bc6c90/ar/airpods-pro.usdz"
fetch airpods.usdz "https://www.apple.com/105/media/us/airpods-5/2026/1bae77a6-82ef-46c2-875f-571e880dbfe2/ar/airpods-mid.usdz"
fetch airpods-max.usdz "https://www.apple.com/105/media/us/airpods-max/2024/e8f376d6-82b2-40ca-8a22-5f87de755d6b/ar/airpods-max-midnight-variant.usdz"
fetch headphones.usdz "https://www.beatsbydre.com/content/dam/beats/web/product/headphones/studiopro-wireless/global/3d/studio-pro-black.usdz"
fetch beats-earbuds.usdz "https://www.beatsbydre.com/content/dam/beats/web/product/earbuds/powerbeats-pro-2/pdp/product-carousel/jet-black/3d/pbpro2-jet-black-p02.usdz"
