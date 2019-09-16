# vm-portgroup-segment
Change VM port assignment from/to portgroup to segment

This is done by DataCenter/Cluster


Create a CSV with PortGroup,Segment called segment.csv in your Documents directory
The CSV should look like the following.  The header line is necessary:

PortGroup,Segment
V-61,segment-vlan-61
MGT-NATIVE-VLAN,seg-vlan-0

A file called cluster.txt is created in your Documents directory and it will keep track of completed clusters.  You can edit this file if you would like to act on a cluster again.
