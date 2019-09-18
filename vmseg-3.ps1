#What file to import that contains portgroup,segment
#
#The file first line must be 
#PortGroup,Segment
#
#Then portgroup,segment
#MGT-NATIVE-VLAN,MGT-NATIVE-VLAN
#
$csvfile = '~\Documents\segment.csv'


#What file to store completed clusters
$hostfile = '~\Documents\hosts.txt'
$hostsdone = get-content $hostfile -ErrorAction Ignore


#Connect to VC
$viServer = Read-Host -Prompt 'What is your vCenter server name: '
$serverlist = $global:DefaultVIServer
if($serverlist) {
	foreach ($server in $serverlist) {
		if($server.Name -eq $viServer){
			$vc=$server
			write-Host -BackgroundColor blue "You are connected to $viServer, Hooray!"
			break
		}
	}
}
if ($vc -eq $null) {
	$vc=connect-viserver -server $viServer
}

#Connect to NSX
#$nsxServer = Read-Host -Prompt 'Input your NSX server  name'
#connect-nsxtserver -server $nsxServer


#Create Windows Dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

$form.Controls.Add($listBox)
$form.Topmost = $true



#Select from list of DCs
$dcselected =""
$dcs = get-datacenter
$form.Text = 'DataCenters:'
$label.Text = 'Please Select a DataCenter:'

foreach ($dc in $dcs) {
	[void] $listBox.Items.Add($dc.name)
}
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $dcselected = $listBox.SelectedItem
}
else {
	exit
}
[void] $listBox.Items.Clear()


#Select from list of clusters
$clusterselected = ""
$vcclusters = get-datacenter -name $dcselected | get-cluster
$form.Text = 'Clusters:'
$label.Text = 'Please Select a Cluster:'

foreach ($vccluster in $vcclusters) {
	[void] $listBox.Items.Add($vccluster.name)
}
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $clusterselected = $listBox.SelectedItem
}
else {
	exit
}
[void] $listBox.Items.Clear()

#Select from list of hosts
$vmhostselected = ""
$vmhosts = get-datacenter -name $dcselected | get-cluster $clusterselected | get-vmhost
$form.Text = 'Hosts:'
$label.Text = 'Please Select a Host:'

foreach ($vmhost in $vmhosts) {
	if ($($dcselected + ":" + $vccluster.name +":"+$vmhost.name) -notin $hostsdone) {
		[void] $listBox.Items.Add($vmhost.name)
	}
}
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $vmhostselected = $listBox.SelectedItem
}
else {
	exit
}
[void] $listBox.Items.Clear()



if ($dcselected -and $clusterselected -and $vmhostselected) {
	
	#Do this for real or Whatif
	$form.Text = "What If?"
	$label.Text = "Is This for Real?"
	$OKButton.Text = 'Do It'
	$CancelButton.Text = 'What If'
	$listBox.Size = New-Object System.Drawing.Size(0,0)
	$result = $form.ShowDialog()


	#Get VMs
	$sortedvms = get-datacenter -name $dcselected | get-cluster -name $clusterselected | get-vmhost -name $vmhostselected | get-vm | sort-object 
	write-Host -BackgroundColor blue "Working on the following VMs:"
	$sortedvms | % {
		write-host $_.name -nonewline 
		$strsep = "-"*(50-$_.name.length)
		write-host $strsep  -nonewline
		write-host $_.vmhost.name
	}

	#Set Network Adapters
	import-csv $csvfile | % {
		write-host ""
		$thisportgroup=$_.PortGroup
		Write-Host -BackgroundColor blue "Working on PortGroup: " $thisportgroup
		$mynetadapters = $sortedvms | get-networkadapter | where {$_.networkname -eq $thisportgroup}
		$doit=0
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			$doit=1
			$mynetadapters|set-networkadapter -NetworkName $_.Segment -confirm:$false
		} 
		else {
			$mynetadapters|set-networkadapter -NetworkName $_.Segment -whatif -confirm:$false
		}
	}

	#Remeber which hosts are done
	if ($doit) {
		$dcclusterhost = $dcselected + ":" + $clusterselected + ":" + $vmhostselected
		$form.Text = "$vmhostselected"
		$label.Text = "Did host $vmhostselected Complete?"
		$OKButton.Text = 'Yes'
		$CancelButton.Text = 'No'

		$result = $form.ShowDialog()
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			Add-Content $hostfile $dcclusterhost
		}
	}
}
if ($vc) {
	$form.Text = "$vc"
	$label.Text = "Disconnect From $vc"
	$OKButton.Text = 'Yes'
	$CancelButton.Text = 'No'

	$result = $form.ShowDialog()
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		disconnect-viserver -server $vc -confirm:$false
	}

}
