#!/bin/bash

# Root privileges check.
if [ $(id -u) -eq 0 ]; then
    echo "Error: the script must not be executed with root privileges."
    exit 1
fi

clear

#----------- QUESTIONS -----------------

# Ask if the user wants to change the default ssh port
echo "Do you want to change the default ssh port? (y/n)"
read change_ssh_port

# If the user wants to change the default ssh port
if [ "$change_ssh_port" == "y" ]; then
  echo "Enter the new ssh port:"
  read new1_ssh_port
else
  # Set the default port 22 in the new1_ssh_port variable
  new1_ssh_port=22
  # Warn that will be kept the default ssh port
  echo "OK. The default port $new1_ssh_port will be kept"
fi

# Ask if the user wants to create an additional user
echo "Do you want to create a secondary user? (y/n)"
read add_user

# If the user wants to create an additional user
if [ "$add_user" == "y" ]; then
  echo "Enter the new username:"
  read user_name
  echo "Enter the new user's password:"
  read user_password
  echo "Do you want to add an ssh port? Note that it will not be linked to the user but will be usable by everyone. (y/n)"
  read second_user_ssh_port

  # Ask for the second ssh port for the second user
  if [ "$second_user_ssh_port" == "y" ]; then
    echo "Enter the second ssh port:"
    read new2_ssh_port
  fi

else
  # Warn the user that no additional users will be created
  echo "No additional user will be created."
fi


# Ask for the Laravel project name
echo "Enter the Laravel project name: (without spaces)"
read project_name

# Ask for the credentials that will be created and used by the project
echo "Enter the username that the project will use to access the db: (will be created)"
read db_username
echo "Enter the password for the user that the project will use to access the db:"
read db_password
echo "Enter the db name:"
read db_name

#------------ END QUESTIONS --------------

# Update the repositories
sudo apt update && sudo apt upgrade -y

# Install Apache
sudo apt install apache2 -y

# Install PHP
sudo apt install php libapache2-mod-php php-mysqlnd php7.4-cli php7.4-dev libmcrypt-dev php -y

# Install MariaDB
sudo apt install mariadb-server mariadb-client -y

# Configure MariaDB with the specified credentials
sudo mysql <<EOF
CREATE DATABASE $db_name;
CREATE USER '$db_username'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON * . * TO '$db_username'@'localhost';
FLUSH PRIVILEGES;
EOF

# Install phpMyAdmin
sudo apt install phpmyadmin -y

# Configure phpMyAdmin to work with Apache
sudo ln -s /usr/share/phpmyadmin /var/www/html

#----------------------

# Create the project directory
sudo mkdir /var/www/html/$project_name

# Install Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Install Laravel via Composer
cd /var/www/html/$project_name
sudo composer create-project --prefer-dist laravel/laravel .

# Configure the database in .env
sudo sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=mariadb/g" .env
sudo sed -i "s/DB_HOST=127.0.0.1/DB_HOST=localhost/g" .env
sudo sed -i "s/DB_PORT=3306/DB_PORT=3306/g" .env
sudo sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$db_name/g" .env
sudo sed -i "s/DB_USERNAME=root/DB_USERNAME=$db_username/g" .env
sudo sed -i "s/DB_PASSWORD=/DB_PASSWORD=$db_password/g" .env

# reload to apply changes
sudo systemctl reload apache2

# Assign the correct permissions to the directory
sudo chown -R www-data:www-data /var/www/html/$project_name
sudo chmod -R 755 /var/www/html/$project_name

#------------------------

# Create a user "$user_name" and set permissions to access the site's root if the user has chosen to create a secondary one
if [ "$add_user" == "y" ]; then
  sudo apt install whois -y
  sudo useradd -m -s /bin/bash -p $(mkpasswd --hash=SHA-512 $user_password) $user_name --home-dir /var/www/html/$project_name/public --gid www-data
  sudo usermod -a -G sudo $user_name
fi

for dir in /var /var/www; do
    sudo chown root:root $dir
    sudo chmod 0755 $dir
done

sudo chown -R www-data:www-data /var/www/html/$project_name

# Assign permissions to the www-data user and the secondary user
sudo chmod -R 755 /var/www/html/$project_name/public
sudo chown -R www-data:www-data /var/www/html/$project_name/public
#if [ "$add_user" == "y" ]; then
#  chown -R $user_name:$user_name /var/www/html/$project_name/public
#fi

# Configure sftp access for the user "$user_name"
# These two commented lines below are used to force the user to use only sftp and are commented by default.
# sudo sed -i 's/Subsystem sftp /usr/lib/openssh/sftp-server/Subsystem sftp internal-sftp/g' /etc/ssh/sshd_config
# echo "ForceCommand internal-sftp" | sudo tee -a /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo "Match User $user_name" | sudo tee -a /etc/ssh/sshd_config
echo "AllowTcpForwarding no" | sudo tee -a /etc/ssh/sshd_config
echo "X11Forwarding no" | sudo tee -a /etc/ssh/sshd_config

# Set the ssh port/s to the one/s specified by the user.
sudo sed -i "s/#Port 22/Port ${new1_ssh_port}\nPort ${new2_ssh_port}/g" /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo systemctl restart sshd
sudo service sshd restart

# Assign read and write permissions to the www-data group that includes $user_name and www-data
sudo chmod 770 /var/www/html/$project_name/public

# Disable directory indexing
sudo sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/g' /etc/apache2/apache2.conf

# Disable the default config
cd /etc/apache2/sites-enabled/
sudo a2dissite 000-default.conf

# Create the file /etc/apache2/sites-available/$project_name.conf to use the directory /var/www/html/$project_name/public as the default webroot
sudo echo "<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/$project_name/public
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>" | sudo tee /etc/apache2/sites-available/$project_name.conf

# Enable $project_name.conf and reload apache2
cd /etc/apache2/sites-available/
sudo a2ensite $project_name.conf
sudo systemctl reload apache2

# Create a symlink in the directory /var/www/html/$project_name/public to access phpMyAdmin, which is located in /usr/share/phpmyadmin
sudo ln -s /usr/share/phpmyadmin/ /var/www/html/$project_name/public

# THIS IS ALSO PART OF THE SUMMARY BUT UGLY TO LOOK AT
server_ip=$(curl -s ifconfig.me)
phpmyadmin_username=$(sudo grep -oP "(?<=^\\\$dbuser=')[^']+" /etc/phpmyadmin/config-db.php)
phpmyadmin_password=$(sudo grep -oP "(?<=^\\\$dbpass=')[^']+" /etc/phpmyadmin/config-db.php)

echo ""
# SUMMARY
echo ---------- SUMMARY ----------
echo "server ip: http://$server_ip/"
echo "project name: $project_name"
echo "project path: /var/www/html/$project_name/"
echo "webroot: /var/www/html/$project_name/public"
echo "database user: $db_username"
echo "database user password: $db_password"
echo "sftp/ssh other user: $user_name"
echo "sftp/ssh other user's password: $user_password"
echo "other sftp/ssh user port: $new2_ssh_port"

echo "phpmyadmin username: $phpmyadmin_username"
echo "phpmyadmin password: $phpmyadmin_password"