#!/bin/bash
#######################################################################
####### Script for NIC driver Update - ravikasaragod@gmail.com   ######
#######################################################################

if [ ! -f /etc/centos-release ]; then
  echo "The script is only for Centos Servers"
  exit 1
fi

if [ `facter virtual` != 'physical' ]; then
  echo "The script is only for bare-metal server"
  exit 1
fi


igburl=https://downloadmirror.intel.com/13663/eng/igb-5.3.5.39.tar.gz
e1000eurl=https://downloadmirror.intel.com/15817/eng/e1000e-3.6.0.tar.gz
ixgbeurl=https://downloadmirror.intel.com/14687/eng/ixgbe-5.6.5.tar.gz
i40eurl=https://downloadmirror.intel.com/24411/eng/i40e-2.10.19.30.tar.gz

####################################################################
####### Installing gcc package and kernel development package ######
####################################################################

upgradeprep () {
	echo -e "\n"
	sleep 5; echo -e "\n"
    if [ ! -d /root/tmp ]; then
        mkdir /root/tmp
    fi
	echo "########## Preparing the server for the driver update ##########" | tee -a /root/tmp/nicdriverupdate.log
    yum -y install gcc make kernel kernel-devel 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    sleep 2; echo -e "\n"
	for dname in `ls -ld /sys/class/net/*/device/driver/module | awk -F / '{print $NF}' | sort -u`; do
		dversion=`modinfo $dname | grep -i '^version:' | awk '{print $NF}'`
		if [ "$dname" == 'igb' -a "$dversion" != '5.3.5.39' ]; then
			echo "########## Updating igb Driver ##########"
			echo -e "\n"
			igbupgrade
		elif [ "$dname" == 'e1000e' -a "$dversion" != '3.6.0-NAPI' ]; then
			echo "########## Updating e1000e Driver ##########"
			echo -e "\n"
			e1000eupgrade
		elif [ "$dname" == 'ixgbe' -a "$dversion" != '5.6.5' ]; then
			echo "########## Updating ixgbe Driver ##########"
			echo -e "\n"
			ixgbeupgrade
		elif [ "$dname" == 'i40e' -a "$dversion" != '2.10.19.30' ]; then
			echo "########## Updating i40e Driver ##########"
			echo -e "\n"
			i40eupgrade
		else
			echo "###########################################################"
			echo "########## Unknown Driver $dname - Please fix me ##########"
			echo "###########################################################"
		fi	
		echo "Checking for more drivers........." | tee -a /root/tmp/nicdriverupdate.log
		sleep 6
	done
	echo -e "\n"
	echo "######################################################################################################"
    echo "###### Driver Updates are Completed. Please check /root/tmp/nicdriverupdate.log for any issues #######"
	echo "######################################################################################################"
	echo -e "\n"
}

######################################
########### IGB upgrade ##############
######################################
igbupgrade () {
    cd /root/tmp
    if [ ! -d `basename $igburl | sed 's/\.tar\.gz//g'` ]; then
        wget $igburl 2>&1 | tee -a /root/tmp/nicdriverupdate.log
        tar -xzvf `basename $igburl` 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    fi
    if [ -d `basename $igburl | sed 's/\.tar\.gz//g'`/src ]; then
        cd `basename $igburl | sed 's/\.tar\.gz//g'`/src
    else
        echo "igbpackage doesn't exist"; exit 1
    fi
    sleep 1
    make install 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    sleep 2;
    echo -e "\n"
    if [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Install the appropriate kernel' ]]; then
        echo "Please reboot the server into the latest kernel and rerun the script"
        exit 1
    elif [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Running depmod' ]]; then
		sleep 2
        echo "igb" >> /etc/modules-load.d/updatedmodule.conf
		rmmod igb; modprobe igb; sleep 1; systemctl restart network 2>&1 | tee -a /root/tmp/nicdriverupdate.log
		sleep 2
		echo "##################################################################################################"
		echo "###### igb Driver update Completed. Confirm with command modinfo igb and  ethtool -i <ethX> ######" 
		echo "##################################################################################################"
    else
         echo "Something went wrong. Please troubleshoot the issue manually by checking /root/tmp/nicdriverupdate.log"
    fi
	echo -e "\n"
}

######################################
########### ixgbe upgrade ############
######################################
ixgbeupgrade () {
    cd /root/tmp
    if [ ! -d `basename $ixgbeurl | sed 's/\.tar\.gz//g'` ]; then
        wget $ixgbeurl 2>&1 | tee -a /root/tmp/nicdriverupdate.log
        tar -xzvf `basename $ixgbeurl` 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    fi
    if [ -d `basename $ixgbeurl | sed 's/\.tar\.gz//g'`/src ]; then
        cd `basename $ixgbeurl | sed 's/\.tar\.gz//g'`/src
    else
        echo "ixgbepackage doesn't exist"; exit 1
    fi
    sleep 1
    make install 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    sleep 2;
    echo -e "\n"
    if [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Install the appropriate kernel' ]]; then
        echo "Please reboot the server into the latest kernel and rerun the script"
        exit 1
    elif [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Running depmod' ]]; then
		sleep 2
        echo "ixgbe" >> /etc/modules-load.d/updatedmodule.conf
		rmmod ixgbe; modprobe ixgbe; sleep 1; systemctl restart network 2>&1 | tee -a /root/tmp/nicdriverupdate.log
		sleep 2
		echo "######################################################################################################"
		echo "###### ixgbe Driver update Completed. Confirm with command modinfo ixgbe and  ethtool -i <ethX> ######"
		echo "######################################################################################################"
    else
         echo "Something went wrong. Please troubleshoot the issue manually by checking /root/tmp/nicdriverupdate.log"
    fi
	echo -e "\n"
}


######################################
########### e1000e upgrade ###########
######################################
e1000eupgrade () {
    cd /root/tmp
    if [ ! -d `basename $e1000eurl | sed 's/\.tar\.gz//g'` ]; then
        wget $e1000eurl 2>&1 | tee -a /root/tmp/nicdriverupdate.log
        tar -xzvf `basename $e1000eurl` 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    fi
    if [ -d `basename $e1000eurl | sed 's/\.tar\.gz//g'`/src ]; then
        cd `basename $e1000eurl | sed 's/\.tar\.gz//g'`/src
    else
        echo "e1000epackage doesn't exist"; exit 1
    fi
    sleep 1
    make install 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    sleep 2;
    echo -e "\n"
    if [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Install the appropriate kernel' ]]; then
        echo "Please reboot the server into the latest kernel and rerun the script"
        exit 1
    elif [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Running depmod' ]]; then
		sleep 2
        echo "e1000e" >> /etc/modules-load.d/updatedmodule.conf
		rmmod e1000e; modprobe e1000e; sleep 1; systemctl restart network 2>&1 | tee -a /root/tmp/nicdriverupdate.log
		sleep 2
		echo "########################################################################################################"
		echo "###### e1000e Driver update Completed. Confirm with command modinfo e1000e and  ethtool -i <ethX> ######"
		echo "########################################################################################################"
    else
         echo "Something went wrong. Please troubleshoot the issue manually by checking /root/tmp/nicdriverupdate.log"
    fi
	echo -e "\n"
}

######################################
########### i40e upgrade #############
######################################

i40eupgrade () {
    cd /root/tmp
    if [ ! -d `basename $i40eurl | sed 's/\.tar\.gz//g'` ]; then
        wget $i40eurl 2>&1 | tee -a /root/tmp/nicdriverupdate.log
        tar -xzvf `basename $i40eurl` 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    fi
    if [ -d `basename $i40eurl | sed 's/\.tar\.gz//g'`/src ]; then
        cd `basename $i40eurl | sed 's/\.tar\.gz//g'`/src
    else
        echo "i40epackage doesn't exist"; exit 1
    fi
    sleep 1
    make install 2>&1 | tee -a /root/tmp/nicdriverupdate.log
    sleep 2;
    echo -e "\n"
    if [[ `tail -4 /root/tmp/nicdriverupdate.log` =~ 'Install the appropriate kernel' ]]; then
        echo "Please reboot the server into the latest kernel and rerun the script"
        exit 1
    elif [[ `tail -6 /root/tmp/nicdriverupdate.log` =~ 'Updating initramfs' ]]; then
		sleep 2
        echo "i40e" >> /etc/modules-load.d/updatedmodule.conf
		rmmod i40e; modprobe i40e; sleep 1; systemctl restart network 2>&1 | tee -a /root/tmp/nicdriverupdate.log
		sleep 2
		echo "########################################################################################################"
		echo "###### i40e Driver update Completed. Confirm with command modinfo i40e and  ethtool -i <ethX> ##########"
		echo "########################################################################################################"
    else
         echo "Something went wrong. Please troubleshoot the issue manually by checking /root/tmp/nicdriverupdate.log"
    fi
	echo -e "\n"
}


######################################
#### Fetch NIC driver Details ########
######################################
nics=`ls /sys/class/net/*/device/driver | grep 'device' |cut -d'/' -f5`
for nicnames in $nics; do
	driver=$(readlink /sys/class/net/$nicnames/device/driver/module)
    if [ $driver ]; then
        driver=$(basename $driver)
    fi
    vers=$(cat /sys/class/net/$nicnames/device/driver/module/version)
    operstate=$(cat /sys/class/net/$nicnames/operstate)
    if [ $driver == 'igb' -a $vers != '5.3.5.39' ]; then
        latest=`echo $igburl`
    elif [ $driver == 'e1000e' -a $vers != '3.6.0-NAPI' ]; then
        latest=`echo $e1000eurl`
	elif [ $driver == 'ixgbe' -a $vers != '5.6.5' ]; then
        latest=`echo $ixgbeurl`
	elif [ $driver == 'i40e' -a $vers != '2.10.19.30' ]; then
        latest=`echo $i40eurl`
    else
        latest=$(echo Updated)
    fi
    NICarray+=($(echo $nicnames $operstate $driver $vers $latest));
done
echo -e "\n"
arrlen=(${#NICarray[@]})
if [ $arrlen == 20 ]; then
    echo ${NICarray[@]:0:5}
    echo ${NICarray[@]:5:5}
    echo ${NICarray[@]:10:5}
    echo ${NICarray[@]:15:5}
elif [ $arrlen == 15 ]; then
    echo ${NICarray[@]:0:5}
    echo ${NICarray[@]:5:5}
    echo ${NICarray[@]:10:5}
elif [ $arrlen == 10 ]; then
    echo ${NICarray[@]:0:5}
    echo ${NICarray[@]:5:5}
elif [ $arrlen == 5 ]; then
    echo ${NICarray[@]:0:5}
else
    echo -e "\n"
    echo "########## Error 1 No Drivers found!! ##########"
	exit 1
fi |sed '1iNICNAME STATE DRIVER CURRENT-VERSION LATEST-VERSION\n'|column -t -s " "

if [[ " ${NICarray[@]} " =~ "downloadmirror.intel.com" ]]; then
	echo -e "\n"
    echo "########## NIC Driver Update Available!! ##########"
	sleep 5
	upgradeprep
else
	echo -e "\n"
    echo "########## No updates required ##########" && exit 1
fi
