#!/bin/bash


clear -x
echo "Updater script successfully started!"

description="Do you want to remove unused programs (if any) and attempt to fix broken programs?\
\nALERT (November 17th, 2021): please choose 'yes' here to reset Python to fix AntiMicroX not installing.\n(Keyboard required to confirm when it checks later, but any menus like this have mouse/touch support. If you don't have a keyboard set up, just choose no.)"
table=("no" "yes")
userinput_func "$description" "${table[@]}"
AptFixUserInput="$output"



############UPDATER SCANNERS - SEE BELOW FOR MANUAL UPDATERS###########
##add more of these later!

#tests if the Dolphin Emulator program exists, then asks to re-run the installer script if it's found, binding the user's response to DolphinUserInput
#reset the variable first to be safe...
DolphinUserInput="no"
if test -f /usr/local/bin/dolphin-emu; then
        description="Do you want to update Dolphin? (May take 5 to 40 minutes)"
        table=("yes" "no")
        userinput_func "$description" "${table[@]}"
	DolphinUserInput="$output"
fi

#Same as above, but for RetroPie, using the emulationstation binary as the test
RetroPieUserInput="No"
if test -f /usr/bin/emulationstation; then
        description="Do you want to update parts of RetroPie?\
		\nBinaries should always be updated but may take a minute or two depending on the speed of your internet\
		\nUpdate RetroPie Setup Script and Megascript RetroPie Scripts\
		\nUpdate Everything from Source, could TAKE MULTIPLE HOURS, Not Recommended, builds all installed cores from source"
        table=("Binaries Only" "Update Scripts Only" "Update From Source" "No")
        userinput_func "$description" "${table[@]}"
        RetroPieUserInput="$output"
fi

#and so on and so forth.
CitraUserInput="no"
if test -f /usr/local/bin/citra-qt; then
        description="Do you want to update Citra? (May take 5 to 40 minutes)"
        table=("yes" "no")
        userinput_func "$description" "${table[@]}"
	CitraUserInput="$output"
fi

MelonDSUserInput="no"
if test -f /usr/local/bin/melonDS; then
        description="Do you want to update melonDS? (May take 5 to 20 minutes)"
        table=("yes" "no")
        userinput_func "$description" "${table[@]}"
	MelonDSUserInput="$output"
fi

MetaforceUserInput="no"
if test -f /usr/local/bin/metaforce; then
        description="Do you want to update Metaforce? (May take 5 minutes to 3+ hours)"
        table=("yes" "no")
        userinput_func "$description" "${table[@]}"
	MetaforceUserInput="$output"
fi

XemuUserInput="no"
if test -f /usr/local/bin/xemu; then
        description="Do you want to update Xemu? (May take 5 minutes to 2 hours)"
        table=("yes" "no")
        userinput_func "$description" "${table[@]}"
	XemuUserInput="$output"
fi

#######################################################################

echo "Running APT updates..."
sleep 1
sudo apt upgrade -y

if [ -f /etc/switchroot_version.conf ]; then
  swr_ver=$(cat /etc/switchroot_version.conf)
  if [ $swr_ver == "3.4.0" ]; then
    # check for bad wifi/bluetooth firmware, overwritten by linux-firmware upgrade
    if [[ $(sha1sum /lib/firmware/brcm/brcmfmac4356-pcie.bin | awk '{print $1}') != "6e882df29189dbf1815e832066b4d6a18d65fce8" ]]; then
      warning "Wifi was probably broken after an apt upgrade to linux-firmware"
      warning "Replacing with known good version from L4T 3.4.0 updates files"
      sudo wget -O /lib/firmware/brcm/brcmfmac4356-pcie.bin https://raw.githubusercontent.com/cobalt2727/L4T-Megascript/master/assets/switch-firmware-3.4.0/brcm/brcmfmac4356-pcie.bin
      sudo wget -O /lib/firmware/brcm/BCM4356A3.hcd https://raw.githubusercontent.com/cobalt2727/L4T-Megascript/master/assets/switch-firmware-3.4.0/brcm/BCM4356A3.hcd
    fi
  fi
fi

#this is an apt package in the Switchroot repo, for documentation join their Discord https://discord.gg/9d66FYg and check https://discord.com/channels/521977609182117891/567232809475768320/858399411955433493
sudo apt install switch-multimedia -y
sudo apt install python-minimal -y
if [[ $(echo $XDG_CURRENT_DESKTOP) = 'Unity:Unity7:ubuntu' ]]; then
        sudo apt install unity-tweak-tool hud -y
else
        echo "Not using Unity as the current desktop, skipping theme manager install..."
fi

if grep -q bionic /etc/os-release; then

    if $(dpkg --compare-versions $(dpkg-query -f='${Version}' --show libc6) lt 2.28);then
        echo "Continuing the installs"
    else
        echo "Force downgrading libc and related packages"
		echo "libc 2.28 was previously required for the minecraft bedrock install"
		echo "this is no longer the case so the hack is removed"
		echo ""
        echo "You may need to recompile other programs such as Dolphin and BOX64 if you see this message"
		sudo rm -rf /etc/apt/sources.list.d/zorinos-ubuntu-stable-bionic.list*
		sudo rm -rf /etc/apt/preferences.d/zorinos*
		sudo rm -rf /etc/apt/sources.list.d/debian-stable.list*
		sudo rm -rf /etc/apt/preferences.d/freetype*

		sudo apt update
		sudo apt install libc-bin=2.27* libc-dev-bin=2.27* libc6=2.27* libc6-dbg=2.27* libc6-dev=2.27* libfreetype6=2.8* libfreetype6-dev=2.8* locales=2.27* -y --allow-downgrades
    fi

fi

#fix error at https://forum.xfce.org/viewtopic.php?id=12752
sudo chown $USER:$USER $HOME/.local/share/flatpak

##this is outside all the other y/n prompt runs at the bottom since you obviously need functioning repositories to do anything else
if [[ $AptFixUserInput == "yes" ]]; then
	echo
	echo
	echo
	echo "Scanning for issues with APT packages..."
	echo
	echo "If you receive a yes/no prompt in the following steps,"
	echo "Make sure you carefully read over the"
	echo "packages to be changed before proceeding."
	echo "If not, don't worry about it."
	echo "Purging, cleaning, and autoremoving are NORMALLY"
	echo "fine, but double-check packages to be safe."
	sleep 5
	##maintenance (not passing with -y to prevent potentially breaking something for a user)
	sudo dpkg --configure -a
	sudo apt --fix-broken install
	sudo apt autoremove
	sudo apt autoclean
	sudo apt autopurge
	sudo apt clean && sudo apt-get purge $(dpkg -l | grep '^rc' | awk '{print $2}')
	
	echo "Fixing flatpak issues (if any)..."
	sudo flatpak remove --unused
	flatpak remove --unused
	sudo flatpak repair
	flatpak repair --user
	
	if grep -q bionic /etc/os-release; then
		if [ -f /etc/alternatives/python ]; then
			echo "Fixing possibly broken Python setup (this was my fault)..."
			sudo rm /etc/alternatives/python && sudo apt install --reinstall python-minimal -y
		else
			echo "No issues detected with Python, skipping fix for that..."
		fi
	fi


else
	echo "Skipping apt fixes..."
fi


echo "Updating Flatpak packages (if you have any)..."
##two separate flatpak updaters to catch all programs regardless of whether the user installed them for the system or just the user
sudo flatpak update -y
flatpak update -y

#echo "Updating NPM (if you have it)..."
##commenting this out until i figure out a better way to replace it with an updater for all NodeJS packages
#sudo npm install -g npm

echo "Marking all AppImages under ~/Applications as executable..."
chmod +x ~/Applications/*.AppImage

#################MANUAL UPDATERS - SEE ABOVE FOR SCANNERS#################

if [[ $DolphinUserInput == "yes" ]]; then
	echo "Updating Dolphin..."
	echo -e "\e[33mTO FIX, RESET, AND/OR UPDATE CONFIGS (not game saves) YOU HAVE\e[0m"
	echo -e "\e[33mTO RE-RUN THE DOLPHIN SCRIPT FROM THE MENU\e[0m"
	sleep 5
	bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/dolphin/install.sh)" || exit $?
else
	echo "Skipping Dolphin update..."
fi

if [[ $RetroPieUserInput == "Update From Source" ]]; then
	echo "Updating RetroPie Cores from Source..."
	echo -e "\e[33mThis can take a VERY long time - possibly multiple hours.\e[0m"
	echo -e "\e[33mCharge your device & remember you can close this terminal or press\e[0m"
	echo -e "\e[33mCtrl+C at any time to stop the process.\e[0m"
	sleep 10
	curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/retropie_auto.sh | bash -s "update_cores"
elif [[ $RetroPieUserInput == "Update Scripts Only" ]]; then
	echo "Updating RetroPie-Setup script and Megascript scripts Only..."
	curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/retropie_auto.sh | bash -s "update_scripts"
elif [[ $RetroPieUserInput == "Binaries Only" ]]; then
	echo "Updating RetroPie binaries only..."
	curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/retropie_auto.sh | bash -s "install_binaries"
else
	echo "Skipping RetroPie updates..."
fi

if [[ $CitraUserInput == "yes" ]]; then
	echo "Updating Citra..."
	sleep 5
	bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/citra.sh)" || exit $?
else
	echo "Skipping Citra update..."
fi

if [[ $MelonDSUserInput == "yes" ]]; then
	echo "Updating melonDS..."
	sleep 5
	bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/melonDS.sh)" || exit $?
else
	echo "Skipping melonDS update..."
fi

if [[ $MetaforceUserInput == "yes" ]]; then
	echo "Updating Metaforce..."
	sleep 5
	bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/metaforce.sh)" || exit $?
else
	echo "Skipping Metaforce update..."
fi

if [[ $XemuUserInput == "yes" ]]; then
	echo "Updating Xemu..."
	sleep 5
	bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/games_and_emulators/xemu.sh)" || exit $?
else
	echo "Skipping Xemu update..."
fi

##########################################################################

cd ~
if test -f customupdate.sh; then
	echo "Looks like you've made a custom update file - running that..."
	chmod +x customupdate.sh
	./customupdate.sh
else
	echo -e "You can add your own commands to automatically run with this updater"
	echo -e "by creating a file in \e[34m/home/$USER/\e[0m (this is your default ~ folder) named \e[36mcustomupdate.sh\e[0m"
	sleep 4
fi

sleep 1

echo
echo "Done! Sending you back to the main menu..."
sleep 4
