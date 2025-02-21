#!/bin/bash
echo "Userdata script started" >> /var/log/userdata.log
set -e  # Exit script if any command fails

if [ -f /etc/redhat-release ]; then
  OS="centos"
  PACKAGE_MANAGER="yum"
elif [ -f /etc/lsb-release ]; then
  OS="ubuntu"
  PACKAGE_MANAGER="apt-get"
else
  echo "Unsupported OS"
  exit 1
fi

# Update and install required packages
if [ "$OS" == "centos" ]; then
  sudo $PACKAGE_MANAGER update -y
  sudo $PACKAGE_MANAGER install -y cronie git unzip
  sudo systemctl enable crond
  sudo systemctl start crond
elif [ "$OS" == "ubuntu" ]; then
  sudo $PACKAGE_MANAGER update -y
  sudo $PACKAGE_MANAGER install -y cron git unzip
  sudo systemctl enable cron
  sudo systemctl start cron
fi

#Make sure HOME is is root.
if [ ! -d "$HOME" ]; then
  HOME="root"
  echo "Directory $LAB_DIR has been deleted."
fi

LAB_DIR="$HOME/lab"
# check for install directory and remove if exists
if [ -d "$LAB_DIR" ]; then
  rm -rf "$LAB_DIR"
  echo "Directory $LAB_DIR has been deleted."
fi
# Set up lab directory

git clone https://github.com/jdschmitz15/jds-lab-demo.git "$LAB_DIR"
chmod +x "$LAB_DIR"/tg-check*

TRAFFIC_GEN_VERSION="v1.0.5"
# Download and configure traffic generator
TG_ZIP="/tmp/linux_amd64.zip"
TG_URL="https://github.com/brian1917/traffic-generator/releases/download/$TRAFFIC_GEN_VERSION/linux_amd64.zip"

curl -L "$TG_URL" -o "$TG_ZIP"
unzip -o "$TG_ZIP" -d /tmp/
mv /tmp/linux_amd64/traffic-generator "$LAB_DIR/"
chmod +x "$LAB_DIR/traffic-generator"
rm -rf /tmp/linux_amd64 "$TG_ZIP"

# Run traffic check script
/$LAB_DIR/tg-check.sh /$LAB_DIR /$LAB_DIR/traffic.csv > /dev/null 2>&1

# Set up cron jobs
CRON_FILE="/tmp/mycron"
cat <<EOL > "$CRON_FILE"
*/5 * * * *  /$LAB_DIR/tg-check.sh /$LAB_DIR /$LAB_DIR/traffic.csv > /dev/null 2>&1
EOL

# If using Terraform, append dynamically:
# if [[ -n "${azurerm_linux_virtual_machine.ticketing-jump01.public_ip_address}" ]]; then
#   echo "* * * * *  telnet ${azurerm_linux_virtual_machine.ticketing-jump01.public_ip_address} 22 -t 10 >> /tmp/DB.log" >> "$CRON_FILE"
# fi

crontab "$CRON_FILE"
rm -f "$CRON_FILE"
