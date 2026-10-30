import urllib.request
import re

url = 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/headphones.svg'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
svg_data = urllib.request.urlopen(req, timeout=5).read().decode('utf-8')

svg_data = re.sub(r'width="\d+"', 'width="64"', svg_data)
svg_data = re.sub(r'height="\d+"', 'height="64"', svg_data)
svg_data = re.sub(r'stroke="currentColor"', 'stroke="#5a2a27"', svg_data)
svg_data = re.sub(r'stroke-width="\d+(\.\d+)?"', 'stroke-width="2.5"', svg_data)

with open('ping-game/art/ui-ux/icons/icon_music.svg', 'w', encoding='utf-8') as f:
    f.write(svg_data)

print("Downloaded icon_music.svg successfully!")
