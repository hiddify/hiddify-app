#!/bin/bash

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
rest='\033[0m'

# Check Dependencies build
check_dependencies_build() {
    local dependencies=("curl" "wget" "git" "golang")

    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "${dep}" &> /dev/null; then
            echo -e "${yellow}${dep} is not installed. Installing...${rest}"
            pkg install "${dep}" -y
        fi
    done
}

# Check Dependencies
check_dependencies() {
    local dependencies=("curl" "openssl-tool" "wget" "unzip")

    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "${dep}" &> /dev/null; then
            echo -e "${yellow}${dep} is not installed. Installing...${rest}"
            pkg install "${dep}" -y
        fi
    done
}

# Install
install() {
    if command -v warp &> /dev/null || command -v usef &> /dev/null; then
        echo -e "${green}Warp is already installed.${rest}"
        return
    fi

    echo -e "${purple}*********************************${rest}"
    echo -e "${green}Installing Warp...${rest}"
    pkg update -y && pkg upgrade -y
    pkg install openssh -y
    check_dependencies

    if wget https://github.com/bepass-org/vwarp/releases/latest/download/vwarp_android-arm64.zip &&
        unzip vwarp_android-arm64.zip &&
        mv vwarp warp &&
        chmod +x warp &&
        cp warp "$PREFIX/bin/usef" &&
        cp warp "$PREFIX/bin/vwarp" &&
        cp warp "$PREFIX/bin/warp"; then
        rm "README.md" "LICENSE" "vwarp_android-arm64.zip"
        echo "================================================"
        echo -e "${green}Warp installed successfully.${rest}"
        socks
    else
        echo -e "${red}Error installing Warp.${rest}"
    fi
}

# Install arm
install_arm() {
    if command -v warp &> /dev/null || command -v usef &> /dev/null; then
        echo -e "${green}Warp is already installed.${rest}"
        return
    fi

    echo -e "${purple}*********************************${rest}"
    echo -e "${green}Installing Warp...${rest}"
    pkg update -y && pkg upgrade -y
    pkg install openssh -y
    check_dependencies

    # Determine architecture
    case "$(dpkg --print-architecture)" in
        i386) ARCH="386" ;;
        amd64) ARCH="amd64" ;;
        armhf) ARCH="arm5" ;;
        arm) ARCH="arm7" ;;
        aarch64) ARCH="arm64" ;;
        *) echo -e "${red}Unsupported architecture.${rest}"; return ;;
    esac

    WARP_URL="https://github.com/bepass-org/vwarp/releases/latest/download/vwarp_linux-$ARCH.zip"

    if wget "$WARP_URL" &&
        unzip "vwarp_linux-$ARCH.zip" &&
        mv vwarp warp &&
        chmod +x warp &&
        cp warp "$PREFIX/bin/usef" &&
        cp warp "$PREFIX/bin/vwarp" &&
        cp warp "$PREFIX/bin/warp"; then
        rm "README.md" "LICENSE" "vwarp_linux-$ARCH.zip"
        echo -e "${blue}================================================${rest}"
        echo -e "${blue}================================================${rest}"
        echo -e "${green}Warp installed successfully.${rest}"
        socks
    else
        echo -e "${red}Error installing Warp.${rest}"
    fi
}

# Get socks config
socks() {
   echo ""
   echo -e "${yellow}Copy this Config to ${purple}V2ray${green} Or ${purple}Nekobox ${yellow}and Exclude Termux${rest}"
   echo ""
   echo -e "${green}socks://Og==@127.0.0.1:8086#warp_(usef)${rest}"
   echo "or"
   echo -e "${green}Manually create a SOCKS configuration with IP ${purple}127.0.0.1 ${green}and port${purple} 8086..${rest}"
   echo -e "${blue}================================================${rest}"
   echo -e "${yellow}To run again, type:${green} warp ${rest}or${green} usef ${rest}or${green} ./warp ${rest}or${green} vwarp ${rest}"
   echo -e "${blue}================================================${rest}"
   echo -e "${green} If you get a 'Bad address' error, run ${yellow}[Arm]${rest}"
   echo -e "${blue}================================================${rest}"
   echo -e "${blue}================================================${rest}"
   echo ""
}

# Gool (warp in warp)
gool() {
    if ! command -v warp &> /dev/null || ! command -v usef &> /dev/null; then
        echo -e "${purple}*********************************${rest}"
        echo -e "${green}Please install Warp first.${rest}"
        return
    fi

    echo -e "${purple}*********************************${rest}"
    echo -e "${green}This option changes your current location to the nearest and best location.${rest}"
    echo -e "${purple}*********************************${rest}"

    while true; do
        echo -e "${cyan}Choose an option: ${purple}*${rest}"
        echo -e "${purple}                  *${rest}"
        echo -e "${cyan}[1] ${green}IPV4${purple}          *${rest}"
        echo -e "${cyan}[2] ${green}IPV6${purple}          *${rest}"
        echo -e "${cyan}[3] ${yellow}Back to Menu${purple}  *${rest}"
        echo -e "${purple}*******************${rest}"

        echo -en "${green}Please Choose: ${rest}"
        read -r option

        case $option in
            1)
                echo -e "${green}Running Warp with IPV4...${rest}"
                warp --gool -4
                ;;
            2)
                echo -e "${green}Running Warp with IPV6...${rest}"
                warp --gool -6
                ;;
            3)
                echo -e "${purple}Back to Menu.${rest}"
                menu
                ;;
            *)
                echo -e "${red}Invalid option.${rest}"
                ;;
        esac
    done
}

# Psiphon
psiphon_location() {
    if ! command -v warp &> /dev/null || ! command -v usef &> /dev/null; then
        echo -e "${purple}*********************************${rest}"
        echo -e "${green}Please install Warp first.${rest}"
        return
    fi
    echo -e "${purple}*********************************${rest}"
    echo -e "${cyan}Please choose a location from the list below by entering its number:${rest}"
    echo ""
    echo -e "${purple} 1)${yellow} Austria (AT)${rest}"
    echo -e "${purple} 2)${yellow} Belgium (BE)${rest}"
    echo -e "${purple} 3)${yellow} Bulgaria (BG)${rest}"
    echo -e "${purple} 4)${yellow} Brazil (BR)${rest}"
    echo -e "${purple} 5)${yellow} Canada (CA)${rest}"
    echo -e "${purple} 6)${yellow} Switzerland (CH)${rest}"
    echo -e "${purple} 7)${yellow} Czech Republic (CZ)${rest}"
    echo -e "${purple} 8)${yellow} Germany (DE)${rest}"
    echo -e "${purple} 9)${yellow} Denmark (DK)${rest}"
    echo -e "${purple}10)${yellow} Estonia (EE)${rest}"
    echo -e "${purple}11)${yellow} Spain (ES)${rest}"
    echo -e "${purple}12)${yellow} Finland (FI)${rest}"
    echo -e "${purple}13)${yellow} France (FR)${rest}"
    echo -e "${purple}14)${yellow} United Kingdom (GB)${rest}"
    echo -e "${purple}15)${yellow} Hungary (HU)${rest}"
    echo -e "${purple}16)${yellow} Ireland (IE)${rest}"
    echo -e "${purple}17)${yellow} India (IN)${rest}"
    echo -e "${purple}18)${yellow} Italy (IT)${rest}"
    echo -e "${purple}19)${yellow} Japan (JP)${rest}"
    echo -e "${purple}20)${yellow} Latvia (LV)${rest}"
    echo -e "${purple}21)${yellow} Netherlands (NL)${rest}"
    echo -e "${purple}22)${yellow} Norway (NO)${rest}"
    echo -e "${purple}23)${yellow} Poland (PL)${rest}"
    echo -e "${purple}24)${yellow} Romania (RO)${rest}"
    echo -e "${purple}25)${yellow} Serbia (RS)${rest}"
    echo -e "${purple}26)${yellow} Sweden (SE)${rest}"
    echo -e "${purple}27)${yellow} Singapore (SG)${rest}"
    echo -e "${purple}28)${yellow} Slovakia (SK)${rest}"
    echo -e "${purple}29)${yellow} Ukraine (UA)${rest}"
    echo -e "${purple}30)${yellow} United States (US)${rest}"
    echo ""

    echo -en "${green}Enter the ${yellow}number${green} of the location [${yellow}default: 1${green}]: ${rest}"
    read -r choice
    choice=${choice:-1}

    case "$choice" in
        1) location="AT" ;;
        2) location="BE" ;;
        3) location="BG" ;;
        4) location="BR" ;;
        5) location="CA" ;;
        6) location="CH" ;;
        7) location="CZ" ;;
        8) location="DE" ;;
        9) location="DK" ;;
        10) location="EE" ;;
        11) location="ES" ;;
        12) location="FI" ;;
        13) location="FR" ;;
        14) location="GB" ;;
        15) location="HU" ;;
        16) location="IE" ;;
        17) location="IN" ;;
        18) location="IT" ;;
        19) location="JP" ;;
        20) location="LV" ;;
        21) location="NL" ;;
        22) location="NO" ;;
        23) location="PL" ;;
        24) location="RO" ;;
        25) location="RS" ;;
        26) location="SE" ;;
        27) location="SG" ;;
        28) location="SK" ;;
        29) location="UA" ;;
        30) location="US" ;;
        *) echo "Invalid choice. Please select a valid location number." ;;
    esac

    echo -e "${purple}*********************************${rest}"
    echo -e "${green}Selected location: $location${rest}"
    echo -e "${blue}*********************************${rest}"

    while true; do
        echo -e "${cyan}Choose an option: ${purple}*${rest}"
        echo -e "${purple}                  *${rest}"
        echo -e "${cyan}[1] ${green}IPV4${purple}          *${rest}"
        echo -e "${cyan}[2] ${green}IPV6${purple}          *${rest}"
        echo -e "${cyan}[3] ${yellow}Back to Menu${purple}  *${rest}"
        echo -e "${purple}*******************${rest}"

        echo -en "${green}Please Choose: ${rest}"
        read -r option

        case $option in
            1)
                echo -e "${green}Running Psiphon with IPV4...${rest}"
                warp --cfon --country $location -4
                ;;
            2)
                echo -e "${green}Running Psiphon with IPV6...${rest}"
                warp --cfon --country $location -6
                ;;
            3)
                echo -e "${purple}Back to Menu.${rest}"
                menu
                ;;
            *)
                echo -e "${red}Invalid option.${rest}"
                ;;
        esac
    done
}

#Uninstall
uninstall() {
    warp="$PREFIX/bin/warp"
    directory="/data/data/com.termux/files/home/vwarp"
    home="/data/data/com.termux/files/home"
    if [ -f "$warp" ]; then
        rm -rf "$directory" "$PREFIX/bin/usef" "wa.py" "$PREFIX/bin/warp" "$PREFIX/bin/vwarp" "warp" "/data/data/com.termux/files/home/.cache/vwarp" > /dev/null 2>&1
        echo -e "${purple}*********************************${rest}"
        echo -e "${red}Uninstallation completed.${rest}"
        echo -e "${purple}*********************************${rest}"
    else
        echo -e "${yellow} ____________________________________${rest}"
        echo -e "${red} Not installed.Please Install First.${rest}${yellow}|"
        echo -e "${yellow} ____________________________________${rest}"
    fi
}

# Warp to Warp plus
vwarp() {
    if ! command -v python &> /dev/null; then
        echo "Installing Python..."
        pkg install python -y
    fi

    echo -e "${green}Downloading and running${purple} Warp+ script...${rest}"
    wget -O wa.py https://raw.githubusercontent.com/Ptechgithub/configs/main/wa.py
    python wa.py
}

# Menu
menu() {
    clear
    echo -e "${green}By --> Peyman * Github.com/Ptechgithub * ${rest}"
    echo ""
    echo -e "${yellow}❤️Github.com/${cyan}bepass-org${yellow}/vwarp❤️${rest}"
    echo -e "${purple}*********************************${rest}"
    echo -e "${blue}  ###${cyan} vwarp in Termux ${blue}###${rest} ${purple}  * ${rest}"
    echo -e "${purple}*********************************${rest}"
    echo -e "${cyan}1]${rest} ${green}Install Warp (vpn)${purple}           * ${rest}"
    echo -e "                              ${purple}  * ${rest}"
    echo -e "${cyan}2]${rest} ${green}Install Warp (vpn) [${yellow}Arm${green}] ${purple}    * ${rest}"
    echo -e "                              ${purple}  * ${rest}"
    echo -e "${cyan}3]${rest} ${green}Uninstall${rest}${purple}                    * ${rest}"
    echo -e "                              ${purple}  * ${rest}"
    echo -e "${cyan}4]${rest} ${green}Gool [${yellow}warp in warp${green}]${purple}          * ${rest}"
    echo -e "                              ${purple}  * ${rest}"
    echo -e "${cyan}5]${rest} ${green}Psiphon [${yellow}+ All Locations${green}]${purple}    * ${rest}"
    echo -e "                              ${purple}  * ${rest}"
    echo -e "${cyan}6]${rest} ${green}Warp to ${purple}Warp plus${green} [${yellow}Free GB${green}]${rest}${purple}  * ${rest}"
    echo -e "                              ${purple}  * ${rest}"
    echo -e "${red}0]${rest} ${green}Exit                         ${purple}* ${rest}"
    echo -e "${purple}*********************************${rest}"

    echo -en "${cyan}Please enter your selection [${yellow}0-6${green}]:${rest}"
    read -r choice

    case "$choice" in
       1)
            install
            warp
            ;;
        2)
            install_arm
            warp
            ;;
        3)
            uninstall
            ;;
        4)
            gool
            ;;
        5)
            psiphon_location
            ;;
        6)
            vwarp
            ;;
        0)
            echo -e "${purple}*********************************${rest}"
            echo -e "${cyan}By 🖐${rest}"
            exit
            ;;
        *)
            echo -e "${purple}*********************************${rest}"
            echo -e "${red}Invalid choice. Please select a valid option.${rest}"
            echo -e "${purple}*********************************${rest}"
            ;;
    esac
}
menu
