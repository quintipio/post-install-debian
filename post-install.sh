#!/bin/bash

# Vérification si le script est exécuté en root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Stop script on error
set -e

# Sélection de l'utilisateur
USERS=$(ls /home)
echo "Utilisateurs disponibles :"
select USERNAME in $USERS; do
  if [ -n "$USERNAME" ]; then
    echo "Utilisateur sélectionné : $USERNAME"
    break
  else
    echo "Choix invalide. Veuillez réessayer."
  fi
done

# Choix de l'environnement de bureau
echo "Choisissez l'environnement de bureau à installer :"
echo "1 - GNOME"
echo "2 - XFCE"
echo "3 - Les deux"
read -p "Choix : " DESKTOP_CHOICE

# Variables
DEBIAN_CODENAME="$(lsb_release -sc)"

echo "Mise à jour du système..."
apt update && apt upgrade -y

echo "Ajout des dépôts contrib, non-free et non-free-firmware..."
sed -i "s/main/main contrib non-free non-free-firmware/g" /etc/apt/sources.list
echo "deb http://deb.debian.org/debian $DEBIAN_CODENAME-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list

echo "Ajout de l'architecture i386..."
dpkg --add-architecture i386

echo "Mise à jour des dépôts..."
apt update

# Paquets essentiels communs
ESSENTIAL_PACKAGES="
gnome-software gnome-software-plugin-flatpak
flatpak wget curl git neofetch htop unzip simple-scan
gimp vlc numlockx mtools thunderbird
python3-pip plymouth plymouth-themes
gparted system-config-printer printer-driver-all printer-driver-cups-pdf
hplip util-linux util-linux-extra ttf-mscorefonts-installer
lm-sensors
libavcodec-extra bpytop mpv mesa-opencl-icd bash-completion vulkan-tools vainfo
libdvd-pkg libdvdcss2 libdvdnav4 libdvdread8
gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
tree ncdu rsync zip rar unrar p7zip-full p7zip-rar
net-tools nmap traceroute dnsutils tmux bat exa lsd fzf file jq xclip xsel colordiff moreutils
nano micro geany imagemagick libreoffice libreoffice-l10n-fr hunspell-fr
fonts-noto fonts-noto-color-emoji fonts-cantarell fonts-dejavu fonts-liberation
yaru-theme-gtk yaru-theme-icon yaru-theme-sound
"

# GNOME
if [[ "$DESKTOP_CHOICE" == "1" || "$DESKTOP_CHOICE" == "3" ]]; then
  DESKTOP_PACKAGES_GNOME="
  gnome-shell-extension-manager
  gnome-shell-extensions-extra gnome-shell-extension-appindicator gnome-shell-extension-arc-menu
  gnome-shell-extension-dash-to-panel gnome-shell-extension-dashtodock
  gnome-shell-extension-desktop-icons-ng gnome-shell-extension-gpaste gnome-shell-extension-prefs"
fi

# XFCE
if [[ "$DESKTOP_CHOICE" == "2" || "$DESKTOP_CHOICE" == "3" ]]; then
  DESKTOP_PACKAGES_XFCE="
  lightdm-settings gnome-control-center xfce4-goodies lxappearance dconf-editor"
fi

echo "Installation des paquets..."
apt install -y $ESSENTIAL_PACKAGES $DESKTOP_PACKAGES_GNOME $DESKTOP_PACKAGES_XFCE

echo "Configuration de libdvd-pkg..."
sudo dpkg-reconfigure libdvd-pkg

# GRUB et Plymouth
echo "Configuration de Plymouth..."
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo update-grub

echo "Ajout de Flathub..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Installation de paquets optionnels
OPTIONAL_APPS=(
  "okular" "pdfarranger" "audacity" "gcompris-qt"
  "nextcloud-desktop" "hedgewars" "youtubedl-gui"
)
FLATPAK_APPS=(
  "com.valvesoftware.Steam" "com.visualstudio.code" "net.lutris.Lutris"
)

echo "Souhaitez-vous installer les paquets applicatifs optionnels suivants ?"
for app in "${OPTIONAL_APPS[@]}"; do
  read -p "Installer $app ? [y/n] " yn
  if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
    apt install -y "$app"
  fi
done

echo "Souhaitez-vous installer Steam, Lutris, ou Visual Studio Code via Flatpak ?"
for fapp in "${FLATPAK_APPS[@]}"; do
  read -p "Installer $(basename "$fapp") ? [y/n] " yn
  if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
    sudo -u "$USERNAME" flatpak install -y flathub "$fapp"
  fi
done

# TeamViewer (question ajoutée)
read -p "Souhaitez-vous installer TeamViewer ? [y/n] " install_teamviewer
if [[ "$install_teamviewer" == "y" || "$install_teamviewer" == "Y" ]]; then
  echo "Installation de TeamViewer..."
  wget -O /tmp/teamviewer.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
  apt install -y /tmp/teamviewer.deb
  rm /tmp/teamviewer.deb
fi


echo "Ajout de $USERNAME au groupe sudo..."
sudo usermod -aG sudo "$USERNAME"

# Choix du navigateur
echo "Choisissez les navigateurs à installer (séparez les choix par des espaces) :"
echo "1 - Brave (APT)"
echo "2 - Chrome (APT)"
echo "3 - Firefox (Flatpak)"
echo "4 - Chromium (APT)"
echo "5 - Brave (Flatpak)"
echo "6 - Chrome (Flatpak)"
echo "Entrez votre choix (ex: 1 2 3 pour installer Brave, Chrome et Firefox):"
read -p "Choix : " CHOICES

# Traitement des choix
for CHOICE in $CHOICES; do
    case $CHOICE in
        1)
            echo "Installation de Brave via APT..."
            curl -fsS https://dl.brave.com/install.sh | sh
            ;;
        2)
            echo "Téléchargement et installation de Google Chrome via APT..."
            wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            apt install -y /tmp/google-chrome.deb
            rm /tmp/google-chrome.deb
            ;;
        3)
            echo "Installation de Firefox via Flatpak..."
            sudo -u $USERNAME flatpak install -y flathub org.mozilla.firefox
            ;;
        4)
            echo "Installation de Chromium via APT..."
            apt install -y chromium
            ;;
        5)
            echo "Installation de Brave via Flatpak..."
            sudo -u $USERNAME flatpak install -y flathub com.brave.Browser
            ;;
        6)
            echo "Installation de Chrome via Flatpak..."
            sudo -u $USERNAME flatpak install -y flathub com.google.Chrome
            ;;
        *)
            echo "Choix invalide, aucune action effectuée."
            ;;
    esac
done

# Mise en place de Yaru
echo "Application du thème Yaru pour $USERNAME..."
sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'

# Activer le mode sombre
echo "Activation du mode sombre pour $USERNAME..."
sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Configuration des boutons de fenêtre GNOME
echo "Affichage des boutons maximiser et minimiser dans GNOME pour $USERNAME..."
sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

# Configuration du raccourci clavier Super+E pour ouvrir le dossier personnel
echo "Configuration du raccourci clavier Super+E pour ouvrir le dossier personnel..."
sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

echo "Nettoyage..."
apt autoremove -y
sudo -u "$USERNAME" update-desktop-database ~/.local/share/applications

echo "Terminé ! Un redémarrage est nécéssaire pour finaliser l’installation. Si le bureau est gnome, une fois le redémarrage effectué, il faut se rendre dans l'application extension pour activer les extensions gnome."
