# Script for setting up a Laravel project on an Ubuntu server

This script sets up a Laravel project on an Ubuntu server. It will ask a few questions and then install and configure everything needed to run a Laravel project.

## Prerequisites

- This script requires an Ubuntu server with root access. It has been tested on Ubuntu 20.04 and Ubuntu 22.04.
- You MUST open port 80 (SSL/TLS is not configured during the script, you must configure it manually.)

## Usage

1. Clone the repository

```
git clone https://github.com/daddyparodz/my-scripts.git
```

2. cd into the directory 

```
cd my-scripts/laravel-autosetup/
```

3. cd into the script directory

```
cd my-scripts
```

4. Make the script executable

```
sudo chmod +x laravel-autosetup.sh
```

5. Run  the  script

```
./laravel-autosetup.sh
```

The script will ask a few questions and then install and configure everything needed to run a Laravel project

__WARN:__ when the installation asks for "Web server to reconfigure automatically:" select with the spacebar apache2 and then tab to Ok, otherwise the script will not work.

*if you're using ubuntu 22.04 or later note that there will be no gui but it will ask you to type 1 (apache2) or 2 (lighttpd) and you must type 1.

__WARN:__ when the installation asks for "Configure database for phpmyadmin with dbconfig-common?" select Yes and then enter, otherwise the database will not work. 
Set a random password in the mysql application password for phpmyadmin, it will be printed at the end of the script as a reminder. 

**WARN:** when the installation asks "Continue as root/super user [yes]?" press ENTER. This step is necessary even if it says "do not do it" because normally you wouldn't create the project into the /var/www/html, but that's the way I tested and it works just as fine.



## What the script does

The script will do the following:

* Ask if the user wants to change the default SSH port.

* Ask if the user wants to create an additional user.

* Ask for the name of the Laravel project.

* Ask for the credentials that will be created and used by the project.

* Update the repositories.

* Install Apache.

* Install PHP 7.4.

* Install MariaDB.

* Configure MariaDB with the specified credentials.

* Install phpMyAdmin.

* Create the project directory.

* Install Composer.

* Install Laravel via Composer.

* Configure the database in .env.

* Assign the correct permissions to the directory.

* Create a user and set permissions to access the site's root if the user has chosen to create a secondary one.

* Configure SFTP access for the user if a secondary user has been created

* Gives the summary of everything including the credentials at the end of the script, ready to be copied.

## License

The code is available under the MIT license.