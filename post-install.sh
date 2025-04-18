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

# Variables
DEBIAN_CODENAME="$(lsb_release -sc)"

echo "Mise à jour du système..."
apt update && apt upgrade -y

echo "Ajout des dépôts contrib, non-free et non-free-firmware..."
sed -i "s/main/main contrib non-free non-free-firmware/g" /etc/apt/sources.list

echo "Ajout du dépôt backports directement dans sources.list..."
echo "deb http://deb.debian.org/debian $DEBIAN_CODENAME-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list

echo "Ajout de l'architecture i386 pour compatibilité multi-arch..."
dpkg --add-architecture i386

echo "Mise à jour des dépôts avec backports..."
apt update

echo "Installation des paquets essentiels..."
apt install -y \
    gnome-software gnome-software-plugin-flatpak \
    flatpak wget curl git neofetch htop unzip \
    gimp vlc okular pdfarranger audacity gcompris-qt mtools \
    lutris thunderbird nextcloud-desktop \
    hedgewars youtubedl-gui \
    yaru-theme-gtk yaru-theme-icon yaru-theme-sound \
    python3-pip \
    gnome-shell-extension-manager \
    plymouth plymouth-themes \
    gparted system-config-printer printer-driver-all printer-driver-cups-pdf \
    remmina hplip util-linux util-linux-extra ttf-mscorefonts-installer \
    lm-sensors gnome-shell-extension-dashtodock gnome-shell-extension-appindicator \
    libavcodec-extra bpytop  mpv mesa-opencl-icd bash-completion vulkan-tools vainfo \
    libdvd-pkg libdvdcss2 libdvdnav4 libdvdread8 \
    gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
    tree ncdu rsync zip rar unrar p7zip-full p7zip-rar \
    net-tools nmap traceroute dnsutils tmux bat exa lsd fzf  file jq xclip xsel colordiff moreutils \
    nano micro geany imagemagick libreoffice libreoffice-l10n-fr hunspell-fr \
    fonts-noto fonts-noto-color-emoji fonts-cantarell fonts-dejavu fonts-liberation

sudo dpkg-reconfigure libdvd-pkg

# Configuration de Plymouth
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo update-grub

echo "Ajout de Flathub à Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Installation de Steam via Flatpak
echo "Installation de Steam via Flatpak..."
flatpak install -y flathub com.valvesoftware.Steam

# Installation de Visual Studio Code via Flatpak
echo "Installation de Visual Studio Code via Flatpak..."
flatpak install -y flathub com.visualstudio.code

# Installation de TeamViewer via téléchargement
echo "Installation de TeamViewer..."
wget -O /tmp/teamviewer.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
apt install -y /tmp/teamviewer.deb
rm /tmp/teamviewer.deb

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

#Installation des extensions gnomes
echo "Activation des extensions GNOME..."
apt install -y gnome-shell-extensions-extra gnome-shell-extension-appindicator gnome-shell-extension-arc-menu \
gnome-shell-extension-dash-to-panel gnome-shell-extension-dashtodock gnome-shell-extension-desktop-icons-ng \
gnome-shell-extension-gpaste gnome-shell-extension-manager gnome-shell-extension-prefs

EXTENSIONS=(
  "dash-to-panel@jderose9.github.com"
  "removable-drive-menu@gnome-shell-extensions.gcampax.github.com"
  "arcmenu@arcmenu.com"
  "desktop-icons-ng@gnome-shell-extensions.gcampax.github.com"
  "gpaste@gnome-shell-extensions.gcampax.github.com"
  "no-overview-at-startup@fthx"
  "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
)

for EXT in "${EXTENSIONS[@]}"; do
  echo "Activation de l'extension : $EXT"
  sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus" \
    gnome-extensions enable "$EXT"
done

echo "Nettoyage..."
apt autoremove -y
sudo -u "$USERNAME" update-desktop-database ~/.local/share/applications

echo "Terminé ! Un redémarrage est nécéssaire pour finaliser l’installation."
