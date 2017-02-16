# Config multipathd system service on Ubuntu
Newer Ubuntu system uses systemd to config/manage services.  If `systemctl` is not present,
run `apt-get install systemd` first to get systemd running.

After "make install", edit file `/usr/lib/systemd/system/multipathd.service`.
Edit "ExecStart" and "ExecReload" to point to the right path where multipathd is installed,
usually this is "/usr/local/sbin".

Then, run `systemctl unmask multipathd`, `systemctl enable multipathd`.

# Install
Pre-requisite packages to compile

```
sudo apt-get install libdevmapper-dev
sudo apt-get install libreadline-dev

export LD_LIBRARY_PATH=./libmpathpersist:./libmultipath

modprobe dm-multipath
multipathd

```

# Example /etc/multipath.conf


```
defaults {
  user_friendly_names     yes
  path_grouping_policy    failover
  polling_interval        3
  path_selector           "round-robin 0"
  failback                immediate
  features                "0"
  no_path_retry           1
}

multipaths {
  multipath {
    wwid    360000000000000000000000000000001
    alias   pair0
    # this alias is to generated on /dev/mapper/pair0,
    #when you login the SCSI target. Instead of “/dev/sd*”,
    #you can access it by “/dev/mapper/pair0”
  }
  multipath {
    wwid    360000000000000000000000000000002
    alias   pair1
  }
  multipath {
    wwid    360000000000000000000000000000003
    alias   pair2
  }
}
```

multipath -r

or 

multipathd -d


## Set up serverice

1. sudo vi /usr/lib/systemd/system/multipathd.service

```
change /bin to /sbin
change "ExecStart=/usr/local/bin/multipathd -d -s"  to "ExecStart=/usr/local/sbin/multipathd -d -s"
change "ExecReload=/usr/local/bin/multipathd reconfigure" to "ExecReload=/usr/local/sbin/multipathd reconfigure"
```

2. sudo systemctl start multipathd

3. sudo service multipathd restart


