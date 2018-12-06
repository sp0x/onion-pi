# onion-pi
Turn a standard Raspbian install into a [tor](https://torproject.org)-ified
wifi access point with [ansible](https://www.ansible.com/).

This is the [Raspbian Stretch](https://www.raspberrypi.org/downloads/raspbian/) edition of stock adafruit [onion-pi](https://learn.adafruit.com/onion-pi?view=all).  You may want to read up on [what's new in Stretch](https://wiki.debian.org/NewInStretch).

This build is different from the original in some minor details. See the list
at end of this document for details.

## Ingredients

We will make use of

* 1 RaspberryPi B ver 3 or 3+ (with onboard WiFi)
* 1 micro SD card (min. 4 GB)
* 1 power adapter
* 1 keyboard (USB preferred)
* 1 TV or other device able to display HDMI signals from your RaspberryPi
* 1 USB wifi adapter (optional)

To setup everything, we additionally need a computer with USB and an SD-card
reader. If your computer does not have a built-in card-reader, you can use any
cheap USB-pluggable SD-card reader available at paper stores and similar.


## Preparation

### 1) Download and verify the OS image

Download the lite image of Raspbian Stretch provided from:

  https://www.raspberrypi.org/downloads/raspbian/

Afterwards you should have a file named ``2018-06-27-raspbian-stretch-lite.zip``. This ZIP archive should contain one
big image file.

Check the sha1 sum of the file:

    openssl sha -sha256 2018-06-27-raspbian-stretch-lite.zip | grep 3271b244734286d99aeba8fa043b6634cad488d211583814a2018fc14fdca313

and make sure it equals the number given on the website (grep prints that hash).
    

### 2) Write the image on OSX

For SD cards larger than 64GB, be sure to start by [formatting them as FAT32](https://www.raspberrypi.org/documentation/installation/sdxc_formatting.md) (not exFAT), as you may have trouble with ``dd`` otherwise.

Insert the SD card, and figure out which number the disk is:

    diskutil list

Assuming it's /dev/disk4, unmount the disk (or change the reference to ``4`` for your specific disk number below):

    diskutil unmountDisk /dev/disk4

Unzip the file and write the contents to a locally attached SD card:

     unzip 2018-06-27-raspbian-stretch-lite.zip
     sudo dd bs=1m if=2018-06-27-raspbian-stretch-lite.img of=/dev/rdisk4 conv=sync

Note that the /dev/rdisk4 is different from /dev/disk4 in that rdisk doesn't buffer the writing, and so the data is flushed for each chunk written which should be faster.

Then eject the disk:

    sudo diskutil eject /dev/rdisk4

### 3) Install Ansible from Homebrew

Ansible basically allows us to run idempotent configuration changes, and is required for this tutorial.  Everything could be done with straight shell/bash/etc, but the goal here is to go fast with few errors, not to document what's changing.  You can always view the ansible yaml files to see what's happening.

    brew install ansible

Make sure you have version 2.4 or higher installed on the host where you also have SSH access to the pi.

    ansible --version

## Basic Setup

### 1) Start Your RaspberryPi

Stick the prepared SD card into your RaspberryPi.

Plug in your keyboard and connect the HDMI port with an appropriate
device. Also plug in the power adapter, which will power up the RaspberryPi.


### 2) Setup basic settings

Login into your new system using the keyboard and monitor attached to the pi with credentials "pi" / "raspberry".

Immediately, change the default password.

    passwd

Configure and start SSH, so further commands can be run via the ansible scripts.

    sudo systemctl enable ssh
    sudo service ssh status
    sudo service ssh restart

Take note of the IP address of the eth0 connection on the pi:

    ifconfig -a

### 3) Setup Basic Config

All of the localization, charset, hostname, etc options that are normally run via ``sudo raspi-config`` are taken care of in the ansible scripts, with parameters passed on the CLI.  That way, there are fewer manual things to do.

Part of good security practices nessecitates creating a new user, other than the default ``pi`` user, and then disabling the default ``pi`` user from logging in via SSH.  In this example, a new user named ``jason`` is created, which will be used for future logins via SSH.

You should change the ``--extra-vars`` as appropriate.

    ansible-playbook -i 192.168.1.131, \
       --become \
       --ask-pass \
       --ask-become-pass \
       --user pi \
       setup_basic.yml \
       --extra-vars "username=jason password=YOUR_SECRET hostname=onionpi timezone=America/Los_Angeles country=US"

### 4) Setup Mail Config (Optional)

This step is not required.  Having the pi email you when normal system maintenance jobs run is very helpful for debugging and monitoring, and is highly recommended.  This setup uses an app-specific password you create for your Gmail account.

    ansible-playbook -i 192.168.1.131, \
      --become \
      --ask-pass \
      --ask-become-pass \
      --user jason \
      setup_mail.yml \
      --extra-vars "hostname=onionpi username=jason gmail_username=jasonthrasher gmail_password=GOOGLE_APP_SPECIFIC_PASSWORD"

If you don't have a gmail account, you'll need to edit the yml script to change the ``@gmail.com`` domain appropriately.

### 5) Setup WiFi OnionPi

This sets up the pi as an access point in standalone network (NAT) mode as [documented by Adafruit](https://learn.adafruit.com/onion-pi?view=all), but setup to work with Raspbian Stretch.

    ansible-playbook -i 192.168.1.131, \
      --become \
      --ask-pass \
      --ask-become-pass \
      --user jason \
      setup_onionpi.yml \
      --extra-vars "dns_servers=8.8.8.8,8.8.4.4"

Reboot the pi, and attempt to connect to it from another computer via WiFi, to verify that it's acting as an access point.  Open a browser and navigate to the [tor check page](https://check.torproject.org/) to verify that your Tor proxy is working.  Generally, you should use an incognito window (with no plugins enabled, or logged in cookies set), when you do this, otherwise your identity may be read from the exit node.

### 6) Access your `OnionPi`

Did it work? You can try with your laptop.

First, look what networks are available to connect to. There should be an
additional network called ``OnionPi``. Connect to it.

The network is encrypted and therefore we need a password. The default password is

    AardvarkBadgerHedgehog

and set in `/etc/hostapd/hostapd.conf`.

If you can connect to the network, try to browse some site. As `ping` does not
work, you can for instance browse

    https://check.torproject.org

to check under which IP you are seen in the internet. This page can tell
whether you look like using `tor` or not. It might also complain that you do
not use the `torbrowser`.

## Differences to Regular Adafruit Onion-pi Setup

The deployment shown here tries to follow closely the more or less canonical
'Adafruit' recipe as described at:

    https://learn.adafruit.com/onion-pi/overview

Some things, however, were changed:

- IPv4 forwarding is not activated. Instead we make sure its turned off.

  There is no reason to forward all ipv4 packets if they cannot be handled as
  regular tor traffic.

- `/etc/init.d/hostapd` script is not changed.

  We do not set a default `DAEMON_CONF` in the init.d-script, because this
  value should be set only in `/etc/default/hostapd`.

- We additionally install and configure `unattended-upgrades`.

  Updates are triggered by a cronjob every other hour.

- A new user is created, and the pi user is disabled for SSH

## Setup USB Wifi (Optional)  (this section is incomplete!)

This optional step allows you to avoid the the need for an ethernet connection.  The USB WiFi device (wlan1 in this case) is used to connect to the upstream network (like a coffee house hotspot), while the onboard WiFi (wlan0) is used as a hotspot for WiFi clients (like your phone or laptop).

If not done already, plug in the USB wifi adapter into your raspi.

We need internet access to complete the next steps. This step depends on your
local networks.

A list of available networks should be provided with:

    (raspi) $ sudo iwlist wlan0 scan | grep ESSID

We then have to edit

    (raspi) $ sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

To add a network without password add something like:

    network={
        ssid="Freifunk"
        key_mgmt=NONE
    }

For networks with a password you want to run `wpa_passphrase`:

    (raspi) $ sudo bash
    (raspi) # wpa_passphrase '<SSID>' '<PASSWORD>' >> /etc/wpa_supplicant/wpa_supplicant.conf
    (raspi) # exit

Afterwards a wifi restart is required. This can be done with:

    (raspi) $ sudo wpa_cli reconfigure
    Selected interface 'wlan0'
    OK

The negotiations might take some seconds, so you should wait for some time,
until the new connection will be established. Keep the displayed interface name
in mind (``wlan0`` or ``wlan1``).

You can get the IP number assigned by running

    (raspi) $ ifconfig wlan0

where `wlan0` is the interface name displayed before.

There should be one line starting with `inet` or `inet6` stating the current
IP.

Now try to connect to your onionpi via SSH:

    $ ssh pi@<IP-OF-YOUR-RASPBERRY-PI>

# Appendix

## Setup the Pi as a WiFi Hotspot

This ansible playbook sets up the pi as an access point in standalone network (NAT) mode as documented [here](https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md).  This is an example of using dnsmasq instead of isc-dhcp-server as the DHCP server.  Replacing isc-dhcp-server for an onionpi config is left as an excercise for the reader, but this playbook is a good starting point.

    ansible-playbook -i 192.168.1.131, \
      --become \
      --ask-pass \
      --ask-become-pass \
      --user jason \
      setup_accesspoint.yml \
      --extra-vars "dns_servers=8.8.8.8,8.8.4.4"

Reboot the pi, and attempt to connect to it from another computer via WiFi, to verify that it's acting as an access point.
