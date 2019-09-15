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
$clusterfile = '~\Documents\clusters.txt'
$clustersdone = get-content $clusterfile -ErrorAction Ignore



#Connect to VC
$viServer = Read-Host -Prompt 'Input your VC server  name'
connect-viserver -server $viServer

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
[void] $listBox.Items.Clear()


#Select from list of clusters
$clusterselected = ""
$vcclusters = get-datacenter -name $dcselected | get-cluster
$form.Text = 'Clusters:'
$label.Text = 'Please Select a Cluster:'

foreach ($vccluster in $vcclusters) {
	if ($($dcselected + ":" + $vccluster.name) -notin $clustersdone) {
		[void] $listBox.Items.Add($vccluster.name)
	}
}
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $clusterselected = $listBox.SelectedItem
}
[void] $listBox.Items.Clear()


if ($dcselected -and $clusterselected) {

	#Get VMs
	$sortedvms = get-datacenter -name $dcselected | get-cluster -name $clusterselected | get-vm | sort-object 

	#Set Network Adapters
	import-csv $csvfile | % {
		write-host ""
		Write-Host "Working on PortGroup: " $_.PortGroup
		foreach ($vm in $sortedvms) {
			foreach($netint in 1..9){
				$netname = 'Network adapter ' + $netint
				try {
					$mynetadapter = $vm | get-networkadapter -name $netname -ErrorAction Ignore
					if ($mynetadapter.networkname -eq $_.PortGroup) {
						write-host -nonewline "Change " $vm.name ": "
						set-networkadapter -NetworkAdapter $myNetAdapter -NetworkName $_.Segment -whatif -confirm:$false
					}
				}
				catch {
				}
			}
		}
	}


	#Remeber which clusters are done
	$dccluster = $dcselected + ":" + $clusterselected
	$form.Text = "$clusterselected"
	$label.Text = "Did cluster $clusterselected Complete?"
	$OKButton.Text = 'Yes'
	$CancelButton.Text = 'No'
	$listBox.Size = New-Object System.Drawing.Size(0,0)

	$result = $form.ShowDialog()
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		Add-Content $clusterfile $dccluster
	}
}
