# vm-portgroup-segment
Change VM port assignment from/to portgroup to segment.

This is done by DataCenter/Cluster.


Create a CSV with PortGroup,Segment called segment.csv in your Documents directory.
The CSV should look like the following.  The header line is necessary:


	PortGroup,Segment

	V-61,segment-vlan-61

	MGT-NATIVE-VLAN,seg-vlan-0



A file called cluster.txt is created in your Documents directory and it will keep track of completed clusters.  You can edit this file if you would like to act on a cluster again.

there are 2 script files that will do the same thing but work differently:

vmseg.ps1 works on each VM and each interface at one time. This is a little slow and inefficient.

vmseg-2.ps1 works on all interfaces that match a certain portgroup from the CSV file.  This is a bit more efficent.

vmseg-3.ps1 works per host rather than per cluster.  A file called host.txt is created in your Documents directory and it will keep track of completed hosts.

vmseg-4.ps1 similar to vmseg-2, works on all interfaces that match a certain portgroup from the CSV file.  This is much faster and more efficent than vmseg-2.
