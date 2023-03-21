Add-Type -AssemblyName System.Windows.Forms

#
# Written by ShadowZone
# Modified by Linuxgurugamer
#
# This script collects the current .log files and packages them into a .zip file to send off to the developers.
# It also asks the user which save file to package into a second .zip file.
# Optional: Users can add a workspace file if the error is specific to a certain vehicle they created.

# Copyright (C) 2023  Linuxgurugamer & ShadowZone

 
# Specify the path to the INI file
$iniPath = ".\KSP2_BugPackager.ini"

# Check if file doesn't exists
if (-not(Test-Path -Path "$iniPath" -PathType Leaf)) {
	$result = [System.Windows.Forms.MessageBox]::Show("The INI file: $iniPath  does not exist", "Error", "OK")
	exit
}
# Define a function to parse the INI file
function Get-IniContent ($path) {
    $ini = @{}
    switch -regex -file $path {
        "^\[(.+)\]$" {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "^\s*([^#].+?)\s*=\s*(.+)$" {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}
$global:config = Get-IniContent $iniPath

# Access the values in the INI file
$global:debug = $config["KSP2_BugPackager"]["debug"];
$global:allInOneFile= $config["KSP2_BugPackager"]["allInOneFile"];
$global:zipFilePath = $config["KSP2_BugPackager"]["zipFilePath"];
$global:pathToGameDirectory = $config["KSP2_BugPackager"]["pathToGameDirectory"];
$global:pathToCampaignDirectories="$env:APPDATA\..\LocalLow\Intercept Games\Kerbal Space Program 2\Saves\SinglePlayer"

Write-Host "1. setting selectedWorkspaceIndex = -1"
$global:selectedWorkspaceIndex  = -1;
$global:workspaceFilePath = "";
$global:saveFolderPath = "abc";


$form = New-Object System.Windows.Forms.Form
$form.Text = "KSP2 Debug Reporter"
$form.Width = 800
$form.Height = 800
$form.StartPosition = "CenterScreen"

#############################################

$bugTitlelabel = New-Object System.Windows.Forms.Label
$bugTitlelabel.Location = New-Object System.Drawing.Point(10, 10)
$bugTitlelabel.Size = New-Object System.Drawing.Size(280, 20)
$bugTitlelabel.Text = "Enter Bug Title:"
$form.Controls.Add($bugTitlelabel)

$bugTitleTextBox = New-Object System.Windows.Forms.TextBox
$bugTitleTextBox.Location = New-Object System.Drawing.Point(10, 30)
$bugTitleTextBox.Size = New-Object System.Drawing.Size(280, 80)
$form.Controls.Add($bugTitleTextBox)

$bugDescrlabel2 = New-Object System.Windows.Forms.Label
$bugDescrlabel2.Location = New-Object System.Drawing.Point(10, 60)
$bugDescrlabel2.Size = New-Object System.Drawing.Size(280, 20)
$bugDescrlabel2.Text = "Please enter the bug description:"
$form.Controls.Add($bugDescrlabel2)

$bugDescrTextbox = New-Object System.Windows.Forms.RichTextBox
$bugDescrTextbox.Location = New-Object System.Drawing.Point(10, 80)
$bugDescrTextbox.Size = New-Object System.Drawing.Size(280, 80)
$form.Controls.Add($bugDescrTextbox)

# $submitButton = New-Object System.Windows.Forms.Button
# $submitButton.Location = New-Object System.Drawing.Point(110, 260)
# $submitButton.Size = New-Object System.Drawing.Size(75, 23)
# $submitButton.Text = "Submit"
# $submitButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
# $form.AcceptButton = $submitButton
# $form.Controls.Add($submitButton)

#$result = $form.ShowDialog()

#if ($result -eq [System.Windows.Forms.DialogResult]::OK)
#{
#    Write-Host "You entered text for field 1:" $textbox1.Text
#    Write-Host "You entered text for field 2:" $textbox2.Text
#}


#############################################
# Add a label to the form
$campaignLabel = New-Object System.Windows.Forms.Label
$campaignLabel.Location = New-Object System.Drawing.Point(10, 170)
$campaignLabel.Text = "Select the campaign"
$campaignLabel.AutoSize = $true
$campaignLabel.Visible = $false
$form.Controls.Add($campaignLabel)


$campaignsaveListBox = New-Object System.Windows.Forms.ListBox
$campaignsaveListBox.Location = New-Object System.Drawing.Point(10, 190)
$campaignsaveListBox.Size = New-Object System.Drawing.Size(300, 120)
$campaignsaveListBox.Visible = $false

$directories = Get-ChildItem $pathToCampaignDirectories | Where-Object {$_.PSIsContainer}

$campaignsaveListBox.Items.AddRange($directories )
$form.Controls.Add($campaignsaveListBox)

$campaignButtonSelect = New-Object System.Windows.Forms.Button
$campaignButtonSelect.Location = New-Object System.Drawing.Point(325, 210)
$campaignButtonSelect.Size = New-Object System.Drawing.Size(125, 23)
$campaignButtonSelect.Text = "Select Campaign"
$campaignButtonSelect.Visible = $false
$form.Controls.Add($campaignButtonSelect)

# Add a label to the form
$saveLabel = New-Object System.Windows.Forms.Label
$saveLabel.Location = New-Object System.Drawing.Point(10, 300)
$saveLabel.Text = "Select the Save"
$saveLabel.AutoSize = $true
$saveLabel.Visible = $false
$form.Controls.Add($saveLabel)

$saveListBox = New-Object System.Windows.Forms.ListBox
$saveListBox.Location = New-Object System.Drawing.Point(10, 320)
$saveListBox.Size = New-Object System.Drawing.Size(150, 120)
$saveListBox.Visible = $false
$form.Controls.Add($saveListBox)
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Location = New-Object System.Drawing.Point(170, 360)
$saveButton.Size = New-Object System.Drawing.Size(75, 23)
$saveButton.Text = "Select Save"
$saveButton.Visible = $false
$form.Controls.Add($saveButton)



$checkBox = New-Object System.Windows.Forms.CheckBox
$checkBox.Location = New-Object System.Drawing.Point(20, 440)
$checkBox.Size = New-Object System.Drawing.Size(200, 20)
$checkBox.Text = "Include a workspace"
$checkBox.Visible = $false
$form.Controls.Add($checkBox)

###############
# Add a label to the form
$workspaceLabel = New-Object System.Windows.Forms.Label
$workspaceLabel.Location = New-Object System.Drawing.Point(10, 460)
$workspaceLabel.Text = "Select the workspace"
$workspaceLabel.AutoSize = $true
$workspaceLabel.Visible = $false
$form.Controls.Add($workspaceLabel)

$workspaceListBox = New-Object System.Windows.Forms.ListBox
$workspaceListBox.Location = New-Object System.Drawing.Point(10, 480)
$workspaceListBox.Size = New-Object System.Drawing.Size(300, 120)
$workspaceListBox.Visible = $false
$form.Controls.Add($workspaceListBox)
$workspaceButton = New-Object System.Windows.Forms.Button
$workspaceButton.Location = New-Object System.Drawing.Point(325, 500)
$workspaceButton.Size = New-Object System.Drawing.Size(150, 23)
$workspaceButton.Text = "Select Workspace"
$workspaceButton.Visible = $false
$form.Controls.Add($workspaceButton)

$checkBox.Add_CheckStateChanged({
	CheckWorkspaceVisibility
})

$finalizeButton = New-Object System.Windows.Forms.Button
$finalizeButton.Location = New-Object System.Drawing.Point(75, 650)
$finalizeButton.Size = New-Object System.Drawing.Size(150, 23)
$finalizeButton.Text = "Finalize Bug Report"
$finalizeButton.Visible = $false
$form.Controls.Add($finalizeButton)

##########################################

# Allow files to be dropped onto the form
$form.AllowDrop = $true

# Add a label to the form
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(475, 20)
$label.Text = "Drag and drop files onto this window."
$form.Controls.Add($label)

# Add a list box to the form to display dropped files
$global:optionalFilesListBox = New-Object System.Windows.Forms.ListBox
$optionalFilesListBox.Location = New-Object System.Drawing.Point(475, 50)
$optionalFilesListBox.Size = New-Object System.Drawing.Size(280, 300)
$form.Controls.Add($optionalFilesListBox)

# Add an event handler for the drag and drop event
$form.add_DragEnter({
    # Check if any files are being dragged onto the form
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})

$form.add_DragDrop({
    # Get the list of dropped files and display them in the list box
    $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach ($file in $files) {
        $optionalFilesListBox.Items.Add($file)
    }
})


#############################################

function CheckCampaignVisibility() {
	if ($bugTitleTextBox.Text.Length -gt 0 -And $bugDescrTextbox.Text.Length -gt 0 ) {
		$campaignLabel.Visible = $true
		$campaignsaveListBox.Visible = $true
		$campaignButtonSelect.Visible = $true
	} else {
		$campaignLabel.Visible = $false
		$campaignsaveListBox.Visible = $false
		$campaignButtonSelect.Visible = $false
	}
}

function CheckSaveVisibility() {
    $saveListBox.Visible = $true
    $saveLabel.Visible = $true
    $saveButton.Visible = $true
}

function CheckWorkspaceVisibility () {
    if ($checkBox.Checked) {
		$workspaceLabel.Visible = $true
		$workspaceListBox.Visible = $true
		$workspaceButton.Visible = $true
		if ($selectedWorkspaceIndex -eq -1) {
			$finalizeButton.Visible = $false
		} else {
			$finalizeButton.Visible = $true
		}
		
    }
    else {
		$workspaceLabel.Visible = $false
		$workspaceListBox.Visible = $false
		$workspaceButton.Visible = $false
		
		$finalizeButton.Visible = $true
    }
}



# Callbacks here

$bugTitleTextBox.add_TextChanged({
	CheckCampaignVisibility
})
$bugDescrTextbox.add_TextChanged({
	CheckCampaignVisibility
})

# Add Clicks here

$campaignButtonSelect.Add_Click({
    $directories = Get-ChildItem $pathToCampaignDirectories | Where-Object {$_.PSIsContainer}

    $global:saveFileIndex = $campaignsaveListBox.SelectedIndex 
    $global:saveFolderPath = $directories[$saveFileIndex].FullName
    # Get the list of save files in the folder, sorted by last modified date
    $global:saveFiles = Get-ChildItem $saveFolderPath -Filter "*.json" | Sort-Object LastWriteTime -Descending
    $saveListBox.Items.Clear()
    $saveListBox.Items.AddRange($saveFiles)

	CheckSaveVisibility

	$selectedWorkspaceIndex  = -1
	$checkBox.Visible = $false
	CheckWorkspaceVisibility
})

$saveButton.Add_Click({
	$checkBox.Visible = $true
	$workspacePath = Join-Path $saveFolderPath "Workspaces"
    $global:workspaceFiles = Get-ChildItem -Path $workspacePath -Filter *.json | Sort-Object -Property LastWriteTime -Descending
	$workspaceListBox.Items.AddRange($workspaceFiles)
Write-Host "3. setting selectedWorkspaceIndex = -1"
	$selectedWorkspaceIndex = -1
	$checkBox.Checked = $false
	$finalizeButton.Visible = $true
    #$form.Close()
})

$workspaceButton.Add_Click({
    $global:selectedWorkspaceIndex = $workspaceListBox.SelectedIndex 
Write-Host "4. setting selectedWorkspaceIndex = $selectedWorkspaceIndex"
    $global:workspaceFilePath = [System.IO.Path]::ChangeExtension($workspaceFiles[$workspaceIndex - 1].FullName, $null)
	$finalizeButton.Visible = $true

})

$finalizeButton.Add_Click({
    $form.Close()
})

###############

$form.ShowDialog() | Out-Null



$bugTitle = $bugTitleTextBox.Text
$bugDescr = $bugDescrTextbox.Text

$selectedCampaign = $campaignsaveListBox.SelectedItem
$selectedCampaignIndex = $campaignsaveListBox.SelectedIndex 

$selectedSave = $saveListBox.SelectedItem
$selectedSaveIndex = $saveListBox.SelectedIndex

if ($selectedSave) {
} else {
    exit
}

Write-Host "Bug title: $bugTitle"
Write-Host "Bug Descr: $bugDescr"
Write-Host "Selected Campaign: $selectedCampaign"
Write-Host "Save: $selectedSave"

#if ($selectedWorkspaceIndex -ge 0) {
	Write-Host "SelectedWorkspaceIndex: $selectedWorkspaceIndex"
#}

$files = @()
foreach ($file in $optionalFilesListBox.Items) {
    Write-Host $file
    $files += $file
}

##################
#exit
##################

$zipLogFiles = $bugTitle + "_logs"
$zipLogTmp = Join-Path $zipFilePath $zipLogFiles
$zipLogPath = $zipLogTmp + ".zip"

Write-Host "Checking for existing zip file"
if (Test-Path $zipLogPath) {
    Write-Host ""
    Write-Host "The file: $zipLogPath  exists, old file is being deleted"
    Write-Host ""
	if (Test-Path $zipLogPath) {
		Remove-Item $zipLogPath
	}
} else {
    $goodFile = 1
}

##############################
# Initializing zip file names
$zipSaveFiles = $zipLogFiles
$zipSaveTmp = $zipLogTmp
$zipSavePath = $zipLogPath

Write-Host "zipSaveFiles: $zipSaveFiles"
Write-Host "zipSaveTmp: $zipSaveTmp"
Write-Host "zipSavePath: $zipSavePath"
##############################


##############################
$bugDescrFilePath="BugDescription.txt"
Write-Host "Writing bug description to file: $bugDescrFilePath"

if (Test-Path $bugDescrFilePath) {
	Remove-Item -Force $bugDescrFilePath
}
Set-Content -Path $bugDescrFilePath -Value $bugDescr
##############################


##############################
# Set the paths to the files you want to collect
$file1Path="$env:APPDATA\..\LocalLow\Intercept Games\Kerbal Space Program 2\Player.log"
$file2Path = "$pathToGameDirectory\Ksp2.log"

Write-Host "Creating zip file: $zipLogPath"
Write-Host "Adding file1Path to zip file: $file1Path"
Write-Host "Adding file2Path to zip file: $file2Path"
Write-Host "Adding bugDescrFilePath to zip file: $bugDescrFilePath"

# Create the .zip file containing the logs
Compress-Archive -Path $file1Path, $file2Path, $bugDescrFilePath -DestinationPath $zipLogPath
Remove-Item -Path $bugDescrFilePath -Force
##############################

##############################
# Adding Save to file
# Generate variables to also package .meta and .jpg files and put them into an array
# Get the path of the selected save file without the .json extension
$saveFilePath = [System.IO.Path]::ChangeExtension($saveFiles[$saveFileIndex - 1].FullName, $null)

$saveFileJson = $saveFilePath + "json"
$saveFileMeta = $saveFilePath + "meta"
$saveFileJpg = $saveFilePath + "jpg"
$saveArray = @($saveFileJson, $saveFileMeta, $saveFileJpg)

Write-Host "saveFilePath:  $saveFilePath"
# Create .zip file with save files
Compress-Archive -Path $saveArray -Update -DestinationPath $zipLogPath
##############################


##############################
# Adding workspace to zip file
if ($selectedWorkspaceIndex -ge 0) {
	# Get full paths and also just the file name of the workspace files. Just file names are necessary for creating the entry in the .zip file later
	$workspaceJson = $workspaceFilePath + "json"
	$workspaceJsonName = Split-Path -Path $workspaceJson -Leaf
	$workspaceMeta = $workspaceFilePath + "meta"
	$workspaceMetaName = Split-Path -Path $workspaceMeta -Leaf
	$workspaceJpg = $workspaceFilePath + "jpg"
	$workspaceJpgName = Split-Path -Path $workspaceJpg -Leaf

	Write-Host "Adding $workspaceJsonName to zip file: $workspaceJson"
	Write-Host "Adding $workspaceMetaName to zip file: $workspaceMeta"
	Write-Host "Adding $workspaceJpgName to zip file: $workspaceJpg"
	

	$zip = [System.IO.Compression.ZipFile]::Open($zipSavePath, 'Update')

	# Create subfolder "Workspaces" inside .zip file
	$zip.CreateEntry("Workspaces/")

	# Add workspace files into subfolder inside .zip.file
	$compression = [System.IO.Compression.CompressionLevel]::Fastest
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$workspaceJson, "Workspaces\$workspaceJsonName",$compression)
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$workspaceMeta, "Workspaces\$workspaceMetaName",$compression)
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$workspaceJpg, "Workspaces\$workspaceJpgName",$compression)
	$zip.Dispose()
} else {
	Write-Host "No workspace selected"
}
##############################
