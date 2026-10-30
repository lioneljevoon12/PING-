import os
import urllib.request
import re

os.makedirs('ping-game/art/ui-ux/icons', exist_ok=True)

icons_to_fetch = {
    'icon_settings.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/settings.svg',
    'icon_music.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/music.svg',
    'icon_sound.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/volume-2.svg',
    'icon_sound_off.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/volume-x.svg',
    'icon_gamepad.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/gamepad-2.svg',
    'icon_cpu.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/cpu.svg',
    'icon_info.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/info.svg',
    'icon_vibrate.svg': 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/smartphone.svg',
}

for filename, url in icons_to_fetch.items():
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        svg_data = urllib.request.urlopen(req, timeout=5).read().decode('utf-8')
        
        # Customize SVG to match PING! design style
        # Change width/height to 64, stroke to #5a2a27, stroke-width to 2.5
        svg_data = re.sub(r'width="\d+"', 'width="64"', svg_data)
        svg_data = re.sub(r'height="\d+"', 'height="64"', svg_data)
        svg_data = re.sub(r'stroke="currentColor"', 'stroke="#5a2a27"', svg_data)
        svg_data = re.sub(r'stroke-width="\d+(\.\d+)?"', 'stroke-width="2.5"', svg_data)
        
        out_path = os.path.join('ping-game/art/ui-ux/icons', filename)
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(svg_data)
        print(f"Downloaded and customized {filename}")
    except Exception as e:
        print(f"Failed {filename}: {e}")

print("Icon download completed!")
