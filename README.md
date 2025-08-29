# 🚀 Script d'installation automatique de GLPI sur Debian 12

Ce script Bash installe et configure **GLPI** avec **Apache**, **MariaDB** et **PHP 8.2** sur **Debian 12**. Il télécharge automatiquement la **dernière version stable de GLPI** depuis GitHub, configure l'environnement, sécurise l'installation et déploie GLPI prêt à l'emploi.

---

## 🧰 Prérequis

- Debian 12 (Bookworm)
- Droits root ou sudo
- Accès à Internet

---

## 🧪 Contenu du script

### Ce que le script fait :
- Met à jour le système
- Ajoute le dépôt PHP Sury pour PHP 8.2
- Installe Apache, MariaDB, PHP 8.2 et toutes les extensions nécessaires
- Configure PHP pour GLPI
- Crée la base de données, l'utilisateur et assigne les droits
- Télécharge la dernière version stable de GLPI depuis GitHub
- Déplace les fichiers de données en dehors du webroot (`/var/lib/glpi`)
- Configure Apache avec un VirtualHost dédié
- Configure les permissions
- Redémarre les services nécessaires

---

## ⚙️ Variables de configuration

Tu peux modifier ces variables en haut du script selon tes besoins :

```bash
DB_NAME="glpi"
DB_USER="glpiuser"
DB_PASS="glpi"
GLPI_DIR="/var/www/html/glpi"
GLPI_DATA_DIR="/var/lib/glpi"
PHP_VERSION="8.2"
APACHE_USER="www-data"

🚀 Utilisation
Rends le script exécutable :

chmod +x install-glpi.sh

Lance-le avec sudo ou en tant que root :

sudo ./install-glpi.sh

📌 À faire après l'installation
Accéder à GLPI via ton navigateur :

http://<adresse-ip-de-ton-serveur>

🔐 Sécurité
⚠️ Attention : Le mot de passe de la base de données est actuellement stocké en clair dans le script.
Pour une utilisation en production, il est fortement recommandé de :

> Utiliser des variables d’environnement ou un fichier .env
> Sécuriser l’accès au script et aux journaux d’exécution
> Mettre en place un certificat SSL (Let's Encrypt)


📂 Emplacements clés
Élément	             Emplacement par défaut
Dossier public GLPI	 /var/www/html/glpi
Dossier de données	 /var/lib/glpi
Configuration Apache /etc/apache2/sites-available/glpi.conf
Logs Apache	         /var/log/apache2/glpi_error.log

✅ Auteurs: herve-mtp

