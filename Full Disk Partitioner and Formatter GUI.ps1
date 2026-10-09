# Clean-up

Remove-Variable -Name * -ErrorAction SilentlyContinue
CLS

$ErrorActionPreference= 'silentlycontinue'

# The GUI  System

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

# Collecting unused drive letters

$partitions = Get-Partition
$UsedLetters = $partitions.DriveLetter
$UsedLetters = $UsedLetters |  ? { $_ } | sort -uniq
$UsedLetters = @($UsedLetters)
$Letters = @('ABCDEFGHIJKLMNOPQRSTUVWXYZ' -split '')
$AvailableLetters = $Letters | Where-Object { $_ -notin $UsedLetters }
$AvailableLetters = $AvailableLetters |  ? { $_ } | sort -uniq

# Main part of said GUI

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Formatter GUI'
$form.Size = New-Object System.Drawing.Size(600,250)
$form.StartPosition = 'CenterScreen'

# Main text

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Location = New-Object System.Drawing.Point(20,20)
$Label1.Size = New-Object System.Drawing.Size(200,20)
$Label1.Text = "Formatter GUI"
$form.Controls.Add($Label1)
$Form.Icon = New-Object System.Drawing.Icon ".\Icon.ico"

# Select Drive

$Label2 = New-Object System.Windows.Forms.Label
$Label2.Location = New-Object System.Drawing.Point(20,60)
$Label2.Size = New-Object System.Drawing.Size(200,20)
$Label2.Text = "Select Drive:"
$form.Controls.Add($Label2)

$ComboBox1 = New-Object System.Windows.Forms.ComboBox
$ComboBox1.Size = New-Object System.Drawing.Size(300,20)


# List disks

$Disks = Get-Disk | Where-Object OperationalStatus -eq 'Online'
foreach ($Disk in $Disks) 
{
	$partitions = Get-Partition -DiskNumber $Disk.Number
	foreach ($partition in $partitions)
	{
		$Volume = (Get-Volume -DriveLetter "$($partition.DriveLetter)").FileSystemLabel
		$ComboBox1.Items.Add("$($Disk.Number) - $($Partition.PartitionNumber) - $($partition.DriveLetter):\ - $Volume - $($Disk.FriendlyName) ")
	}
}
$ComboBox1.Location  = New-Object System.Drawing.Point(250,60)
$form.Controls.Add($ComboBox1)

# FS select

$Label3 = New-Object System.Windows.Forms.Label
$Label3.Location = New-Object System.Drawing.Point(20,80)
$Label3.Size = New-Object System.Drawing.Size(200,20)
$Label3.Text = "Select FileSystem:"
$form.Controls.Add($Label3)

$ComboBox2 = New-Object System.Windows.Forms.ComboBox
$ComboBox2.Size = New-Object System.Drawing.Size(300,20)
$ComboBox2.Items.Add("exFAT")
$ComboBox2.Items.Add("FAT")
$ComboBox2.Items.Add("FAT32")
$ComboBox2.Items.Add("NTFS")
$ComboBox2.Items.Add("ReFS")
$ComboBox2.Items.Add("UDF")
$ComboBox2.Location  = New-Object System.Drawing.Point(250,80)
$form.Controls.Add($ComboBox2)

# FS style select

$Label4 = New-Object System.Windows.Forms.Label
$Label4.Location = New-Object System.Drawing.Point(20,100)
$Label4.Size = New-Object System.Drawing.Size(200,20)
$Label4.Text = "Select FileSystem-Style:"
$form.Controls.Add($Label4)

$ComboBox3 = New-Object System.Windows.Forms.ComboBox
$ComboBox3.Size = New-Object System.Drawing.Size(300,20)
$ComboBox3.Items.Add("GPT")
$ComboBox3.Items.Add("MBR")
$ComboBox3.Location  = New-Object System.Drawing.Point(250,100)
$form.Controls.Add($ComboBox3)

# Drive letter Select

$Label5 = New-Object System.Windows.Forms.Label
$Label5.Location = New-Object System.Drawing.Point(20,120)
$Label5.Size = New-Object System.Drawing.Size(200,20)
$Label5.Text = "Select Drive letter to set:"
$form.Controls.Add($Label5)

$ComboBox4 = New-Object System.Windows.Forms.ComboBox
$ComboBox4.Size = New-Object System.Drawing.Size(300,20)

foreach ($Letter in $AvailableLetters)
{
	$Letter = $Letter + ":\"
	$ComboBox4.Items.Add("$Letter")
}
$ComboBox4.Location  = New-Object System.Drawing.Point(250,120)
$form.Controls.Add($ComboBox4)

# Label

$Label6 = New-Object System.Windows.Forms.Label
$Label6.Location = New-Object System.Drawing.Point(20,140)
$Label6.Size = New-Object System.Drawing.Size(200,20)
$Label6.Text = "Volume Label:"
$form.Controls.Add($Label6)

$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(250,140)
$textBox1.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($textBox1)

# Quick format?

$checkbox1 = new-object System.Windows.Forms.checkbox
$checkbox1.Location = new-object System.Drawing.Point(430,20)
$checkbox1.Size = new-object System.Drawing.Size(200,30)
$checkbox1.Text = "Quick format"
$checkbox1.Checked = $False
$Form.Controls.Add($checkbox1)

# Process button
$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(450,165)
$Button.Size = New-Object System.Drawing.Size(100,25)
$Button.Text = "Process"
$form.Controls.Add($Button)

# Button press
	
$Button.Add_Click({
	$Button.Text = "Busy..."
	$Button.Enabled = $false
	$Selected = $Combobox1.Text
	$SelectedFS = $Combobox2.Text
	$SelectedStyle = $Combobox3.Text
	$SelectedLetter = $Combobox4.Text
	$Label = $textBox1.Text
	$SelectedDisk,$SelectedPartition,$SelectedDrive,$SelectedVolume,$SelectedName=$Selected.split("-")
	$SelectedDisk = $SelectedDisk.Trim()
	$SelectedPartition =$SelectedPartition.Trim()
	$SelectedDrive = $SelectedDrive.Trim()
	$SelectedName = $SelectedName.Trim()
	$SelectedVolume = $SelectedVolume.Trim()
	Clear-Disk -Number $SelectedDisk -RemoveData -Confirm:$false
	Set-Disk $SelectedDisk -PartitionStyle $SelectedStyle
	New-Partition -DiskNumber $SelectedDisk -UseMaximumSize | Format-Volume -FileSystem $SelectedFS -NewFileSystemLabel $Label
	if (-not [String]::IsNullOrEmpty($SelectedLetter))
	{
		$SelectedLetter = $SelectedLetter.Substring(0,$SelectedLetter.Length-2)
		Get-Partition -DiskNumber $SelectedDisk -PartitionNumber $SelectedPartition | Set-Partition -NewDriveLetter $SelectedLetter
	}
	else
	{
		$SelectedDrive = $SelectedDrive.Substring(0,$SelectedDrive.Length-2)
		Get-Partition -DiskNumber $SelectedDisk -PartitionNumber $SelectedPartition | Set-Partition -NewDriveLetter $SelectedDrive
	}	
	$Button.Text = "Process"
	$Button.Enabled = $true
})

# Closing the application

$form.Add_Closing({param($sender,$e)
    $result = [System.Windows.Forms.MessageBox]::Show(`
        "Are you sure you want to exit?", `
        "Close", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel)
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes)
    {
        $e.Cancel= $true
    }
})

$form.Add_Shown({$form.Activate()})
$form.ShowDialog() | Out-Null
$form.Dispose()

Remove-Variable -Name * -ErrorAction SilentlyContinue
exit
