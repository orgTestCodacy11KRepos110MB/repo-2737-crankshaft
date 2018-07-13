#!/bin/bash -e

# Set lang
SETLANG=en_GB

sudo sed -i -e '/^#/! s/./# &/' /etc/locale.gen # disable all entries by adding # in line start
sudo sed -i "s/^# $SETLANG.UTF-8 UTF-8/$SETLANG.UTF-8 UTF-8/" /etc/locale.gen # enable lang
sudo dpkg-reconfigure --frontend=noninteractive locales
sudo update-locale LANG=$SETLANG.UTF-8

#link graphics libs
ln -s /opt/vc/lib/libbrcmEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so
ln -s /opt/vc/lib/libbrcmGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so
ln -s /opt/vc/lib/libbrcmOpenVG.so /usr/lib/arm-linux-gnueabihf/libOpenVG.so
ln -s /opt/vc/lib/libbrcmWFC.so /usr/lib/arm-linux-gnueabihf/libWFC.so

# we don't need to resize the root part
sed -i 's/ init\=.*$//' /boot/cmdline.txt

# config.txt
echo "" >> /boot/config.txt
echo "# Custom power settings" >> /boot/config.txt
echo "max_usb_current=1" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Disable the PWR LED." >> /boot/config.txt
echo "dtparam=pwr_led_trigger=none" >> /boot/config.txt
echo "dtparam=pwr_led_activelow=off" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# Disable Rainbow splash" >> /boot/config.txt
echo "disable_splash=1" >> /boot/config.txt

echo "" >> /boot/config.txt
echo "# GPU Mem" >> /boot/config.txt
echo "gpu_mem=256" >> /boot/config.txt

# pulseaudio
cat /etc/pulse/pulseaudio_daemon.conf >> /etc/pulse/daemon.conf
sed -i 's/load-module module-udev-detect/load-module module-udev-detect tsched=0/' /etc/pulse/default.pa
echo 'load-module module-mmkbd-evdev device=/dev/gpio2kbd' >> /etc/pulse/default.pa
echo 'set-sink-volume 0 52428' >> /etc/pulse/default.pa

# wallaper's
ln -s /boot/crankshaft/wallpaper.png /home/pi/wallpaper.png
ln -s /boot/crankshaft/wallpaper-night.png /home/pi/wallpaper-night.png
ln -s /boot/crankshaft/wallpaper-devmode.png /home/pi/wallpaper-devmode.png
ln -s /boot/crankshaft/wallpaper-devmode-night.png /home/pi/wallpaper-devmode-night.png

# triggerhappy
sed -i 's/user nobody/user pi/' /lib/systemd/system/triggerhappy.service
ln -s /boot/crankshaft/triggerhappy.conf /etc/triggerhappy/triggers.d/crankshaft.conf

# set the hostname
echo "crankshaft" > /etc/hostname
sed -i "s/raspberrypi/crankshaft/" /etc/hosts

# fix watchdog module (seems to be renamed on latest versions)
CHECK=`modprobe --dry-run bcm2835_wdt`
if [ $CHECK == "" ]; then
    sed -i "s/bcm2835_wdog/bcm2835_wdt/" /etc/modules
fi
CHECK=`modprobe --dry-run bcm2708_wdt`
if [ $CHECK == "" ]; then
    sed -i "s/bcm2708_wdog/2708_wdt/" /etc/modules
fi

# Set default startup services state
systemctl enable gpio2kbd.service
systemctl enable crankshaft.service
systemctl enable user_startup.service
systemctl enable devmode.service
systemctl enable debugmode.service
systemctl enable display.service
systemctl enable user_startup.service
systemctl enable fake-hwclock.service
systemctl enable update.service
systemctl enable usbrestore.service
systemctl enable usbdetect.service
systemctl enable daymode.timer
systemctl enable nightmode.timer
systemctl enable tap2wake.service
systemctl enable openauto.service
systemctl enable gpiotrigger.service
systemctl enable timerstart.service
systemctl enable regensshkeys.service
systemctl enable ssh.service
systemctl disable rpicamserver.service
systemctl disable wpa_supplicant.service
systemctl disable networking.service
systemctl disable dhcpcd.service
systemctl disable regenerate_ssh_host_keys.service
systemctl disable wifisetup.service
systemctl disable systemd-rfkill.service
systemctl disable systemd-rfkill.socket
systemctl disable systemd-timesyncd.service
systemctl disable hwclock-load.service
systemctl disable hwclock-save.service
systemctl disable resize2fs_once.service
systemctl disable bluetooth.service
systemctl disable hciuart.service
systemctl disable hostapd.service
systemctl disable dnsmasq.service
systemctl disable hotspot.service
systemctl disable systemd-backlight@.service
systemctl disable alsa-restore.service
rm /lib/systemd/system/systemd-rfkill.service
rm /lib/systemd/system/systemd-rfkill.socket
rm /lib/systemd/system/apt-daily.timer
rm /lib/systemd/system/apt-daily.service
rm /lib/systemd/system/apt-daily-upgrade.timer
rm /lib/systemd/system/apt-daily-upgrade.service
rm /etc/systemd/system/timers.target.wants/apt-daily.timer
rm /etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer
rm /lib/systemd/system/timers.target.wants/systemd-tmpfiles-clean.timer
rm /lib/systemd/system/alsa-restore.service
rm /lib/systemd/system/systemd-backlight@.service
systemctl daemon-relaod

# set custom boot splash
plymouth-set-default-theme crankshaft

# create lib cache
ldconfig

# add gettys
systemctl enable getty@tty3.service

# enable splash and set default console
sed -i 's/console=tty1/console=tty3/' /boot/cmdline.txt

# add special settings
sed -i 's/$/ logo.nologo loglevel=0 vt.global_cursor_default=0 noswap splash plymouth.ignore-serial-consoles consoleblank=0 ipv6.disable=1 fastboot/' /boot/cmdline.txt

# Banner for ssh
sed -i 's/#Banner none/Banner \/etc\/issue.net/' /etc/ssh/sshd_config

# Lisen on all interfaces ssh
sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

# OS Name
STRING="Welcome to Crankshaft CarOS Alpha (${IMG_DATE} / ${BUILDHASH})"
sed -i 's/PRETTY_NAME=.*/PRETTY_NAME="'${STRING}'"/g' /usr/lib/os-release
echo "$STRING" > /etc/issue
echo "" >> /etc/issue
echo "$STRING" > /etc/issue.net
echo "" >> /etc/issue.net

# wifi
rm /etc/wpa_supplicant/wpa_supplicant.conf
ln -s /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

# Enable systemd timesync
sed -i 's/#NTP=.*/NTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org/g' /etc/systemd/timesyncd.conf
sed -i 's/#FallbackNTP=.*/FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org/g' /etc/systemd/timesyncd.conf

# add alias for mc to stay inside folder after exit mc
echo "" >> /etc/bash.bashrc
echo "alias mc='. /usr/share/mc/bin/mc-wrapper.sh'" >> /etc/bash.bashrc

# enable auto detection display
#sed -i 's/DISPLAY_AUTO_DETECT=0/DISPLAY_AUTO_DETECT=1/' /boot/crankshaft/crankshaft_env.sh

# Setup watchdog
sed -i 's/.*max-load-1	.*/max-load-1		= 2/' /etc/watchdog.conf
sed -i 's/.*watchdog-device.*/watchdog-device		= \/dev\/watchdog/' /etc/watchdog.conf

# Setup kernel panic behaviour
sed -i 's/.*kernel-panic.*//g' /etc/sysctl.conf
echo "kernel-panic = 10" >> /etc/sysctl.conf