#!/bin/bash

# getestet auf:
#
# - Ubuntu 12.04 LTS - Precise (getestet)
# - Ubuntu 14.04 LTS - Trusty (getestet)
# - Ubuntu 16.04 LTS - Xenial (getestet)
# - Debian 7 - Wheezy (getestet)
# - Debian 8 - Jessie (getestet)
# - Debian 9 - Strech (in Arbeit) - Fehlerhafte Packete: php-net-ipv4 (kein IPv4 Support mehr)


# Ubuntu Sources.List probleme bei minimal Installation Fix:
#
# cd /var/lib/apt
# sudo mv lists lists.old
# sudo mkdir -p lists/partial
# sudo apt-get update


# Script Version
VERSION="1.1"

# Debug Modus
DEBUG="0"

# Installationsscript Root-Gameservices:
PATH_HOME="/home/gameserver"
MASTER_SCRIPTS="rsync.gsi.g-portal.de::scripts.linux.rootserver/"
DEFAULT_GID=500
DEFAULT_UID=500

ALL=""screen" "cron" "rsync" "screen" "sqlite" "sqlite3" "zip" "unzip" "libglib2.0-0" "psmisc" "php-net-ipv4" "php-net-ipv6" "fail2ban" "sudo" "ntp""
DEBIAN_WHEEZY=""php5-cli" "php5-sqlite" "openjdk-6-jre""
DEBIAN_JESSIE=""php5-cli" "php5-sqlite" "openjdk-7-jre""
UBUNTU_XENIAL=""php7.0-cli" "php7.0-sqlite3" "openjdk-8-jre""



### Header ###
header() {
	echo
	ausgabe "##################################################"
	ausgabe "####        G-Portal GSI-Install-Script       ####"
	ausgabe "####           Script Version: $VERSION            ####"
	ausgabe "####             www.G-Portal.com             ####"
	ausgabe "####                    by                    ####"
	ausgabe "####               Lacrimosa99                ####"
	ausgabe "####     www.Devil-Hunter-Multigaming.de      ####"
	ausgabe "#### lacrimosa99@devil-hunter-multigaming.de  ####"
	ausgabe "##################################################"
}

### Farben ###
ausgabe() {
	case "$2" in
		"blau") echo -e "\033[1;34m$1\033[1;37m" ;;
		"rot") echo -e "\033[1;31m$1\033[1;37m" ;;
		"gruen") echo -e "\033[1;32m$1\033[1;37m" ;;
		"normal") echo -e "\033[0m" ;;
		*) echo -e "\033[1;37m$1\033[1;37m" ;;
	esac
}

### source.list ###
sourcelist() {
	if [ "$OS_DIST" == "Debian" ]; then
		if [ ! -f /etc/apt/sources.list.bak ]; then
			cp /etc/apt/sources.list /etc/apt/sources.list.bak
			sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list
		fi
	elif [ "$OS_DIST" == "Ubuntu" ] && [ "$OS_BRANCH" = "trusty" ] && [ ! -f /etc/apt/sources.list.d/ia32-libs-raring.list ]; then
		echo "deb http://old-releases.ubuntu.com/ubuntu/ raring main restricted universe multiverse" > /etc/apt/sources.list.d/ia32-libs-raring.list
	fi
}

### OS check ###
os_check() {
	OS=''

	if [ -f /etc/debian_version ]; then
		if [ "$DEBUG" == "1" ]; then
			apt-get -y install lsb-release
			ausgabe
		else
			apt-get -y install lsb-release > /dev/null 2>&1
		fi
		DISTRIBUTORID=`lsb_release -a 2> /dev/null | grep 'Distributor' | awk '{print $3}'`

		if [ "$DISTRIBUTORID" == "Ubuntu" ]; then
			OS_BRANCH=`lsb_release -a 2> /dev/null | grep 'Codename' | awk '{print $2}'`
			OS_DIST='Ubuntu'
			BIT=`getconf LONG_BIT`
			MANAGER="apt-get"
		elif [ "$DISTRIBUTORID" == "Debian" ]; then
			#OS_BRANCH=`cat /etc/*release | grep 'VERSION=' | awk '{print $2}' | tr -d '()"'`
			OS_BRANCH=`lsb_release -a 2> /dev/null | grep 'Codename' | awk '{print $2}'`
			OS_DIST='Debian'
			BIT=`getconf LONG_BIT`
			MANAGER="apt-get"
		fi

		if [ "$OS_DIST" == "" ]; then
			ausgabe "Error: Could not detect OS. Aborting" rot
			quit
		else
			ausgabe "Detected OS: $OS_DIST" gruen
		fi

		if [ "$OS_BRANCH" == "" ]; then
			ausgabe "Error: Could not detect Branch of OS. Aborting"	rot
			quit
		else
			ausgabe "Detected Branch: $OS_BRANCH" gruen
		fi

		if [ "$BIT" == "" ]; then
			ausgabe "Error: Could not detect Bit Version of OS. Aborting" rot
			quit
		else
			ausgabe "Detected Bit Version: $BIT Bit" gruen
		fi
	else
		ausgabe "Betriebssystem wird nicht unterstützt!" rot
		ausgabe 'Es wird nur Debian oder Ubuntu unterstützt.' rot
		quit
	fi
}

### Branch Version ###
branch_check() {
	if [ "$OS_BRANCH" = "squeeze" -o "$OS_BRANCH" = "wheezy" -o "$OS_BRANCH" = "precise" -o "$OS_BRANCH" = "trusty" ]; then
		DEPENT_PACKET=$DEBIAN_WHEEZY
		if [ "$DEBUG" == "1" ]; then
			echo "Nutze Packetliste DEBIAN_WHEEZY"
		fi
	elif [ "$OS_BRANCH" = "jessie" -o "$OS_BRANCH" = "stretch" -o "$OS_BRANCH" = "yakkety" ]; then
		DEPENT_PACKET=$DEBIAN_JESSIE
		if [ "$DEBUG" == "1" ]; then
			echo "Nutze Packetliste DEBIAN_JESSIE"
		fi
	elif [ "$OS_BRANCH" = "xenial" ]; then
		DEPENT_PACKET=$UBUNTU_XENIAL
		if [ "$DEBUG" == "1" ]; then
			echo "Nutze Packetliste UBUNTU_XENIAL"
		fi
	else
		ausgabe
		ausgabe "Error: nicht Unterstützter Codename "$OS_BRANCH" erkannt." rot
		ausgabe "" normal
		exit 0
	fi
}

### Bit Version ###
bit_check() {
	if [ "$BIT" = "64" ]; then
		bit_check="1"
		if [ "$OS_BRANCH" = "xenial" ]; then
			LIBARY="lib32ncurses5 lib32z1"
		elif [ "$OS_BRANCH" = "jessie" ]; then
			LIBARY="libc6-dev-i386 lib32ncurses5-dev gcc-multilib lib32stdc++6"
		elif [ "$OS_BRANCH" = "stretch" ]; then
			LIBARY="lib32z1 lib32ncurses5"
		else
			LIBARY="ia32-libs"
		fi

		ausgabe " > Prüfe/Installiere 32Bit Umgebung." blau
		if dpkg-query -s $LIBARY 2>/dev/null | grep -q "installed"; then
			ausgabe "   32Bit Umgebung bereits installiert." gruen
			ausgabe
		else
			ausgabe "   64Bit System gefunden. Installiere benötigte Pakete." rot
			ausgabe "   Dies kann etwas Dauern." rot
			ausgabe "   Wir bitten um Gedult." rot
			ausgabe
			dpkg --add-architecture i386 2>/dev/null
			if [ "$DEBUG" == "1" ]; then
				$MANAGER -y update
				$MANAGER -y install $LIBARY
			else
				$MANAGER -y update >/dev/null 2>&1
				$MANAGER -y install $LIBARY >/dev/null 2>&1
			fi
			ausgabe
		fi
	fi
}

### Installer ###
install() {
	unset="$program"
	if [ ! "$bit_check" == "1" ]; then
		ausgabe " > Prüfe/Installiere benötigte Programme:"
		echo
	fi

	for program in ${ALL[@]}; do
	if [ "$DEBUG" == "1" ]; then
		ausgabe " > Prüfe Installationskandidat: $program" blau
		$MANAGER install -y $program
	else
		ausgabe " > Prüfe Installationskandidat: $program" blau
		$MANAGER install -y $program >/dev/null 2>&1
	fi

	if dpkg-query -s "$program" 2>/dev/null | grep -q "installed"; then
		ausgabe "   $program wurde/ist installiert." gruen
		echo
	else
		echo
		ausgabe "   Fehler - Program installation $program fehlgeschlagen!" rot
		ausgabe "   Packet $program wurde nicht gefunden oder wurde ersetzt!" rot
		ausgabe "   Bitte wenden Sie sich an den Support." rot
		quit
	fi
	sleep 1
	done
}

install2() {
	unset="$program"
	for program in ${DEPENT_PACKET[@]}; do
	if [ "$DEBUG" == "1" ]; then
		ausgabe " > Prüfe Installationskandidat: $program" blau
		$MANAGER install -y $program
	else
		ausgabe " > Prüfe Installationskandidat: $program" blau
		$MANAGER install -y $program >/dev/null 2>&1
	fi

	if dpkg-query -s "$program" 2>/dev/null | grep -q "installed"; then
		ausgabe "   $program wurde/ist installiert." gruen
		echo
	else
		echo
		ausgabe "   Fehler - Program installation $program fehlgeschlagen!" rot
		ausgabe "   Packet $program wurde nicht gefunden oder wurde ersetzt!" rot
		ausgabe "   Bitte wenden Sie sich an den Support." rot
		quit
	fi
	sleep 1
	done
	sleep 1
}

### Frage Install ###
ask_install () {
	printf "Software installieren ? [J/n]: "; read -n1 ANSWER
	ask_install_return="1"
	ask_answer
}

### Frage Fortsetzen ###
ask_continue() {
	printf "Installation fortsetzen? [J/n]: "; read -n1 ANSWER
	ask_coninue_return="1"
	ask_answer
}

### Antwortabfrage ###
ask_answer() {
	case $ANSWER in
		y|Y|j|J)
			echo;;
		n|N)
			quit;;
		*)
			error;;
	esac
}

### Quit ###
quit() {
	echo; echo
	ausgabe "Installation wurde abgebrochen!" rot
	ausgabe "" normal
	exit 0
}

### Error ###
error() {
	echo
	echo
	ausgabe "Fehler: falsche Antwort!" rot
	ausgabe "Bitte nochmal versuchen." rot

	if [ "$ask_install_return" = "1" ]; then
		echo && ask_install
	elif [ "$ask_coninue_return" = "1" ]; then
		echo && ask_continue
	fi
}

#
# Beginn Installation
#
clear
header
echo
echo
os_check
branch_check
sourcelist
echo

# Auto-Installation Debian
ausgabe "Die Installation findet über das Installationsystem statt und es werden keine"
ausgabe "Dateien überschrieben. Es werden nur Programme installiert, die noch nicht vorhanden"
ausgabe "sind. Wir empfehlen stark, diesen Schritt nicht zu überspringen, damit wirklich alle"
ausgabe "benötigten Programme vorhanden sind."
ausgabe
ausgabe "Sollen benötigte Dienstprogramme automatisch installiert werden?" blau
ask_continue

echo
ausgabe " > aktualisiere Debian-Paketlisten..." blau
apt-get -y update
echo

if [ "$?" != "0" ]; then
	ausgabe "Es scheint ein Fehler beim Abrufen der Paketliste aufgetreten zu sein!" rot
	ausgabe "Bitte die obigen Meldungen prüfen." rot
	ask_continue
fi

echo "--------------------------------------------"
echo
ausgabe "Beginne Programm Installation:" blau
echo

bit_check
install
install2

echo
echo
echo "Verschiedene Funktionen im Gameserver-Webinterface benötigen derzeit einen FTP Account "
echo "auf dem Rootserver um verschiedene Konfigdateien zu lesen und zu schreiben."
echo "Unser Standard-FTP-Server ist Proftpd (weitere Informationen auf www.proftpd.org) "
echo
ausgabe "Proftpd wird nun automatisch installiert und konfiguriert. Das Webinterface übernimmt" rot
ausgabe "die Verwaltungs der FTP User für die Gameserver." rot
ausgabe "Alternativ kann die Installation übersprungen werden. Allerdings *muss* dann ein (anderer) FTP Server" rot
ausgabe "manuell installiert werden und auch die Userverwaltung erfolgt nicht automatisch." rot
ausgabe
ausgabe	"Wir empfehlen Proftpd automatisch installieren zu lassen." rot
ask_install
echo

unset="$program"
program="proftpd-basic"
echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
if [ "$DEBUG" == "1" ]; then
	ausgabe " > Prüfe Installationskandidat: $program" blau
	$MANAGER install -y $program
else
	ausgabe " > Prüfe Installationskandidat: $program" blau
	$MANAGER install -y $program >/dev/null 2>&1
fi

if dpkg-query -s "$program" 2>/dev/null | grep -q "installed"; then
	ausgabe "   $program wurde/ist installiert." gruen
	echo
else
	echo
	ausgabe "   Fehler - Program installation $program fehlgeschlagen!" rot
	ausgabe "   Es scheint ein Fehler beim Installieren der Pakete aufgetreten zu sein!" rot
	quit
fi

sed -i 's/inetd/standalone/g' /etc/proftpd/proftpd.conf
sed -i 's/LoadModule mod_facl.c//g' /etc/proftpd/modules.conf
sed -i 's/.*LoadModule mod_tls_memcache.c.*/#LoadModule mod_tls_memcache.c/g' /etc/proftpd/modules.conf
/etc/init.d/proftpd restart >/dev/null 2>&1
echo

if [ "$?" != "0" ]; then
	ausgabe "Es scheint ein Fehler beim Installieren von proftpd aufgetreten zu sein!" rot
	ausgabe "Bitte die obigen Meldungen prüfen und ggf. dem Support Bescheid sagen." rot
	ask_continue
else
	if [ -f /etc/proftpd.conf ]; then
		PROFTPD_CONF="/etc/proftpd.conf"
	elif [ -f /etc/proftpd/proftpd.conf ]; then
		PROFTPD_CONF="/etc/proftpd/proftpd.conf"
	else
		PROFTPD_CONF="nothing"
		echo "Keine ProFTPd-Konfiguration gefunden."
		echo "Wir können die vollständige Funktion des Gameserver-Services nicht garantieren!"
		ask_continue
	fi

	if [ "`cat $PROFTPD_CONF | grep -i 'END OF ROOT GSI PROFTPD SETTINGS' | grep -v grep`" = "" ]; then
		ausgabe "Konfiguration wird automatisch angepasst ..." gruen
		echo "" >> $PROFTPD_CONF
		echo "########### Nicht entfernen ! ############" >> $PROFTPD_CONF
		echo "# ACHTUNG die folgenden Zeilen sind notwendig für das Root Gameserver Interface" >> $PROFTPD_CONF
		echo "########### Do NOT remove ! ##############" >> $PROFTPD_CONF
		echo "# ATTENTION the following lines are required of the Root Gameserver Interface" >> $PROFTPD_CONF
		echo "" >> $PROFTPD_CONF
		echo "AuthPAM off" >> $PROFTPD_CONF
		echo "AuthUserFile /home/gameserver/gsi_ftp_user" >> $PROFTPD_CONF
		echo "RequireValidShell	off" >> $PROFTPD_CONF
		echo "DefaultRoot	~" >> $PROFTPD_CONF
		echo "############ END OF ROOT GSI PROFTPD SETTINGS #######################" >> $PROFTPD_CONF
	fi
fi

ausgabe "Systemvoraussetzungen erfüllt!" gruen
echo
echo "--------------------------------------------"
echo

if [ "`which php`" = "" ]; then
	if [ "`which php5`" = "" ]; then
		ausgabe "   Fehler: es konnte kein PHP-Kommandozeileninterpreter gefunden werden!" rot
		ausgabe "   PHP ist eine Scriptsprache, die zum Betrieb des Gameserversystems zwingend benötigt wird." rot
		ausgabe "   Bitte installieren sie zuerst diese Programme über einen Paketmanager und starten dann die Installation erneut!" rot
		ausgabe "   Hinweis: eine reine PHP-Installation ohne Zusatzmodule wie MySQL oder ähnliches ist ausreichend." rot

		if [ "$OS_DIST" = "debian"]; then
			echo
			echo "   Hinweis: der Paketname für den Interpreter ist 'php5-cli' für Debian Lenny und aufwärts."
			echo "   Am schnellsten ist die Installation mit 'apt-get update; apt-get install <paketname>' möglich."
		fi
		quit
	else
		PHP5_LOCATION=`which php5`
		PHP_DIR=`dirname $PHP5_LOCATION`
		cd $PHP_DIR
		echo "	 - erstelle Link 'php' -> 'php5'"
		ln -s php5 php
		cd $OLDPWD
	fi
fi

ausgabe "Beginne Gamemaster Installation:" gruen
sleep 1

echo
echo " > Lege Gruppe "gameserver" an."
sleep 1
GROUP_CHECK=$(cat /etc/group | grep gameserver:x:)
if [ "$GROUP_CHECK" = "" ]; then
	groupadd -g $DEFAULT_GID gameserver 2>/dev/null
	ausgabe "   Gruppe wurde erfolgreich angelegt." gruen
	ausgabe
elif [ ! "$GROUP_CHECK" == "gameserver:x:"$DEFAULT_GID":" ]; then
	if [ "$DEBUG" == "1" ]; then
		groupmod -g $DEFAULT_GID gameserver
		ausgabe '   Gruppe "gameserver" wurde auf GID "$DEFAULT_GID" geändert.'
	else
		groupmod -g $DEFAULT_GID gameserver >/dev/null 2>&1
		ausgabe '   Gruppe "gameserver" wurde auf GID "$DEFAULT_GID" geändert.'
	fi
else
	ausgabe "   Warnung: die Gruppe konnte nicht angelegt werden, eventuell ist sie schon vorhanden." rot
	ausgabe "   Dies kann von einer vorherigen Installation des Systems stammen, in diesem Fall kann" rot
	ausgabe "   mit der Installation fortgefahren werden." rot
fi
sleep 2

echo
echo " > Lege User "gameserver" an."
sleep 1
USER_CHECK=$(cat /etc/passwd | grep gameserver:x: | cut -c 1-21)
if [ "$USER_CHECK" = "" ]; then
	useradd -c Gameserver-System -d $PATH_HOME -g gameserver -s /bin/false -u $DEFAULT_UID gameserver >/dev/null 2>&1
	ausgabe "   User wurde erfolgreich angelegt." gruen
	ausgabe
elif [ ! "$USER_CHECK" == "gameserver:x:"$DEFAULT_GID":"$DEFAULT_UID":" ]; then
	if [ "$DEBUG" == "1" ]; then
		ausgabe
		usermod -u $DEFAULT_UID -g $DEFAULT_GID gameserver
		ausgabe
		ausgabe '   Gruppe des Users "gameserver" wurde auf Gruppe "gameserver" geändert.' gruen
		ausgabe
	else
		usermod -u $DEFAULT_UID -g $DEFAULT_GID gameserver >/dev/null 2>&1
		ausgabe '   Gruppe des Users "gameserver" wurde auf Gruppe "gameserver" geändert.' gruen
		ausgabe
	fi
else
	ausgabe "   Warnung: der User konnte nicht angelegt werden, eventuell ist er schon vorhanden." rot
	ausgabe "   Dies kann von einer vorherigen Installation des Systems stammen, in diesem Fall kann" rot
	ausgabe "   mit der Installation fortgefahren werden." rot
fi
sleep 2

echo
echo " > Lege Verzeichnisse an"
sleep 1
if [ ! -d $PATH_HOME ]; then
	mkdir -p $PATH_HOME && mkdir -p $PATH_HOME/scripts && mkdir -p $PATH_HOME/servers && mkdir -p $PATH_HOME/master
	if [ "$DEBUG" == "1" ]; then
		ausgabe
		chown -cR gameserver:gameserver $PATH_HOME
		ausgabe
	else
		chown -cR gameserver:gameserver $PATH_HOME >/dev/null 2>&1
	fi
	if [ "$?" != "0" ]; then
		ausgabe "   Fehler: das Verzeichnis $PATH_HOME und Unterverzeichnisse konnten nicht angelegt werden!" rot
		ausgabe "   Ohne diese Verzeichnisse ist das System nicht funktionsfähig. Bitte prüfen sie eventuelle Fehlermeldungen" rot
		ausgabe "   (eventuell Partition voll?) und führen sie die Installation dann noch einmal aus." rot
		ausgabe "" normal
		exit 0
	else
		ausgabe "   Verzeichnisse wurden erfolgreich angelegt." gruen
		ausgabe
	fi
else
	if [ "$DEBUG" == "1" ]; then
		chown -cR gameserver:gameserver $PATH_HOME
	else
		chown -cR gameserver:gameserver $PATH_HOME >/dev/null 2>&1
	fi
	ausgabe "   Warnung: das Verzeichniss konnte nicht angelegt werden, eventuell ist er schon vorhanden." rot
	ausgabe "   Dies kann von einer vorherigen Installation des Systems stammen, in diesem Fall kann" rot
	ausgabe "   mit der Installation fortgefahren werden." rot
fi
sleep 2

echo
echo " > Installiere Scripte..."
sleep 1
if [ "$DEBUG" == "1" ]; then
	rsync -au --log-file=/tmp/rsync.log "$MASTER_SCRIPTS" "$PATH_HOME"/scripts/
	ausgabe
else
	rsync -auq "$MASTER_SCRIPTS" "$PATH_HOME"/scripts/ 2> /tmp/rsync.log
fi
if [ "$?" != "0" ] || [ ! -f $PATH_HOME/scripts/servermonitor.php ]; then
	ausgabe "   Fehler: die Scripte konnten nicht vom Server heruntergeladen werden." rot
	ausgabe "   Dies kann mehrere Ursachen haben, eventuell ist RSync nicht voll funktionsfähig oder aber" rot
	ausgabe "   der Server kann nicht erreicht werden." rot
	ausgabe
	ausgabe "Ausgabe von RSync:" rot
	ausgabe
	cat /tmp/rsync.log
	rm /tmp/rsync.log > /dev/null 2>&1
	ausgabe
	ausgabe "Bitte wenden sie sich unter Angabe der obigen Meldung an den Support!" rot
	quit
else
	ausgabe "   Scripte wurden erfolgreich installiert."
	ausgabe
fi
rm /tmp/rsync.log >/dev/null 2>&1
sleep 2
exit 0
################################################################################  ab hier ist das Script noch in Arbeit!
################################################################################
cp $PATH_HOME/scripts/startproc /usr/bin/
chmod 755 /usr/bin/startproc

# ioncube installieren
PHP_INI=`php5 -r 'echo php_ini_loaded_file();'`

echo "Benutze PHP-Konfiguration: $PHP_INI"

cd $PATH_HOME/scripts/

OLDIONCUBE=`grep 'ioncube_loader_lin_5' $PHP_INI`
if [ "$OLDIONCUBE" = "" ]; then
	echo "Trage IONCUBE-Loader Erweiterung ein"
else
	echo "Ersetze vorhandenen IONCOBE Loader!"
	grep -v "ioncube_loader_lin_5" $PHP_INI > /tmp/php.ini
	mv /tmp/php.ini $PHP_INI
fi

KERNEL_ARCH=`uname -m`
if [ "`uname -m`" = "x86_64" ]; then
	if [ "$OS_VERSION" = "squeeze/sid" -o ${OS_VERSION:0:1} = "6" ]; then
		echo "zend_extension = $PATH_HOME/scripts/ioncube/ioncube_loader_lin_5.3_x64.so" >> $PHP_INI
	else
		echo "zend_extension = $PATH_HOME/scripts/ioncube/ioncube_loader_lin_5.2_x86_64.so" >> $PHP_INI
	fi
else 
	if [ "$OS_VERSION" = "squeeze/sid" -o ${OS_VERSION:0:1} = "6" ]; then
		echo "zend_extension = $PATH_HOME/scripts/ioncube/ioncube_loader_lin_5.3.so" >> $PHP_INI
	else
		echo "zend_extension = $PATH_HOME/scripts/ioncube/ioncube_loader_lin_5.2.so" >> $PHP_INI
	fi
fi

sed -i 's/memory_limit = .*/memory_limit = 64M/g' $PHP_INI

echo " > Richte crontab ein."
OLDCRONTAB=`grep 'scheduler.php' /etc/crontab 2>&1`

if [ "$OLDCRONTAB" = "" ]; then
	echo "	- Eintrag noch nicht vorhanden, füge ein."
else
	echo "	- Eintrag in crontab schon gefunden (frühere Installation?), ersetze."

	grep -v 'scheduler.php' /etc/crontab > /tmp/tmp_new_crontab
	mv /tmp/tmp_new_crontab /etc/crontab
fi

echo "* *	* * *	root php -q $PATH_HOME/scripts/scheduler.php" >> /etc/crontab

wget "http://wi.unitedcolo.de/ProductRootserver/gsi-redirect-experimental.sh"
bash gsi-redirect-experimental.sh

ausgabe
ausgabe "######################################################" gruen
ausgabe "Installation abgeschlossen !" gruen
ausgabe "######################################################" gruen
ausgabe "Das Gameserversystem ist jetzt aktiviert und wird in wenigen Minuten das erste Mal" gruen
ausgabe "automatisch gestartet. Falls sie es noch nicht getan haben, können Sie in ihrem Rootserverinterface" gruen
ausgabe "Gameserver einrichten, die dann automatisch gestartet werden." gruen
ausgabe
ausgabe "Hinweis: beim ersten Starten eines Spiels auf dem Rechner kann die Servereinrichtung" 
ausgabe "einige Minuten dauern, da zuerst die entsprechenden Spieldaten auf ihren Server kopiert werden."
ausgabe "Alle weiteren Server mit dem selben"
ausgabe "Spiel greifen dann auf die selben Spieldaten zurück und werden schneller eingerichtet."
