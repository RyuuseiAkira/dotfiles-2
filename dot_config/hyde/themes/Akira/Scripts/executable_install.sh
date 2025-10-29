#!/usr/bin/env bash

# this script will install msi-ec and agsv1

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No color

pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

scrDir="$(dirname "$(realpath "$0")")"

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script should not be run as root. Please run it as a regular user."
    exit 1
fi

## Install msi-ec (Kernel Module)

echo -e "${GREEN}[INFO]${NC} Installing msi-ec (kernel module)..."
msi_ec_dir="${scrDir}/msi-ec"

KERNEL_NAME=$(uname -r)
KERNEL_HEADERS_PKG="linux-headers" # Default for standard kernel

if echo "$KERNEL_NAME" | grep -q -- "-zen"; then
    KERNEL_HEADERS_PKG="linux-zen-headers"
elif echo "$KERNEL_NAME" | grep -q -- "-lts"; then
    KERNEL_HEADERS_PKG="linux-lts-headers"
# Add more specific flavors if needed, e.g., elif echo "$KERNEL_NAME" | grep -q -- "-hardened"; then KERNEL_HEADERS_PKG="linux-hardened-headers"
fi

# Install prerequisites for kernel modules on Arch
echo -e "${GREEN}[INFO]${NC} Installing prerequisites for msi-ec (base-devel, ${KERNEL_HEADERS_PKG})..."
sudo pacman -S --noconfirm --needed base-devel "${KERNEL_HEADERS_PKG}"
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Failed to install msi-ec build prerequisites. Skipping msi-ec installation."
else
    # Check if dkms is installed, install if not
    if ! pkg_installed dkms; then
        echo -e "${YELLOW}[WARN]${NC} dkms is not installed. Attempting to install dkms with yay..."
        if pkg_installed yay; then
            yay -S --noconfirm dkms
            if [ $? -ne 0 ]; then
                echo -e "${RED}[ERROR]${NC} Failed to install dkms with yay. Skipping msi-ec installation."
                dkms_installed=false
            else
                echo -e "${GREEN}[INFO]${NC} dkms installed successfully."
                dkms_installed=true
            fi
        else
            echo -e "${RED}[ERROR]${NC} yay is not installed. Cannot automatically install dkms. Skipping msi-ec installation."
            dkms_installed=false
        fi
    else
        echo -e "${GREEN}[INFO]${NC} dkms detected."
        dkms_installed=true
    fi

    if [ "$dkms_installed" = true ]; then
        if [ -d "${msi_ec_dir}" ]; then
            echo -e "${YELLOW}[WARN]${NC} msi-ec directory already exists, pulling latest changes..."
            git -C "${msi_ec_dir}" pull
        else
            echo -e "${GREEN}[INFO]${NC} Cloning msi-ec repository..."
            git clone https://github.com/BeardOverflow/msi-ec.git "${msi_ec_dir}"
        fi

        if [ -d "${msi_ec_dir}" ]; then
            echo -e "${GREEN}[INFO]${NC} Building and installing msi-ec kernel module using DKMS..."
            (cd "${msi_ec_dir}" && sudo make dkms-install)

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[INFO]${NC} msi-ec kernel module installed successfully via DKMS."
            else
                echo -e "${RED}[ERROR]${NC} Failed to install msi-ec kernel module via DKMS. Check make output for details."
            fi
            # Clean up
            echo -e "${GREEN}[INFO]${NC} Cleaning up msi-ec repository..."
            rm -rf "${msi_ec_dir}"
        else
            echo -e "${RED}[ERROR]${NC} Failed to clone msi-ec repository."
        fi
    fi
fi

# ---

## Install agsv1

echo -e "${GREEN}[INFO]${NC} Installing custom package: agsv1..."

# Check if agsv1 is already installed
if pkg_installed agsv1; then
    echo -e "${YELLOW}[SKIP]${NC} agsv1 is already installed. Skipping custom package build."
else
    agsv1_build_dir="${scrDir}/agsv1-build" # Temporary directory for building agsv1
    mkdir -p "${agsv1_build_dir}"

    if [ ! -d "${agsv1_build_dir}" ]; then
        echo -e "${RED}[ERROR]${NC} Failed to create directory ${agsv1_build_dir}. Cannot build agsv1."
    else
        # --- Install and Downgrade TypeScript if necessary ---
        REQUIRED_TS_VER="5.1.6-1"
        CURRENT_TS_VER=$(pacman -Q typescript 2>/dev/null | awk '{print $2}')

        if [ "$CURRENT_TS_VER" != "$REQUIRED_TS_VER" ]; then
            echo -e "${GREEN}[INFO]${NC} Ensuring typescript version ${REQUIRED_TS_VER} is installed for agsv1 build using 'downgrade' utility..."

            # First, ensure 'downgrade' is installed
            if ! pkg_installed downgrade; then
                echo -e "${YELLOW}[WARN]${NC} 'downgrade' utility not found. Attempting to install it via yay..."
                if pkg_installed yay; then
                    yay -S --noconfirm downgrade
                    if [ $? -ne 0 ]; then
                        echo -e "${RED}[ERROR]${NC} Failed to install 'downgrade' utility. Cannot guarantee specific typescript version. Aborting agsv1 installation."
                        rm -rf "${agsv1_build_dir}"
                        exit 1
                    fi
                else
                    echo -e "${RED}[ERROR]${NC} yay is not installed. Cannot automatically install 'downgrade'. Please install 'downgrade' manually from AUR. Aborting agsv1 installation."
                    rm -rf "${agsv1_build_dir}"
                    exit 1
                fi
            fi

            echo -e "${GREEN}[INFO]${NC} Running 'sudo downgrade typescript'. Please confirm adding to IgnorePkg."
            sudo downgrade typescript=5.1.6-1
            if [ $? -ne 0 ]; then
                echo -e "${RED}[ERROR]${NC} 'downgrade typescript' failed or was cancelled. Aborting agsv1 installation."
                rm -rf "${agsv1_build_dir}"
                exit 1
            fi
            echo -e "${GREEN}[INFO]${NC} typescript ${REQUIRED_TS_VER} should now be installed and ignored by pacman."
        else
            echo -e "${GREEN}[INFO]${NC} Correct typescript version (${REQUIRED_TS_VER}) already installed. Verifying it's ignored..."
            # Manually ensure IgnorePkg is set, in case downgrade was skipped or didn't add it
            PACMAN_CONF_PATH="/etc/pacman.conf"
            PKG_TO_IGNORE="typescript"

            if grep -qE "^IgnorePkg =.*\\b${PKG_TO_IGNORE}\\b" "$PACMAN_CONF_PATH"; then
                echo -e "${GREEN}[INFO]${NC} 'typescript' is correctly in pacman's IgnorePkg list."
            elif grep -q "^#IgnorePkg =" "$PACMAN_CONF_PATH"; then
                sudo sed -i "s/^#IgnorePkg =.*/IgnorePkg = ${PKG_TO_IGNORE}/" "$PACMAN_CONF_PATH"
                echo -e "${GREEN}[INFO]${NC} Uncommented and added 'typescript' to pacman's IgnorePkg list."
            elif grep -q "^IgnorePkg =" "$PACMAN_CONF_PATH"; then
                sudo sed -i "/^IgnorePkg =/ s/$/ ${PKG_TO_IGNORE}/" "$PACMAN_CONF_PATH"
                echo -e "${GREEN}[INFO]${NC} Added 'typescript' to existing pacman's IgnorePkg list."
            else
                sudo sed -i "/^\[options\]/a IgnorePkg = ${PKG_TO_IGNORE}" "$PACMAN_CONF_PATH"
                echo -e "${GREEN}[INFO]${NC} Added 'IgnorePkg = typescript' to pacman.conf."
            fi
        fi
        # --- End TypeScript Version Handling ---

        echo -e "${GREEN}[INFO]${NC} Creating PKGBUILD for agsv1 in ${agsv1_build_dir}..."
        cat <<EOF > "${agsv1_build_dir}/PKGBUILD"
# Maintainer: kotontrion <kotontrion@tutanota.de>

# This package is only intended to be used while migrating from ags v1.8.2 to ags v2.0.0.
# Many ags configs are quite big and it takes a while to migrate, therefore I made this package
# to install ags v1.8.2 as "agsv1", so both versions can be installed at the same time, making it
# possible to migrate bit by bit while still having a working v1 config around.
#
# First update the aylurs-gtk-shell package to v2, then install this one.
#
# This package won't receive any updates anymore, so as soon as you migrated, uninstall this one.

pkgname=agsv1
_pkgname=ags
pkgver=1.9.0
pkgrel=1
pkgdesc="Aylurs's Gtk Shell (AGS), An eww inspired gtk widget system."
arch=('x86_64')
url="https://github.com/Aylur/ags"
license=('GPL-3.0-only')
makedepends=('git' 'gobject-introspection' 'meson' 'glib2-devel' 'npm' 'typescript')
depends=('gjs' 'glib2' 'glibc' 'gtk3' 'gtk-layer-shell' 'libpulse' 'pam')
optdepends=('gnome-bluetooth-3.0: required for bluetooth service'
            'greetd: required for greetd service'
            'libdbusmenu-gtk3: required for systemtray service'
            'libsoup3: required for the Utils.fetch feature'
            'libnotify: required for sending notifications'
            'networkmanager: required for network service'
            'power-profiles-daemon: required for powerprofiles service'
            'upower: required for battery service')
backup=('etc/pam.d/ags')
source=("\$pkgname-\$pkgver.tar.gz::https://github.com/Aylur/ags/archive/refs/tags/v\${pkgver}.tar.gz"
        "git+https://gitlab.gnome.org/GNOME/libgnome-volume-control")
sha256sums=('962f99dcf202eef30e978d1daedc7cdf213e07a3b52413c1fb7b54abc7bd08e6'
            SKIP)

prepare() {
    cd "\$srcdir/\$_pkgname-\$pkgver"
    mv -T "\$srcdir"/libgnome-volume-control subprojects/gvc
}

build() {
    cd "\$srcdir/\$_pkgname-\$pkgver"
    npm install
    arch-meson build --libdir "lib/\$_pkgname" -Dbuild_types=true
    meson compile -C build
}

package() {
    cd "\$srcdir/\$_pkgname-\$pkgver"
    meson install -C build --destdir "\$pkgdir"
    rm \${pkgdir}/usr/bin/ags
    ln -sf /usr/share/com.github.Aylur.ags/com.github.Aylur.ags \${pkgdir}/usr/bin/agsv1
}
EOF
        echo -e "${GREEN}[INFO]${NC} PKGBUILD created successfully."

        echo -e "${GREEN}[INFO]${NC} Building and installing agsv1 using makepkg..."
        (cd "${agsv1_build_dir}" && makepkg -si --noconfirm)

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[INFO]${NC} agsv1 installed successfully."
        else
            echo -e "${RED}[ERROR]${NC} Failed to build and install agsv1. Check makepkg output for details."
        fi

        # Clean up
        echo -e "${GREEN}[INFO]${NC} Cleaning up agsv1 build directory..."
        rm -rf "${agsv1_build_dir}"
    fi
fi