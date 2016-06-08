<<<<<<<<<<<<<<<<<<<   Multipath Setup for failover >>>>>>>>>>>>>>>>>>>>> 


Target System>>>>>>>>>>>>> 

	1.	 Download tgt code
		https://github.com/hdatas/tgt


		a.	 modify the configuration files that will be configured 
			for multipath failover.  you should keep all Luns that are 
			in the same shard with 
			i.	same iqn name
			ii.	same scsi_id => will turn to WWN with adding prefixed ones.  

	   # vim /etc/tgt/targets.conf

		<target iqn.2016-01.hcd.com:iscsi-server2> => iqn name
		    bs-type kvs
		    block-size 4096 
		    volume-size 0x40000000

		    controller_tid 35
		    <backing-store tcp:ceph11:10000> 
		        vendor_id HCD 
	        	scsi_id 12345670	=> SCSI ID 
		        lun 1
		    </backing-store>
		</target>

	2.	Run all tgts(Master/Slave) in the same shard group. 
		a.	Terminal 1# ./usr/tgtd/ -f 
		b.	Terminal 2# ./scripts/tgt-admin –e 

Initiator System>>>>>>>>>>>>>

	1.	Install iSCSI Initiator 
		sudo apt-get install open-iscsi

	2.	Multipath-tools-0.5.0
		a.	Download https://github.com/hdatas/multipath-tools-0.5.0
		b.	make; make install;
	3.	configuration file 

		#vim /etc/multipath.conf

		defaults {
		       user_friendly_names     yes
		       path_grouping_policy    failover
		       polling_interval        3
		       path_selector           "round-robin 0"
		       failback                immediate
		       features                "1 queue_if_no_path"
		#       no_path_retry           1
		}

		multipaths {
			multipath {
				wwid    360000000000000000000000012345670
				#any lun has this WWN will be mapped into common alias 
				alias   pair0
				# this alias is to generated on /dev/mapper/pair0,
				#when you login the SCSI target. Instead of “/dev/sd*”, 
				#you can access it by “/dev/mapper/pair0”  
			}	
		}


	4.	ISCSI discovery/login/logout/ 
		a.	Reset :If you want to Initialize all the discovery history, 
			you can do that as below 
			i.	clean up the previous history 
				# rm -rf /etc/iscsi/
		b.	Discovery : 
			# iscsiadm -m discovery -t st -p 192.168.56.11:3260
			192.168.56.11:3260,1 iqn.2016-01.hcd.com:iscsi-server2

			# iscsiadm -m discovery -t st -p 192.168.56.12:3260
		   	192.168.56.12:3260,1 iqn.2016-01.hcd.com:iscsi-server2

		c.	Login :

		- 1st master login

		# iscsiadm -m node -l -T iqn.2016-01.hcd.com:iscsi-server2 -p 192.168.56.11:3260
		Logging in to [iface: default, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.11,3260] (multiple)
		Login to [iface: default, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.11,3260] successful.


		- Check Multipath status (single list) 
		root@jay0:~# multipath -ll
			pair0 (360000000000000000000000012345670) dm-0 HCD,VIRTUAL-DISK
			size=1.0G features='1 queue_if_no_path' hwhandler='0' wp=rw
			`-+- policy='round-robin 0' prio=1 status=active => master only
			`- 43:0:0:1 sdb 8:16 active ready running

		- 2nd  master login
		# iscsiadm -m node -l -T iqn.2016-01.hcd.com:iscsi-server2 -p 192.168.56.12:3260
		  Logging in to [iface: default, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.12,3260] (multiple)
		  Login to [iface: default, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.12,3260] successful.


		- Check Multipath status (Double List) 

		~# multipath -ll
			pair0 (360000000000000000000000012345670) dm-0 HCD,VIRTUAL-DISK
			size=1.0G features='1 queue_if_no_path' hwhandler='0' wp=rw
			|-+- policy='round-robin 0' prio=1 status=active  =>master 
			| `- 44:0:0:1 sdc 8:32 active ready running
			`-+- policy='round-robin 0' prio=1 status=enabled => slave
			`- 43:0:0:1 sdb 8:16 active ready running


		d.	Logout
		root@jay0:~# iscsiadm -m node -u -T iqn.2016-01.hcd.com:iscsi-server2 -p 192.168.56.12:3260
		Logging out of session [sid: 42, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.12,3260]
		Logout of [sid: 42, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.12,3260] successful.
		root@jay0:~# iscsiadm -m node -u -T iqn.2016-01.hcd.com:iscsi-server2 -p 192.168.56.11:3260
		Logging out of session [sid: 41, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.11,3260]
		Logout of [sid: 41, target: iqn.2016-01.hcd.com:iscsi-server2, portal: 192.168.56.11,3260] successful.
		root@jay0:~# 



Failover Test >>>>>  

	1.	Login the Master target Only
	2.	if you want to switch to the other path( the slave in the shard), login the slave target and then logout the master. 
	3.	By the above sequence, dynamic failover can be managed.   

Recofigure Option >>>

	if you want to update the latest configuration file that has been modifie on the condition of running multipathd daemon, you just execute  ./multipathd -r. that will update all of configuration file changes.    


