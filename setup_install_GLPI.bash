#!/bin/bash

set -e

# === CONFIGURATION ===
DB_NAME="glpi"
DB_USER="glpiuser"
DB_PASS="glpi"
GLPI_DIR="/var/www/html/glpi"
GLPI_DATA_DIR="/var/lib/glpi"
GLPI_PUBLIC_DIR="${GLPI_DIR}"
PHP_VERSION="8.2"
APACHE_USER="www-data"

echo "🔄 Mise à jour du système..."
apt update && apt upgrade -y

echo "📦 Installation des outils de base..."
apt install -y software-properties-common lsb-release apt-transport-https ca-certificates curl wget unzip dos2unix gnupg2
apt install -y curl wget jq unzip

echo "🧰 Ajout manuel du dépôt PHP (Sury) pour Debian 12..."
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
echo "deb https://packages.sury.org/php/ bookworm main" > /etc/apt/sources.list.d/php.list
apt update

echo "📥 Installation de PHP ${PHP_VERSION} et des extensions nécessaires..."
apt install -y apache2 mariadb-server php${PHP_VERSION} \
php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-mysql php${PHP_VERSION}-curl \
php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-ldap \
php${PHP_VERSION}-apcu php${PHP_VERSION}-zip php${PHP_VERSION}-bz2 php${PHP_VERSION}-intl \
php${PHP_VERSION}-bcmath php${PHP_VERSION}-readline \
php${PHP_VERSION}-opcache php${PHP_VERSION}-imagick php${PHP_VERSION}-soap \
php${PHP_VERSION}-exif

echo "⚙️ Configuration PHP..."
PHP_INI="/etc/php/${PHP_VERSION}/apache2/php.ini"
sed -i 's/^memory_limit = .*/memory_limit = 512M/' $PHP_INI
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' $PHP_INI
sed -i 's/^post_max_size = .*/post_max_size = 100M/' $PHP_INI
sed -i 's/^;session.cookie_httponly.*/session.cookie_httponly = 1/' $PHP_INI
sed -i 's/^session.cookie_httponly.*/session.cookie_httponly = 1/' $PHP_INI

echo "▶️ Activation de MariaDB et Apache..."
systemctl enable --now mariadb apache2

echo "🔐 Sécurisation de MariaDB (manuel recommandé)..."
echo "⚠️ mysql_secure_installation est interactif. Lancez-le manuellement après le script si nécessaire."

echo "🗃️ Création de la base de données GLPI et utilisateur..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "🌐 Téléchargement de la dernière version stable de GLPI..."
cd /tmp
GLPI_URL=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep "browser_download_url.*glpi-[0-9]*\.[0-9]*\.[0-9]*\.tgz" | cut -d '"' -f 4)
wget -O glpi.tgz "$GLPI_URL"

echo "📂 Extraction de GLPI..."
tar -xzf glpi.tgz
rm -f glpi.tgz

echo "🚚 Déploiement de GLPI dans ${GLPI_DIR}..."
rm -rf $GLPI_DIR
mv glpi $GLPI_DIR

echo "📁 Déplacement du répertoire de données hors du webroot pour sécurité..."
echo "⚠️ Suppression du contenu existant dans ${GLPI_DATA_DIR} (s'il y en a)..."
rm -rf ${GLPI_DATA_DIR}/*
mkdir -p ${GLPI_DATA_DIR}

echo "🚚 Déplacement des fichiers de 'files' vers ${GLPI_DATA_DIR}..."
mv ${GLPI_DIR}/files/* ${GLPI_DATA_DIR}/

echo "🔗 Création du lien symbolique vers le dossier de données..."
rm -rf ${GLPI_DIR}/files
ln -s ${GLPI_DATA_DIR} ${GLPI_DIR}/files

echo "🔒 Attribution des droits..."
chown -R ${APACHE_USER}:${APACHE_USER} ${GLPI_DIR} ${GLPI_DATA_DIR}
find ${GLPI_DIR} -type d -exec chmod 755 {} \;
find ${GLPI_DIR} -type f -exec chmod 644 {} \;

echo "🧱 Création du VirtualHost Apache sécurisé..."
cat <<EOL > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot ${GLPI_PUBLIC_DIR}

    <Directory ${GLPI_PUBLIC_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOL

echo "📡 Activation de la configuration Apache..."
a2dissite 000-default.conf
a2ensite glpi.conf
a2enmod rewrite
a2enmod php${PHP_VERSION}
systemctl reload apache2

echo ""
echo "✅✅✅ Installation complète de GLPI terminée ! ✅✅✅"
echo "🌐 Accédez à GLPI via : http://<votre-ip> pour finaliser l'installation."
echo "📂 Dossier public      : ${GLPI_PUBLIC_DIR}"
echo "📂 Dossier de données  : ${GLPI_DATA_DIR}"
echo "🗃️ Base de données     : ${DB_NAME}"
echo "👤 Utilisateur MariaDB : ${DB_USER}"
echo "🔑 Mot de passe DB     : ${DB_PASS}"
