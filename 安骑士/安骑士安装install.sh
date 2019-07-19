#!/bin/bash
INST_UPDATE_VER=update_10_59
if [ `uname -m` = "x86_64" ]; then
    ARCH="linux64"
else
    ARCH="linux32"
fi

UPDATE_RPOC="AliYunDunUpdate"
CLIENT_PROC="AliYunDun"

#check linux Gentoo os 
var=`lsb_release -a 2>/dev/null | grep Gentoo`
if [ -z "${var}" ]; then 
    var=`cat /etc/issue | grep Gentoo`
fi

if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
    LINUX_RELEASE="GENTOO"
else
    LINUX_RELEASE="OTHER"
fi

AEGIS_INSTALL_DIR="/usr/local/aegis"

AEGIS_UPDATE_SITE="http://update2.aegis.aliyun.com/download"
AEGIS_UPDATE_SITE2="http://update.aegis.aliyun.com/download"
AEGIS_UPDATE_SITE3="http://update4.aegis.aliyun.com/download"
AEGIS_UPDATE_SITE4="http://update5.aegis.aliyun.com/download"
AEGIS_UPDATE_SITE5="http://update3.aegis.aliyun.com/download"
DOWNLOAD_UPDATE_INDEX_VALUE=0

DEST_UPDATE_FILE=${AEGIS_INSTALL_DIR}/aegis_update/${UPDATE_RPOC}

download_file()
{
    echo "start download from script"

	checkValue=$3
	if [ 1 -gt ${checkValue} ]; then
		echo "download from 0"
		wget "${AEGIS_UPDATE_SITE}""$1" -O "$2" -t 1 -T 180
		if [ $? == 0 ]; then
			return 0
		fi
	fi
	if [ 2 -gt ${checkValue} ]; then
		echo "download from 1"
		wget "${AEGIS_UPDATE_SITE2}""$1" -O "$2" -t 1 -T 180
		if [ $? == 0 ]; then
			return 1
		fi
	fi
	if [ 3 -gt ${checkValue} ]; then
		echo "download from 2"
		wget "${AEGIS_UPDATE_SITE3}""$1" -O "$2" -t 1 -T 180
		if [ $? == 0 ]; then
			return 2
		fi
	fi
    if [ 4 -gt ${checkValue} ]; then
		echo "download from 3"
		wget "${AEGIS_UPDATE_SITE4}""$1" -O "$2" -t 1 -T 180
		if [ $? == 0 ]; then
			return 2
		fi
	fi
    if [ 5 -gt ${checkValue} ]; then
		echo "download from 4"
		wget "${AEGIS_UPDATE_SITE5}""$1" -O "$2" -t 1 -T 180
		if [ $? == 0 ]; then
			return 2
		fi
	fi
    
	rm -rf "$2"
	echo "download file error" 1>&2
	exit 1
}

install_aegis()
{
    echo "begin to install"
	
    killall ${UPDATE_RPOC} 2>/dev/null
    killall ${CLIENT_PROC} 2>/dev/null
    killall aegis_cli 2>/dev/null
    killall aegis_update 2>/dev/null
    killall -9 AliHids 2>/dev/null
    
    if [ -d "${AEGIS_INSTALL_DIR}/aegis_client" ];then
        rm -rf "${AEGIS_INSTALL_DIR}/aegis_client"
    fi 
    if [ -d "${AEGIS_INSTALL_DIR}/aegis_update" ];then
        rm -rf "${AEGIS_INSTALL_DIR}/aegis_update"
    fi 
    mkdir -p "${AEGIS_INSTALL_DIR}/aegis_client"
    mkdir -p "${AEGIS_INSTALL_DIR}/aegis_update"

    echo "downloading aegis_update..."
    download_file "/$ARCH/updates/${INST_UPDATE_VER}/aegis_update" "${DEST_UPDATE_FILE}" ${DOWNLOAD_UPDATE_INDEX_VALUE}
	DOWNLOAD_UPDATE_INDEX_VALUE=$?
    download_file "/$ARCH/updates/${INST_UPDATE_VER}/aegis_update.md5" "${AEGIS_INSTALL_DIR}/aegis_update/aegis_update.md5" ${DOWNLOAD_UPDATE_INDEX_VALUE}
	DOWNLOAD_UPDATE_INDEX_VALUE=$?
	
    echo "checking aegis_update file..."
    md5_check=`md5sum "${DEST_UPDATE_FILE}" | awk '{print $1}' ` 
    md5_server=`head -1 "${AEGIS_INSTALL_DIR}/aegis_update/aegis_update.md5" | awk '{print $1}'`
    if [ "$md5_check"x = "$md5_server"x ]; then
		chmod +x "${DEST_UPDATE_FILE}"
    else
        echo "aegis_update checksum error."
		exit 1
    fi
}

uninstall_service() 
{
   echo "uninstalling service..."
   if [ -f "/etc/init.d/aegis" ]; then
      /etc/init.d/aegis stop  >/dev/null 2>&1
      rm -f /etc/init.d/aegis 
   fi

   if [ $LINUX_RELEASE = "GENTOO" ]; then
    rc-update del aegis default
        if [ -f "/etc/runlevels/default/aegis" ]; then
            rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
        fi
    elif [ -f /etc/init.d/aegis ]; then
         /etc/init.d/aegis  uninstall
        for ((var=2; var<=5; var++)) do
            if [ -d "/etc/rc${var}.d/" ];then
                 rm -f "/etc/rc${var}.d/S80aegis"
            elif [ -d "/etc/rc.d/rc${var}.d" ];then
                rm -f "/etc/rc.d/rc${var}.d/S80aegis"
            fi
        done
    fi
}

install_service()
{    
    echo "installing service..."

    if [ $LINUX_RELEASE = "GENTOO" ];then
		download_file "/linux_install/0061plus/aegis_gentoo" "/etc/init.d/aegis" ${DOWNLOAD_UPDATE_INDEX_VALUE}
		DOWNLOAD_UPDATE_INDEX_VALUE=$?
		download_file "/linux_install/0061plus/aegis_gentoo.md5" "${AEGIS_INSTALL_DIR}/aegis_update/aegis.md5" ${DOWNLOAD_UPDATE_INDEX_VALUE}
		DOWNLOAD_UPDATE_INDEX_VALUE=$?
    else
		download_file "/linux_install/0061plus/aegis" "/etc/init.d/aegis" ${DOWNLOAD_UPDATE_INDEX_VALUE}
		DOWNLOAD_UPDATE_INDEX_VALUE=$?
		download_file "/linux_install/0061plus/aegis.md5" "${AEGIS_INSTALL_DIR}/aegis_update/aegis.md5" ${DOWNLOAD_UPDATE_INDEX_VALUE}
		DOWNLOAD_UPDATE_INDEX_VALUE=$?
    fi

    echo "checking aegis service file..."
    md5_check=`md5sum "/etc/init.d/aegis" | awk '{print $1}' ` 
    md5_server=`head -1 "${AEGIS_INSTALL_DIR}/aegis_update/aegis.md5" | awk '{print $1}'`
    if [ "$md5_check"x = "$md5_server"x ]; then
		echo "aegis checksum success."
    else
        echo "aegis checksum error."
        exit 1
    fi
    

    chmod 700 /etc/init.d/aegis
    
    echo "remove old server"
    
    #delete old aegis sever
    if [ $LINUX_RELEASE = "GENTOO" ]; then
        rc-update del aegis default 2> /dev/null
        if [ -f "/etc/runlevels/default/aegis" ]; then
            rm -f "/etc/runlevels/default/aegis"
        fi
    else
        for ((var=2; var<=5; var++))
        do
            if [ -f "/etc/rc${var}.d/S80aegis" ]; then
                 rm -f "/etc/rc${var}.d/S80aegis"
            elif [ -f "/etc/rc.d/rc${var}.d/S80aegis" ];then
                 rm -f "/etc/rc.d/rc${var}.d/S80aegis"
            fi
        done
    fi

    echo "installing new server"
    
    # install new aegis server
    if [ $LINUX_RELEASE = "GENTOO" ]; then
        rc-update add aegis default 2>/dev/null
    else
        for ((var=2; var<=5; var++)) do
            if [ -d "/etc/rc${var}.d/" ];then
                #redhat 
                ln -s /etc/init.d/aegis /etc/rc${var}.d/S80aegis 2>/dev/null
            elif [ -d "/etc/rc.d/rc${var}.d" ]; then
                 #suse
                 ln -s /etc/init.d/aegis /etc/rc.d/rc${var}.d/S80aegis  2>/dev/null
            fi
        done
    fi

    path="/etc/debian_version"

    if [ -f "$path" -a -s "$path" ];
    then
        var=`awk -F. '{print $1}' $path`

        if [ -z $(echo $var|grep "[^0-9]") ]; then
            if [ $var -ge 6 ]; then
                echo "insserv aegis"
                insserv aegis  >/dev/null 2>&1
            fi
        fi
    fi
}

#remove_ud()
#{
#    if [ -f "${AEGIS_INSTALL_DIR}/globalcfg/ud" ];then
#        rm -f "${AEGIS_INSTALL_DIR}/globalcfg/ud" > /dev/null 2>&1
#    fi 
#    
#    if [ -f "${AEGIS_INSTALL_DIR}/globalcfg/ui_ud" ];then
#        rm -f "${AEGIS_INSTALL_DIR}/globalcfg/ui_ud" > /dev/null 2>&1
#    fi 
#}

check_aegis()
{
    var=1
    limit=18
    echo "Aegis client is installing , please wait for 1 to 3 minutes.";

    while [[ $var -lt $limit ]]; do 
        if [ -n "$(ps -ef|grep aegis_client|grep -v grep)" ]; then
             break
         else
            sleep 10
         fi
         
        ((var++))
    done     
}

if [ `id -u` -ne "0" ]; then
    echo "ERROR: This script must be run as root." 1>&2
    exit 1
fi


uninstall_service
install_aegis
install_service
#remove_ud

if [ -f /etc/init.d/aegis ];then
    /etc/init.d/aegis start
fi 

check_aegis
#service aegis start
echo "Aegis successfully installed"
exit 0
