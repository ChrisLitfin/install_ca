#!/bin/bash

#See information below at [Step 0]...

#####################################################################################################################################
# HELPER FUNCTIONS TO DO VARIOUS THINGS NON-REPETITIVELY

#generates a timestamp
timestamp(){
	date +%s
	}
startts=$(timestamp)

#Exstracts the substring between $2 and $3 in $1
subStrBetween(){
out="$1"

out=${out##*"$2"}
out=${out%%"$3"*}

echo $out

}


#Gets "real" (i.e. not localhost 127.0.0.1) IPv4 address of this computer
myip(){
#	local _ip _line
#	while IFS=$': \t' read -a _line ;do
#		[ -z "${_line%inet}" ] && _ip=${_line[${#line[1]}>4?1:2]} && 
#			[ "${_ip#127.0.0.1}" ] &&  echo $_ip && return 0
#		done< <(LANG=C /sbin/ifconfig)

ipstr=$(subStrBetween "$(ip a)" "inet " "/")
echo $ipstr

}


#Gets and confirms input from a user
# $1 =0 if non-protected, =1 if protected (i.e. password)
# $2 Message for prompt
# $3 Usename for prompt
# $4 Prompt text colour and formatting string
# $5 Default option (not available if protected)
# i.e. =$(getInput 1 "Message for Prompt" "User_for_prompt" "textcol" "default_value")
getInput(){

if [ "$5" != "" ] && ! [ $1 -eq 1 ]
then
	defmsg="\n[Leave blank for default """$5"""]"
	blankmsg=""
else
	defmsg=""
	blankmsg=" or are blank"
fi

if [ "$3" != "" ]
then
	usrmsg=" for user ""$3"""
else
	usrmsg=""
fi


for ((c=0;c=1;c=c+0))
do
	echo -e "\e["$4"mEnter $2$usrmsg$defmsg:\e[0m" > /dev/tty
		if [ $1 -eq 0 ]
		then
			read out
		else
			read -s out; echo -e "\n" > /dev/tty
		fi

		if [ "$out" == "ABORT" ]
		then
			exit 1
		fi

	echo -e "\e["$4"mConfirm $2$usrmsg$defmsg:\e[0m" > /dev/tty
		if [ $1 -eq 0 ]
		then
			read out2
		else
			read -s out2; echo -e "\n" > /dev/tty
		fi

		if [ "$out2" == "ABORT" ] 
		then 
			exit 1
		fi
	
	if [ "$out" == "$out2" ] && [ "$out" == "" ] && [ "$5" != "" ] && ! [ $1 = 1 ]
	then
		echo -e "Default option """$5""" confirmed." > /dev/tty
		out=$5
		break

	elif [ "$out" == "$out2" ] && [ "$out" != "" ]
	then
		echo -e "Confirmed." > /dev/tty
		break
	else
		echo -e "Error: entries do not match$blankmsg." > /dev/tty
		echo -e ""
	fi
done

echo $out
echo "" > /dev/tty
}

#determines OS distro and version and sets stuff up accordingly
getOSInfo(){

	#set variables to 0

	OSdist=""
	OSname=""

	use_dotdeb=0
	use_debmm=0
	installString=""


	#check if lsb_release works; if not, install it using a brute-force method
	#(it's a catch-22 here; we need lsb_release to determine the os 
	#but we can't isntall lsb_release without knowing the os)
		
	if [ command -v lsb_release >/dev/null 2>&1 ]
	then
		apt-get -y install lsb_release
	fi
	
	#use lsb_release to get os info and then set variables accordingly	

	OSdist=$(lsb_release -si)
	OSname=$(lsb_release -sc)

	case $OSdist in
		Debian)
			installString="apt-get"
			case $OSname in
				jessie)
					use_dotdeb=1
					;;
				stretch)
					use_debmm=1
					;;
				*)
					unknownOS
					;;
			esac
			;;
		Ubuntu)
			installString="apt-get"
			;;
		LinuxMint)
			installString="apt-get"
			case $OSname in
				betsy)
					use_dotdeb=1
					;;
				*)
					unknownOS
					;;
			esac
			;;
		Raspbian)
			installString="apt"
			case $OSname in
				jessie)
					unsupportedOS stretch
					;;
				stretch)
					use_debmm=1
					;;
				*)
					unknownOS
					;;
				esac
				;;		
		*)
			unknownOS
			;;
	esac

}

# Print message regarding unknown OS and abort.
unknownOS(){
	echo -e "\e[1;31;43mCollectiveAccess Installation Aborted due to unknown OS:\n\"$OSdist $OSname\"\nFork this on github and add the nescessary options for your OS.\e[0m"
	exit
}

# Print message regarding unsupported OS and abort.
# $1 specifies acceptable OS version
unsupportedOS(){
	echo -e "\e[1;31;43mCollectiveAccess Installation Aborted due to unsupported OS:\n\"$OSdist $OSname\"\nPlease upgrade your OS ($OSdist) to version \"$1\" or higher.\e[0m"
	exit
}

# Check if $1 is a working symlink and create where $1 is pointing at if it is not
checkFixSymLink() {
	if [[ -L "$1" ]] && [[ ! -a "$1" ]];
	then 
	  	sym_path=$(readlink -f $1)
		mkdir $sym_path
		echo -e "Symlink $1 fixed by creating $sym_path" > /dev/tty
	elif [[ -L "$1" ]] && [[ -a "$1" ]];
	then
		echo -e "Symlink $1 OK." > /dev/tty
	elif [[ ! -L "$1" ]]
	then
		echo -e "$1 is not a symlink." >/dev/tty
	fi
}

randAlphaNumeric() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-$1};echo;}

#####################################################################################################################################
#FIGURING OUT OPTIONS

optf=0
while getopts ":f" opt; do
	case $opt in
		f ) 
			optf=1 
				echo "Option -f"
		;;
		\?)	
			echo "Invalid Option: -$OPTARG"; 
			exit 1;
		;;
	esac
done



#####################################################################################################################################

# [Step 0] Introductory stuff

echo -e "\e[1;4;45mCollectiveAccess BASH SETUP SCRIPT v0.7.4\e[0m"

echo -e "Welcome to the bash setup script for Collective Access. \nThis script will install and configure all the files and software dependancies need to run a Linux-based webserver for the current versions of CollectiveAccess Providence 1 and Pawtucket 2. \nThis process may take several hours."

echo -e "\e[37;41mPLEASE NOTE THAT THIS SCRIPT IS PROVIDED COMPLETELY AS-IS, WITH ABSOLUTELY NO GUARANTEES EXPRESSED OR IMPLIED.\n\n FOR MORE INFORMATION ON WHAT EXACTLY THIS SCRIPT WILL DO, SEE THE README.md FILE IN THE GITHUB REPOSITORY.\e[0m\n"

echo -e "\e[1;91m Having read the above description, do you wish to proceed with the installation?\e[0m \nType option number, [Enter] to confirm: "

select yna in "Yes" "No" "Abort"; do
	case $yna in
	Yes ) echo "Proceeding."; break;;
	No ) echo -e "\e[1;31;43mCollectiveAccess Installation Aborted\e[0m"; exit; break;;
	Abort ) echo -e "\e[1;31;43mCollectiveAccess Installation Aborted\e[0m"; exit; break;;
	esac
done

echo -e "\n Please verify that the following information is correct:\n"
#get os information
getOSInfo
echo -e "\e[1;44mThis operating system is: $OSdist $OSname \e[0m\n"

#get username for current user (i.e. directory name)
calinuxun=$SUDO_USER
echo -e "\e[1;44mThis user (logged into the computer) is: $calinuxun \e[0m\n"

#get computer ip address
echo -e "\e[1;44mThe IP Address for this computer is: "$(myip)" \e[0m\n"

#get system Olson timezone
catimezone=$(subStrBetween "$(timedatectl)" "zone:" " (")
echo -e "\e[1;44mThe current time zone (Olson) of this computer is: $catimezone \e[0m\n"

#get system locale
calocale=$(subStrBetween "$(locale)" "LANG=" ".")
echo -e "\e[1;44mThe current locale of this computer is: $calocale \e[0m\n"

echo -e "\e[1;91m Is the above information correct?\e[0m \nType option number, [Enter] to confirm: "

select yna in "Yes" "No" "Abort"; do
	case $yna in
	Yes ) echo "Proceeding."; break;;
	No ) echo -e "\e[1;31;43mCollectiveAccess Installation Aborted\e[0m"; exit; break;;
	Abort ) echo -e "\e[1;31;43mCollectiveAccess Installation Aborted\e[0m"; exit; break;;
	esac
done

echo -e "Enter the following information for your CollectiveAccess installation. This information will be used while configuring your CollectiveAccess installation, and will be required for any maintenance, so keep this information safe. The usual rule about secure passwords apply here too."

#get password for root user for MySQL database
dbrootpw=$(getInput 1 "MySQL password" "root user" "0;30;43" "")

#get app_name for CollectiveAccess (used for MySQL db name and user also)
caident=$(getInput 0 "CollectiveAccess app_name (config purposes only, alphanumeric only)" "" "0;30;43" "collectiveaccess")

#get password for ca user for MySQL database
dbcapw=$(getInput 1 "MySQL password" "$caident" "0;30;43" "")

#get display name for CollectiveAccess
caappdisp=$(getInput 0 "CollectiveAccess display name (shows on browser tab)" "" "0;30;43" "My First CollectiveAccess Installation")

echo -e "\e[1;91m LAST CHANCE: Once this installation starts, it cannot be stopped without causing serious problems with the system packages (to the point where the entire OS may have to be re-installed from scratch). This process will take several hours, so you might want to get a book. Are you absolutely positively sure you want to continue?\e[0m \nType option number, [Enter] to confirm: "

select yna in "Yes" "No" "Abort"; do
	case $yna in
	Yes ) echo "Proceeding."; break;;
	No ) echo -e "\e[1;31;43mCollectiveAccess Installation Aborted\e[0m"; exit; break;;
	Abort ) echo -e "\e[1;31;43mCollectiveAccess Installation Aborted\e[0m"; exit; break;;
	esac
done

#####################################################################################################################################

# [Step 1] add additional apt package servers
echo -e "\e[1;4;45mStep 1: Add additional package servers to apt sources.list\e[0m"
echo -e "Step started at "$(timestamp)"."
echo -e "Copying current sources.list to "$(timestamp)"-sources.list.old..."
cp "/etc/apt/sources.list" "/etc/apt/"$(timestamp)"-sources.list.old"
echo -e "Checking sources.list and adding additional package servers if required..."

#add dem-multimedia package locations if required and not there already
if (( $use_debmm == "1" ))
then
	if ! grep -Fq "deb-multimedia.org" /etc/apt/sources.list
	then
		echo -e '' >> /etc/apt/sources.list
		echo -e "#Multimedia apt package locations (added by Collective Access Installer)" >> /etc/apt/sources.list
		echo -e "deb http://www.deb-multimedia.org $OSname main non-free" >> /etc/apt/sources.list
		echo -e "deb-src http://www.deb-multimedia.org $OSname main non-free" >> /etc/apt/sources.list
	fi
fi

#add dotdeb package locations if required and not there already
if (( $use_dotdeb == "1" ))
then
	if ! grep -Fq "dotdeb.org" /etc/apt/sources.list
	then
		echo -e '' >> /etc/apt/sources.list
		echo -e "#php7 apt package locations (added by Collective Access Installer)" >> /etc/apt/sources.list
		echo -e "deb http://packages.dotdeb.org $OSname all" >> /etc/apt/sources.list
		echo -e "deb-src http://packages.dotdeb.org $OSname all" >> /etc/apt/sources.list
	fi
fi

echo -e "Done."

echo -e "\e[1;42mFinished Step 1.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 2] update package list from new sources
echo -e "\e[1;4;45mStep 2: Update package lists from new sources\e[0m"
echo -e "Step started at "$(timestamp)"."

$installString update

#add deb-multimedia keyring if required
if (( $use_debmm  == "1" ))
then
	wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
	dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
	rm deb-multimedia-keyring_2016.8.1_all.deb
fi

#Add dotdeb key if required
if (( $use_dotdeb == "1" ))
then 
	cd /tmp
	wget https://www.dotdeb.org/dotdeb.gpg
	apt-key add dotdeb.gpg
	rm dotdeb.gpg
	cd
fi

$installString update
echo -e "\e[1;42mFinished Step 2.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 3] update already-installed packages and OS components
echo -e "\e[1;4;45mStep 3: Update operating system and pre-installed packages\e[0m"
echo -e "Step started at "$(timestamp)"."
$installString -y update
printf 'q' | $installString -y dist-upgrade
$installString -y autoremove
$installString -y upgrade
$installString -y update
echo -e "\e[1;42mFinished Step 3.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 4] install apache2 webserver
echo -e "\e[1;4;45mStep 4: Install Apache\e[0m"
echo -e "Step started at "$(timestamp)"."
$installString -y install apache2
echo -e ''

echo -e "\e[1;42mFinished Step 4.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 5] Install php7
echo -e "\e[1;4;45mStep 5: Install php7\e[0m"
echo -e "Step started at "$(timestamp)"."

$installString -y install  php7.0 php7.0-gd libapache2-mod-php7.0 php7.0-mcrypt php7.0-curl php7.0-dev

echo -e "Copying current php.ini to "$(timestamp)"-php.ini.old..."
cp "/etc/php/7.0/apache2/php.ini" "/etc/php/7.0/apache2/"$(timestamp)"-sources.list.old"
echo -e "Updating php.ini to allow CollectiveAccess to operate better..."
perl -pi -e "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.0/apache2/php.ini
perl -pi -e "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.0/apache2/php.ini
perl -pi -e "s/memory_limit = 128M/memory_limit = 256M/" /etc/php/7.0/apache2/php.ini
perl -pi -e "s/display_errors = Off/display_errors = On/" /etc/php/7.0/apache2/php.ini

echo -e "Updating Apache dir.conf to serve index.php first..."
perl -pi -e "s/index.pl index.php/index.pl/" /etc/apache2/mods-enabled/dir.conf
perl -pi -e "s/index.html/index.php index.html/" /etc/apache2/mods-enabled/dir.conf

echo -e "Restarting Apache..."
service apache2 restart

echo -e "\e[1;42mFinished Step 5.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 6] Install git, graphicsMagick, GMagick, GhostScript, DCraw, LibreOffice, Poppler-Utils (PdfToText), MediaInfo, WkHtmlToText, OpenCTM, PdfMiner, ExifTool, 
echo -e "\e[1;4;45mStep 6: Install CollectiveAccess image-handling packages\e[0m"
echo -e "Step started at "$(timestamp)"."

echo -e "\e[1;91mNote that the ""Unknown media type in type ""chemical/x..."" warnings are normal and non-fatal. This is caused by a problem with the registration of the MIME ""chemical"" type with IANA.\e[0m"

$installString -y install git php-pear liblzma5 liblzma-dev libtiff-dev graphicsmagick libgraphicsmagick1-dev ghostscript dcraw libreoffice poppler-utils mediainfo wkhtmltopdf openctm-tools meshlab meshlab python-pip

pecl channel-update pecl.php.net
printf '\n' | pecl install gmagick-2.0.4RC1
#Add extension iformation for php gmagick module
echo -e "; configuration for php gmagick module\n; Added by CollectiveAccess Installer\n; priority=20\nextension=gmagick.so" > /etc/php/7.0/apache2/conf.d/20-gmagick.ini

pip install pdfminer

echo -e "Installing ExifTool..."

checkFixSymLink /usr/local/man
mkdir /usr/local/exiftool_sources
cd /usr/local/exiftool_sources
wget http://www.sno.phy.queensu.ca/~phil/exiftool/Image-ExifTool-10.82.tar.gz
gzip -dc Image-ExifTool-10.82.tar.gz | tar -xf -
cd Image-ExifTool-10.82
perl Makefile.PL
make test
make install
cd
echo -e "ExifTool Installed."

echo -e "\e[1;42mFinished Step 6.\e[0m"
echo -e ''

#####################################################################################################################################

if [ $optf -eq 1 ]
then

	# [Step 7] Install ffmpeg
	echo -e "\e[1;4;45mStep 7: Install CollectiveAccess audio- and video-handling packages\e[0m"
	echo -e "Step started at "$(timestamp)"."


	$installString -y remove ffmpeg
	$installString -y install ffmpeg

	echo -e "\e[1;42mFinished Step 7.\e[0m"

else
	echo -e "\e[1;4;41mSKIPPING STEP:\e[49m\n\e[45mStep 7: Install CollectiveAccess audio- and video-handling packages\e[0m"
fi
echo -e ''

#####################################################################################################################################

# [Step 8] Install MySQL server
echo -e "\e[1;4;45mStep 8: Install MySQL Server and secure the installation\e[0m"
echo -e "Step started at "$(timestamp)"."

tmppw=$(randAlphaNumeric 32)
dbtemprootpw="$tmppw"
echo -e "Temporary mysql root password: $dbtemprootpw"
echo -e "Actual password will be set in Step 9"

debconf-set-selections <<< "mysql-server mysql-server/root_password password $dbtemprootpw"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $dbtemprootpw"
$installString -y install mysql-server 

mysql_install_db --defaults-file=~/.my.cnf

#equivalent to running mysql_secure_installation
mysql -uroot -p${dbtemprootpw} -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -p${dbtemprootpw} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -uroot -p${dbtemprootpw} -e "DROP DATABASE IF EXISTS test;"
mysql -uroot -p${dbtemprootpw} -e "DELETE FROM mysql.db WHERE Db='test' OR db='test\\%';"
mysql -uroot -p${dbtemprootpw} -e "FLUSH PRIVILEGES;"

$installString -y install  php7.0-mysql

echo -e "Restarting Apache..."
service apache2 restart

echo -e "\e[1;42mFinished Step 8.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 9] Create database and user for CollectiveAccess
echo -e "\e[1;4;45mStep 9: Create database for CollectiveAccess\e[0m"
echo -e "Step started at "$(timestamp)"."

echo -e "Creating CollectiveAccess database..."
mysql -uroot -p${dbtemprootpw} -e "CREATE DATABASE ${caident} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${dbtemprootpw} -e "CREATE USER ${caident}@'localhost' IDENTIFIED BY '${dbcapw}';"
mysql -uroot -p${dbtemprootpw} -e "GRANT ALL PRIVILEGES ON ${caident}.* TO '${caident}'@'localhost';"
mysql -uroot -p${dbtemprootpw} -e "FLUSH PRIVILEGES;"
mysql -uroot -p${dbtemprootpw} -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${dbrootpw}');"
echo -e "Done creating database."

echo -e "\e[1;42mFinished Step 9.\e[0m"
echo -e ''

#####################################################################################################################################


# [Step 10] actually install and configure CollectiveAccess - Providence
echo -e "\e[1;4;45mStep 10: Install and configure CollectiveAccess - Providence\e[0m"
echo -e "Step started at "$(timestamp)"."

echo -e "Deleting test webpages (if any)..."
if ! grep -q "CollectiveAccess" /var/www/html/index.php
then
	rm /var/www/html/index.php
fi

rm /var/www/html/


echo -e "Downloading CollectiveAccess - Providence files from github..."
git clone https://github.com/collectiveaccess/providence.git /var/www/html/staff
echo -e "Done."

echo -e "Updating setup.php..."
sudo cp /var/www/html/staff/setup.php-dist /var/www/html/staff/setup.php
perl -pi -e "s/my_database_user/$caident/" /var/www/html/staff/setup.php
perl -pi -e "s/my_database_password/$dbcapw/" /var/www/html/staff/setup.php
perl -pi -e "s/name_of_my_database/$caident/" /var/www/html/staff/setup.php
perl -pi -e "s/My First CollectiveAccess System/$caappdisp/" /var/www/html/staff/setup.php
perl -pi -e "s/""__CA_APP_NAME__"", ""collectiveaccess""/""__CA_APP_NAME__"", ""$caident""/" /var/www/html/staff/setup.php
perl -pi -e "s{'America/New_York'}{'$catimezone'}" /var/www/html/staff/setup.php
perl -pi -e "s/en_US/$calocale/" /var/www/html/staff/setup.php
echo -e "Done." 

echo -e "Updating external_applications.conf..."
perl -pi -e "s{/usr/bin/pdf2txt.py}{/usr/local/bin/pdf2txt.py}" /var/www/html/staff/app/conf/external_applications.conf
perl -pi -e "s{/usr/bin/exiftool}{/usr/local/bin/exiftool}" /var/www/html/staff/app/conf/external_applications.conf
perl -pi -e "s{/usr/local/bin/wkhtmltopdf}{/usr/bin/wkhtmltopdf}" /var/www/html/staff/app/conf/external_applications.conf
echo -e "Done."

echo -e "\e[1;42mFinished Step 10.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 11] actually install and configure CollectiveAccess - Pawtucket2
echo -e "\e[1;4;45mStep 11: Install and configure CollectiveAccess - Pawtucket2\e[0m"
echo -e "Step started at "$(timestamp)"."

echo -e "Downloading CollectiveAccess - Pawtucket2 files from github..."
git clone https://github.com/collectiveaccess/pawtucket2.git /var/www/html/p_temp
mv /var/www/html/p_temp/* /var/www/html
echo -e "Done."

echo -e "Updating setup.php..."
sudo cp /var/www/html/setup.php-dist /var/www/html/setup.php
perl -pi -e "s/my_database_user/$caident/" /var/www/html/setup.php
perl -pi -e "s/my_database_password/$dbcapw/" /var/www/html/setup.php
perl -pi -e "s/name_of_my_database/$caident/" /var/www/html/setup.php
perl -pi -e "s/My First CollectiveAccess System/$caappdisp/" /var/www/html/setup.php
perl -pi -e "s/""__CA_APP_NAME__"", ""collectiveaccess""/""__CA_APP_NAME__"", ""$caident""/" /var/www/html/setup.php
perl -pi -e "s{'America/New_York'}{'$catimezone'}" /var/www/html/setup.php
perl -pi -e "s/en_US/$calocale/" /var/www/html/setup.php
echo -e "Done."

echo -e "Updating external_applications.conf..."
perl -pi -e "s{/usr/bin/pdf2txt.py}{/usr/local/bin/pdf2txt.py}" /var/www/html/app/conf/external_applications.conf
perl -pi -e "s{/usr/bin/exiftool}{/usr/local/bin/exiftool}" /var/www/html/app/conf/external_applications.conf
perl -pi -e "s{/usr/local/bin/wkhtmltopdf}{/usr/bin/wkhtmltopdf}" /var/www/html/app/conf/external_applications.conf
echo -e "Done."

echo -e "\e[1;42mFinished Step 11.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 12] fix filesystem issues
echo -e "\e[1;4;45mStep 12: Fix filesystem issues in var/www/html\e[0m"
echo -e "Step started at "$(timestamp)"."

echo -e "Fixing filesystem structure and permissions..."
ln -s /var/www/html/staff/media /var/www/html/media

mkdir /var/www/html/staff/media

chmod a+w /var/www/html/staff/app/tmp
chmod a+w /var/www/html/staff/app/log
chmod a+w /var/www/html/staff
chmod a+w /var/www/html/staff/media
chmod a+w /var/www/html/staff/media/collectiveaccess
chmod a+w /var/www/html/staff/vendor/ezyang/htmlpurifier/library/HTMLPurifier/DefinitionCache/Serializer

chmod a+w /var/www/html/app/tmp 
chmod a+w /var/www/html/media
chmod a+w /var/www/html/media/collectiveaccess
chmod a+w /var/www/html/vendor/ezyang/htmlpurifier/library/HTMLPurifier/DefinitionCache/Serializer

echo -e "Done."

echo -e "\e[1;42mFinished Step 12.\e[0m"
echo -e ''

#####################################################################################################################################

# [Step 13] clean up
echo -e "\e[1;4;45mStep 13: Clean up installation files\e[0m"
echo -e "Step started at "$(timestamp)"."

echo -e "Cleaning up installation files and packages that are no longer required..."

$installString -y autoremove
$installString -y clean

echo -e "Done."

echo -e "\e[1;42mFinished Step 13.\e[0m"
echo -e ''
#ENDSCRIPT
#####################################################################################################################################
endts=$(timestamp)

elapsedts=$((endts-startts))
echo -e "Install took $elapsedts seconds (from $startts to $endts).\n"

echo -e "All done! All that remains is for you to run the web installer by going to:"
echo -e "http://"$(myip)"/staff/install"

