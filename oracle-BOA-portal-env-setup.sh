#! /bin/sh
# This script is used to setup the environment in the Oracle cloud for BOA-Portal

# Update and upgrade the system
echo "Updating and upgrading the system"
sudo apt-get update -y
sudo apt-get upgrade -y
echo ""
echo "Deactivating iptables firewall"
# Setup the firewall rules
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -F
echo ""
echo "Installing ufw firewall and activating it"

sudo apt install ufw
sudo ufw allow ssh
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp

sudo ufw enable -y
sudo ufw status
echo ""
echo "ufw firewall is now active with ssh, 80 and 443 ports open"

# Install the required packages
echo ""

echo "ufw firewall is now active with ssh, 80 and 443 ports open"

# Checking the Doker installation
echo ""
echo "Checking the Docker installation"
which docker

if [ $? -eq 0 ]
then
    docker --version | grep "Docker version"
    if [ $? -eq 0 ]
    then
        echo "docker already installed so skipping it"
    else
        echo "installing docker"
        sh ./docker-installation.sh
    fi
else
    echo "installing docker" >&2
    sh ./docker-installation.sh
fi

# Setting permissions for docker
sudo groupadd docker
sudo usermod -aG docker ${USER}
su -s ${USER}

docker run hello-world
# Change directory to the home directory
cd ~

# Installing Laravel
echo ""
echo "Installing Laravel"

# Install Laravel with Sail... (https://laravel.com/docs/9.x#getting-started-on-linux)
docker run --rm \
    --pull=always \
    -v "$(pwd)":/opt \
    -w /opt \
    laravelsail/php81-composer:latest \
    bash -c "laravel new BOA-Editors-Portal && cd BOA-Editors-Portal && php ./artisan sail:install --with=mysql,redis,meilisearch,mailhog,selenium "

cd BOA-Editors-Portal

./vendor/bin/sail pull mysql
./vendor/bin/sail build

CYAN='\033[0;36m'
LIGHT_CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""

if sudo -n true 2>/dev/null; then
    sudo chown -R $USER: .
    echo -e "${BOLD}Get started with:${NC} cd BOA-Editors-Portal && ./vendor/bin/sail up"
else
    echo -e "${BOLD}Please provide your password so we can make some final adjustments to your application's permissions.${NC}"
    echo ""
    sudo chown -R $USER: .
    echo ""
    echo -e "${BOLD}Thank you! We hope you build something incredible. Dive in with:${NC} cd BOA-Editors-Portal && ./vendor/bin/sail up"
fi

echo ""
echo "Installing Tailwind CSS"

./vendor/bin/sail npm install

./vendor/bin/sail npm install -D tailwindcss postcss autoprefixer
./vendor/bin/sail npx tailwindcss init -p


# Editing the tailwind.config.js file to add contents option
sed -i 's/contents: [],/contents: ["./resources/**/*.blade.php", "./resources/**/*.js","./resources/**/*.vue"],/g' tailwind.config.js

# Add the @tailwind directives for each of Tailwind’s layers to your ./resources/css/app.css file.

echo "@tailwind base; 
@tailwind components; 
@tailwind utilities;" >> ./resources/css/app.css

echo "Tailwind CSS installed"

# Installing Vue 3

echo "Installing Vue 3"

./vendor/bin/sail npm install vue@next vue-loader@next
./vendor/bin/sail npm i @vitejs/plugin-vue

# overwriting the vite.config.js file with new contents
echo "// vite.config.js
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue'


export default defineConfig({
    plugins: [
        vue(),
        laravel([
            'resources/css/app.css',
            'resources/js/app.js',
        ]),
    ],
});" > ./vite.config.js






