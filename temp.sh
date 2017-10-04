#!/bin/bash
echo "###################################"
echo "# nan0s7's fan speed curve script #"
echo "###################################"
echo

# Editable variables
gpuid=1 # look in /sys/class/hwmon, find the right number for your gpu. mine is hwmon1, so the gpuid is 1.
declare -a fcurve=( "76" "86" "95" "108" "128" "255" ) # Fan speeds (multiply percentage by 2.55 and take closest integer, amdgpu takes fanspeed as a 0-255 value)
declare -a tcurve=( "35" "43" "50" "58" "65" "90" ) # Temperatures
# ie - when temp<=35 degrees celsius the fan speed=84

# Variable initialisation (so don't change these)
gpu=0
temp=0
old_temp=0
tdiff=0
slp=0
eles=0
old_speed=0
speed=${fcurve[0]}
clen=$[ ${#fcurve[@]} - 1 ]
declare -a diff_curve=()
declare -a diff_c2=()
hwpath="/sys/class/hwmon/hwmon"

# Make sure the variables are back to normal
# changed set_fan_control to 2 (auto)
function finish {
	echo 2 > $hwpath$gpuid/pwm1_enable
	echo -e "\nFan control set back to auto mode."
	unset gpu
	unset temp
	unset old_temp
	unset slp
	unset speed
	unset old_speed
	unset i
	unset tdiff
	unset clen
	unset diff_c2
	unset diff_curve
	unset tcurve
	unset fcurve
	unset eles
	unset diffr
	unset hashes
	unset gpuid
	unset hwpath
	echo -e "\nSuccessfully caught exit & cleared variables!"
}
trap finish EXIT

# Check driver version
# compare hwpath name string to known value
function check_driver {
	if ! [ "$(cat $hwpath$gpuid/name)" == 'amdgpu' ]; then
		echo "You're not using amdgpu, or your gpuid is not set correctly"
		exit
	else
		echo "A likely supported driver version was detected."
	fi
}

# Check that the curves are the same length
function check_arrays {
	if ! [ ${#fcurve[@]} -eq ${#tcurve[@]} ]; then
		echo "Your two fan curves don't match up - you should fix that."
		exit
	else
		echo -e "The fan curves match up! \nGood job! :D"
	fi
}

# Cleaner than worrying about if x or y statements in main imo
function get_abs_tdiff {
	if [ "$1" -le "$2" ]; then
		tdiff=$[ $2 - $1 ]
	else
		tdiff=$[ $1 - $2 ]
	fi
}

# gotta divide temp readout by 1000 to get celsius value
# i think nvidia-settings returns a celsius integer
function get_temp {
	temp=`cat $hwpath$gpuid/temp1_input`
	temp=("$[ $temp / 1000]")
}

# This function is the biggest calculation in this script (use it sparingly)
# change speed=100 to speed=255
function get_speed {
        # Execution of fan curve
	if [ "$temp" -gt "$[ ${tcurve[-1]} + 10 ]" ]; then
                speed="255"
        else
                # Get a new speed from curve
                for i in `seq 0 $clen`; do
                        if [ "$temp" -le "${tcurve[$i]}" ]; then
                                speed="${fcurve[$i]}"
                                eles=$i
                                break
                        fi
                done
	fi
}

# Enable/disable fan control (if CoolBits is enabled) - see USAGE.md
# for amdgpu: 0=full on 1=manual, 2=auto
function set_fan_control {
	echo $1 > $hwpath$gpuid/pwm1_enable
	echo "sending $1 to pwm1_enable"
}

# diff curves are the difference in fan-curve temps for better slp changes
function set_diffs {
	for i in `seq 0 $[ $clen - 1 ]`; do
		diffr=$[ ${tcurve[$[ $i + 1 ]]} - ${tcurve[$i]} ]
		diff_curve+=("$diffr")
		diff_c2+=("$[ $diffr / 2 ]")
	done
	unset diffr
}

# Function to contain the nvidia-settings command for changing speed
# send it to hwpath instead
function set_speed {
	if ! [ "$1" -eq "$2" ]; then
		echo $1 > $hwpath$gpuid/pwm1
		echo "sending $1 to pwm1"
	fi
}

function main {
	check_driver
	check_arrays
	set_fan_control 1
	set_diffs
	set_speed $speed $old_speed

	# Anything in this loop will be running in the persistant process
	while true; do
		# Current temperature query
		get_temp

		# Calculate tdiff and make sure it's positive
		get_abs_tdiff $temp $old_temp

		# Better adjustments based on tcurve values
		if [ "$tdiff" -ge "${diff_curve[$eles]}" ]; then
			old_speed=$speed
			get_speed
			set_speed $speed $old_speed
			old_temp=$temp
			echo "old_temp old_speed speed temp"
			echo "$old_temp       $old_speed       $speed    $temp"
			slp=3
		elif [ "$tdiff" -ge "${diff_c2[$eles]}" ]; then
			slp=5
		else
			slp=7
		fi

		# Execute `./temp.sh 1>log.txt 2>&1` to log all output
		# Uncomment the following line if you want to log stuff
		# echo "t="$temp" ot="$old_temp" sp="$speed" tdif="$tdiff" slp="$slp

		# This will automatically adjust
		sleep "$slp"
	done
}

main
