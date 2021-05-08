#! /bin/bash
# Programming and idea by : Iman Homayouni
# Gitbub : https://github.com/iman-homayouni
# Email : homayouni.iman@Gmail.com
# Website : http://www.homayouni.info
# License : GPL v2.0
# Last update : 11-March-2021_19:53:05
# netdata.installer v1.0.1
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #
# SUCCESSFULLY TESTED IN UBUNTU 18.04 [BIONIC]
# SUCCESSFULLY TESTED IN UBUNTU 20.04 [FOCAL]
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #



# PRINT MSG TO TERMINAL # --------------------------------------------------------------------------------------------------------------------------------- #
clear
echo -e "[>>] ----------------------------------------------------------- [<<]"
echo -e "[>>] Programming and idea by : Iman Homayouni                    [<<]"
echo -e "[>>] Gitbub : https://github.com/iman-homayouni                  [<<]"
echo -e "[>>] Email : homayouni.iman@Gmail.com                            [<<]"
echo -e "[>>] ----------------------------------------------------------- [<<]"
echo -e "[>>] INSTALL NETDATA IN UBUNTU 18.04 & 20.04                     [<<]"
echo -e "[>>] ----------------------------------------------------------- [<<]"
echo -en "[>>] PRESS ENTER TO CONTINUE " ; read q
unset q
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #



# CHECK CONFIG FILE # ------------------------------------------------------------------------------------------------------------------------------------- #
if [ -f netdata.installer.conf ]
    source netdata.installer.conf
else
    echo -e "[>] cannot access 'netdata.installer.conf': No such file or directory"
    exit 1
fi
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #



# CHECK VARIABLES # --------------------------------------------------------------------------------------------------------------------------------------- #
if [ -z "$netdata_listen_port" ] ; then
    echo -e "[>] netdata_listen_port variable is empty"
    exit 1
fi

if [ -z "$netdata_panel_username" ] ; then
    echo -e "[>] netdata_panel_username variable is empty"
    exit 1
fi

if [ -z "$netdata_panel_password" ] ; then
    echo -e "[>] netdata_panel_password variable is empty"
    exit 1
fi
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #



# UPDATE AND UPGRADE SYSTEM # ----------------------------------------------------------------------------------------------------------------------------- #
apt-get update
apt-get -y dist-upgrade
apt -y autoremove
apt-get -y -f install
apt-get clean
apt-get install -y lsb-release &> /dev/null
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #



# CHECK lsb_release # ------------------------------------------------------------------------------------------------------------------------------------- #
which lsb_release &> /dev/null
[ "$?" != "0" ] && echo -e "\e[91m[>] WE CAN NOT FIND lsb_release COMMAND\e[0m" && exit !
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# CHECK OS CODENAME # ------------------------------------------------------------------------------------------------------------------------------------- #
lsb_release -cs | grep 'focal\|bionic' &> /dev/null
[ "$?" != "0" ] && echo -e "\e[91m[>] WE CAN NOT INSTALL NETDATA IN YOUR OS\e[0m"
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# INSTALL netdata PACKAGES # ------------------------------------------------------------------------------------------------------------------------------ #
apt-get -y install netdata
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# CHECK NGINX PACAKGE IN SYSTEM # ------------------------------------------------------------------------------------------------------------------------- #
dpkg -V nginx &> /dev/null
if [ "$?" = "0" ] ; then
    echo -e "\e[91m[>] FIND NGINX PACKAGE IN SYSTEM"
    echo -e "[>] WE NEED TO CHANGE SOME CONFIGURATION IN SYSTEM\e[0m"
    echo -en "[>] ARE YOU SURE ABOUT THAT ? [y/n] : " ; read q
    if [ "$q" != "y" ] ; then
        exit 1
    fi
fi
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# INSTALL NGINX PACKAGE # --------------------------------------------------------------------------------------------------------------------------------- #
apt-get -y install nginx apache2-utils
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# STOP NETDATA AND NGINX SERVICE # ------------------------------------------------------------------------------------------------------------------------ #
systemctl stop netdata
systemctl stop nginx
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# CREATE NETDATA CONFIGURATION FILE IN NGINX # ------------------------------------------------------------------------------------------------------------ #
unlink /etc/nginx/sites-enabled/default
touch /etc/nginx/sites-enabled/netdata_reverse_proxy
cat << EOF > /etc/nginx/sites-enabled/netdata_reverse_proxy

upstream backend {
    server 127.0.0.1:19999;
    keepalive 64;
}

server {
    listen $netdata_listen_port;
    server_name _;

    location / {
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_pass_request_headers on;
        proxy_set_header Connection "keep-alive";
        proxy_store off;

        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}

EOF
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# GET USERNAME FROM USER # -------------------------------------------------------------------------------------------------------------------------------- #
# for (( ;; )) ; do
#    echo -en "[>] ENTER USERNAME [FOR NETDATA] : " ; read username
#    if [ ! -z "$username" ] ; then
#        echo -en "[>] ARE YOU SURE ABOUT USER $username ? [y/n] : " ; read q
#        if [ "$q" = "y" ] ; then
#            break
#        fi
#    fi
#    clear
# done
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# CREATE USERNAME AND PASSWORD FOR NETDATA PANEL # -------------------------------------------------------------------------------------------------------- #
# echo -e "[>] SET PASSWORD FOR USER $username"
# htpasswd -c /etc/nginx/.htpasswd $netdata_panel_username
htpasswd -cdb /root/.htpasswd-all $netdata_panel_username $netdata_panel_password
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# ENABLE AND START NGINX AND NETDATA SERVICE # ------------------------------------------------------------------------------------------------------------ #
systemctl enable nginx netdata
systemctl start nginx netdata
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# CLEANUP TERMINAL # -------------------------------------------------------------------------------------------------------------------------------------- #
clear
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #


# SHOW SERVICE STATUS # ----------------------------------------------------------------------------------------------------------------------------------- #
systemctl status netdata
systemctl status nginx
# --------------------------------------------------------------------------------------------------------------------------------------------------------- #
