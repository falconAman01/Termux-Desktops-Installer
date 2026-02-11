#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

VERSION="3.3"

G='\033[1;32m';Y='\033[1;33m';C='\033[1;36m';R='\033[1;31m';NC='\033[0m'
trap 'echo -e "${R}[ERROR] Installer stopped safely${NC}"' ERR

# ========= ANIMATED BANNER =========
typewriter(){
 text="$1"
 for ((i=0;i<${#text};i++)); do
  printf "%s" "${text:$i:1}"
  sleep 0.01
 done
 echo
}

clear
echo -e "${C}"
typewriter ">>> AMAN CYBER INSTALLER v$VERSION <<<"
echo -e "${NC}"

# ========= BASIC SETUP =========
touch ~/.hushlogin
termux-setup-storage || true

pkg update -y || true
pkg install -y x11-repo tur-repo pulseaudio proot-distro wget git curl || true

# ===== AUTO DETECT TERMUX X11 =====
if pkg search termux-x11-nightly >/dev/null 2>&1; then
 pkg install -y termux-x11-nightly || pkg install -y termux-x11 || true
else
 pkg install -y termux-x11 || true
fi

# ========= LOGIN BANNER =========
grep -q "AMAN CYBER TERMINAL" ~/.bashrc || cat << 'EOF' >> ~/.bashrc
echo -e "\033[1;36m🔥 AMAN CYBER TERMINAL 🔥\033[0m"
echo -e "\033[1;33mScript By: falconAman01"
echo "https://github.com/falconAman01\033[0m"
EOF

# ========= DYNAMIC DISTRO LIST =========
clear
echo -e "${C}Available Proot Distros:${NC}"

mapfile -t DISTROS < <(proot-distro list | grep -E '\* ' | sed -E 's/.*< ([^ ]+) >/\1/')

if [ "${#DISTROS[@]}" -eq 0 ]; then
 echo -e "${R}Failed to load distro list${NC}"
 exit 1
fi

num=1
for d in "${DISTROS[@]}"; do
 echo "$num) $d"
 ((num++))
done

echo -e "${R}$num) kali nethunter${NC}"
echo ""
read -p "Choice (number): " dchoice

# ========= VALIDATION =========
if ! [[ "$dchoice" =~ ^[0-9]+$ ]]; then
 echo -e "${R}Invalid input${NC}"
 exit 1
fi

# ========= KALI OPTION =========
if [ "$dchoice" -eq "$num" ]; then

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

cmd="$@"
if [ "$#" == "0" ]; then
 exec $cmdline
else
 $cmdline -c "$cmd"
fi
EOF

chmod +x start-kali.sh

cat << 'EOF' > $PREFIX/bin/kali
#!/data/data/com.termux/files/usr/bin/bash
bash ~/start-kali.sh
EOF

chmod +x $PREFIX/bin/kali

echo -e "${G}Kali Installed. Run: kali${NC}"
exit 0
fi

# ========= SELECT DISTRO =========
index=$((dchoice-1))
DISTRO="${DISTROS[$index]}"

echo -e "${G}Selected: $DISTRO${NC}"

# ========= DESKTOP MENU =========
echo ""
echo "1) gnome"
echo "2) xfce4"
echo "3) lxde"
echo "4) cinnamon"
echo "5) kde"
echo "6) lxqt"

read -p "Desktop Choice: " dechoice

case $dechoice in
1) PKG="gnome"; STARTCMD="gnome-session";;
2) PKG="xfce4 xfce4-goodies"; STARTCMD="startxfce4";;
3) PKG="lxde"; STARTCMD="startlxde";;
4) PKG="cinnamon"; STARTCMD="cinnamon-session";;
5) PKG="plasma"; STARTCMD="startplasma-x11";;
6) PKG="lxqt"; STARTCMD="startlxqt";;
*) echo "Invalid"; exit 1;;
esac

proot-distro install "$DISTRO" || true

install_desktop(){
if proot-distro login "$DISTRO" -- which pacman >/dev/null 2>&1; then
 CMD="pacman -Sy --noconfirm $PKG"
elif proot-distro login "$DISTRO" -- which apk >/dev/null 2>&1; then
 CMD="apk add $PKG"
else
 CMD="apt update && apt install -y $PKG"
fi
proot-distro login "$DISTRO" -- bash -c "$CMD"
}

echo -e "${Y}Installing Desktop...${NC}"
install_desktop || install_desktop "xfce4 xfce4-goodies" || install_desktop lxde || install_desktop lxqt

# ========= DESKTOP LAUNCHER =========
cat << EOF > start-desktop.sh
#!/data/data/com.termux/files/usr/bin/bash
clear
echo -e "\033[1;36m🔥 AMAN NEON DESKTOP 🔥\033[0m"

pkill -f termux.x11 2>/dev/null || true
pulseaudio --start --exit-idle-time=-1

export XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :0 >/dev/null &
sleep 3

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

proot-distro login $DISTRO --shared-tmp -- /bin/bash -c "export DISPLAY=:0 && $STARTCMD"
EOF

chmod +x start-desktop.sh

cat << 'EOF' > $PREFIX/bin/desktop
#!/data/data/com.termux/files/usr/bin/bash
bash ~/start-desktop.sh
EOF

chmod +x $PREFIX/bin/desktop

echo -e "${G}INSTALL COMPLETE ✅${NC}"
echo -e "${C}Run:${NC} desktop"