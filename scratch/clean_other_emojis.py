# Clean auth_modal.tscn
with open('ping-game/scenes/auth_modal.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('text = "🔐 "', 'text = ""\nvisible = false')

with open('ping-game/scenes/auth_modal.tscn', 'w', encoding='utf-8') as f:
    f.write(text)

# Clean guidebook.tscn
with open('ping-game/scenes/guidebook.tscn', 'r', encoding='utf-8') as f:
    text2 = f.read()

text2 = text2.replace('text = "📖 BUKU PANDUAN JARINGAN (GUIDEBOOK)"', 'text = "BUKU PANDUAN JARINGAN (GUIDEBOOK)"')

with open('ping-game/scenes/guidebook.tscn', 'w', encoding='utf-8') as f:
    f.write(text2)

print("Cleaned emojis from auth_modal and guidebook!")
