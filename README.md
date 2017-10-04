# nfancurve-amd
**Must be run as root, this script writes to /sys/class/hwmon/hwmonX/pwm1**

A fan control script for amdgpu users, based off nan0s7's nfancurve

The fan control occurs in steps, please use several points to avoid sudden ramping-up.

## Features
- by default it has a severe fan curve profile, you should probably change it
- automatically controls GPU fan according to the curve
- easy to read code, with plentiful comments (beginner friendly)
- "intelligently" adjusts the time between tempurature readings
- very lightweight

## Prerequisites
- Bash version 4 and above, or a bash-like shell with the same commands
- an AMD card with a pwm fan
- amdgpu driver

## How to use
- Find your GPU's `hwmon` number and edit `gpuid` in the script to match (there is a short howto at the top of the script)
- `chmod +x temp.sh`
- Run `./temp.sh` as root
- This script does not take arguments, but has editable variables at the top of the script.

To run in the background, use this command as root: `nohup ./temp.sh >/dev/null 2>&1 &`
