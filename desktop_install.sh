#!/data/data/com.termux/files/usr/bin/bash
set -e

G='\033[1;32m'
Y='\033[1;33m'
C='\033[1;36m'
R='\033[1;31m'
NC='\033[0m'

clear
echo -e "${C}>>> AMAN CYBER INSTALLER FINAL <<<${NC}"

# ===== BASIC SETUP =====
touch ~/.hushlogin
termux-setup-storage || true

pkg update -y || true
pkg install -y proot-distro pulseaudio wget git curl x11-repo tur-repo termux-x11 || true

# ===== DISTRO LIST LOAD (FIXED) =====
clear
echo -e "${C}Available Proot Distros:${NC}"

DISTROS=()

while IFS= read -r line; do
    alias=$(echo "$line" | sed -n 's/.*< *\([^ >]*\) *>.*/\1/p')
    if [ -n "$alias" ]; then
        DISTROS+=("$alias")
    fi
done <<< "$(proot-distro list)"

if [ ${#DISTROS[@]} -eq 0 ]; then
    echo -e "${R}Failed to load distro list${NC}"
    exit 1
fi

i=1
for d in "${DISTROS[@]}"; do
    echo "$i) $d"
    ((i++))
done

echo -e "${R}$i) kali nethunter${NC}"
echo ""

read -p "Choice (number): " choice

# ===== INPUT CHECK =====
if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo -e "${R}Invalid input${NC}"
    exit 1
fi

# ===== KALI OPTION =====
if [ "$choice" -eq "$i" ]; then

echo -e "${Y}Installing Kali NetHunter...${NC}"

wget -O install-nethunter-termux https://offs.ec/2MceZWr
chmod +x install-nethunter-termux
./install-nethunter-termux

cat << 'EOF' > start-kali.sh
#!/data/data/com.termux/files/usr/bin/bash -e
cd ${HOME}
unset LD_PRELOAD
[ ! -f kali-arm64/root/.version ] && touch kali-arm64/root/.version

user="kali"
home="/home/$user"
start="sudo -u kali /bin/bash"

if ! grep -q "kali" kali-arm64/etc/passwd 2>/dev/null; then
 user="root"
 home="/$user"
 start="/bin/bash --login"
fi

cmdline="proot \
--link2symlink \
-0 \
-r kali-arm64 \
-b /dev \
-b /proc \
-b /data/data/com.termux/files/usr/tmp:/tmp \
-b /sdcard \
-b kali-arm64$home:/dev/shm \
-w $home \
/usr/bin/env -i \
HOME=$home \
PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \
TERM=$TERM \
LANG=C.UTF-8 \
$start"

if [ "$#" == "0" ]; then
 exec $cmdline
else
 $cmdline -c "$@"
fi
EOF

chmod +x start-kali.sh

echo '#!/data/data/com.termux/files/usr/bin/bash
bash ~/start-kali.sh' > $PREFIX/bin/kali

chmod +x $PREFIX/bin/kali

echo -e "${G}Kali Installed. Run: kali${NC}"
exit 0
fi

# ===== SELECT DISTRO =====
index=$((choice-1))
DISTRO="${DISTROS[$index]}"

echo -e "${G}Selected: $DISTRO${NC}"

# ===== DESKTOP MENU =====
echo ""
echo "1) xfce4"
echo "2) lxde"
echo "3) lxqt"

read -p "Desktop Choice: " dchoice

case $dchoice in
1) PKG="xfce4 xfce4-goodies"; STARTCMD="startxfce4";;
2) PKG="lxde"; STARTCMD="startlxde";;
3) PKG="lxqt"; STARTCMD="startlxqt";;
*) echo "Invalid"; exit 1;;
esac

proot-distro install "$DISTRO" || true

proot-distro login "$DISTRO" -- bash -c "apt update && apt install -y $PKG" || true

cat << EOF > start-desktop.sh
#!/data/data/com.termux/files/usr/bin/bash
pkill -f termux.x11 2>/dev/null || true
pulseaudio --start --exit-idle-time=-1
export XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :0 &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
proot-distro login $DISTRO --shared-tmp -- /bin/bash -c "export DISPLAY=:0 && $STARTCMD"
EOF

chmod +x start-desktop.sh

echo '#!/data/data/com.termux/files/usr/bin/bash
bash ~/start-desktop.sh' > $PREFIX/bin/desktop

chmod +x $PREFIX/bin/desktop

echo -e "${G}INSTALL COMPLETE ✅${NC}"
echo -e "${C}Run:${NC} desktop"