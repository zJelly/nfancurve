## automating this script
This script can be run at startup using a systemd service. I would recommend first putting the script in a safe place, and `chown`ing it to root, so that nobody can easily modify it

**Please only do this if you understand what is happening, and after you have set up the script how you like it**

Move the script somewhere out of the way, and change its permissions:
```
sudo mkdir /etc/nfancurve-amd
sudo mv ./temp.sh /etc/nfancurve-amd
sudo chown root:root /etc/nfancurve-amd/temp.sh
sudo chmod 755 /etc/nfancurve-amd/temp.sh
```
Create a systemd service:
```
touch /etc/systemd/system/nfancurve-amd.service
sudo chmod 644 /etc/systemd/system/nfancurve-amd.service
sudo nano /etc/systemd/system/nfancurve-amd.service
```
add the following to `/etc/systemd/system/nfancurve-amd.service`

```
[Unit]
Description=Run nfancurve-amd automatically

[Service]
Type=simple
RemainAfterExit=false
ExecStart=/etc/nfancurve-amd/temp.sh

[Install]
WantedBy=multi-user.target
```

to run it
```
sudo systemctl daemon-reload
sudo systemctl start nfancurve-amd.service
```
to run it at startup:
```
sudo systemctl enable nfancurve-amd.service
```

(Instructions from https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sect-managing_services_with_systemd-unit_files)
