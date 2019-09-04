To deploy an SAP S/4 environment using these scripts, do the following in Azure cloud shell:

```bash
git clone https://github.com/AzureCAT-GSI/Hana-Test-Deploy.git
cd Hana-Test-Deploy/tests
```

Edit the azuredeploy.cfg with your own values.  You can use vi, emacs or visual studio code within cloud shell.

***VERY IMPORTANT: put in your own password and SSH public key in the proper fields of the azuredeploy.cfg***

In cloud shell, if you get timed out on running any of the following, the operation that you were running will still complete - it's all running within Azure.  

For all machines, the username and password to login with are controled by the azuredeploy.cfg
To check the status of any of the software installs, you can ssh to the machine, sudo to root, and do the following:
tail -f /var/lib/waagent/custom-script/download/0/stderr
This will show you the log for the linux custom script extension.  When the linux custom script has completed, it should print out:

```bash
software deploy completed.  Please check for proper software install
```

To actually deploy, do the below steps.  Please run these steps individually - they can take a long time and you will want each step to complete before going on to the next one.

```bash
chmod u+x *.sh
./vnet-inf
./linuxjumpbox-inf.sh #(if you want a linux jumpbox to ssh to)
./jb-inf.sh #(if you want a windows jumpbox to RDP to)
./iscsi-inf.sh
./iscsi-sw.sh

At this point, if you are setting up your own NFS cluster, use this:
    ./nfs-inf.sh
    ./nfs-sw.sh #(this will generally take a long time. check the stderr file.  If you select SUSE 12 SP4+, this will be much faster)
otherwise, if you are using ANF, run this:
    ./anf-inf.sh
    when this is done, you will have to gather the IP addresses for the ANF mount points from the Azure portal, and transfer them into the azuredeploy.cfg file i
    in the nfs mount locations.
    
./hana-inf.sh
./hana-sw.sh #(this should take 30-45 minutes - check the stderr file for completion)
./ascs-inf.sh
./ascs-sw.sh #(this should take about 1 hour - check the stderr file for completion)
./pas-inf.sh
./pas-sw.sh #(this should take 1-2 hours - check the stderr file for completion)
```

when this is all done, you will have a few post automation steps to do:

1) finish the ASCS/ERS cluster setup.  details to be added soon

1) On the PAS server, you need to set the hdbuserstore to point to the hana load balancer rather than to a single HANA instance.

You should then be able to go to the windows jumpbox, install sapgui, and connect to the primary app server.  The SAP* user password will be what you put in the azuredeploy.cfg.
