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
$global:saveFileIndex = -1;
$global:selectedSaveIndex = -1;

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



$global:checkBox = New-Object System.Windows.Forms.CheckBox
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

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(300, 680)
$closeButton.Size = New-Object System.Drawing.Size(150, 23)
$closeButton.Text = "Close"
#$closeButton.Visible = $false
$form.Controls.Add($closeButton)

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
# Define the URLs to display
$url1Name = "Private Division Customer Support"
$url1 = "https://support.privatedivision.com/hc/en-us/requests/new?ticket_form_id=360001675633"
$url2Name = "Dedicated Bug Reports on the KSP Subforum"
$url2 = "https://forum.kerbalspaceprogram.com/index.php?/forum/144-ksp2-bug-reports/"
function ShowURLButtons() {

	$global:insLabel1 = New-Object System.Windows.Forms.Label
	$insLabel1.Location = New-Object System.Drawing.Point(250, 625)
	$insLabel1.Text = "Select the page to send/post the bug report to"
	$insLabel1.AutoSize = $true
	$insLabel1.Visible = $false
	$form.Controls.Add($insLabel1)

	$global:insLabel2 = New-Object System.Windows.Forms.Label
	$insLabel2.Location = New-Object System.Drawing.Point(250, 640)
	$insLabel2.Text = "Upload the zip file from the opened window"
	$insLabel2.AutoSize = $true
	$insLabel2.Visible = $false
	$form.Controls.Add($insLabel2)



	# Create the first button for URL 1
	$global:url1Button = New-Object System.Windows.Forms.Button
	$url1Button.Text = $url1Name
	$url1Button.Location = New-Object System.Drawing.Point( 500,625)
	$url1Button.Size = New-Object System.Drawing.Size(250, 23)
	$url1Button.Visible = $false
	$url1Button.Add_Click({
	    Start-Process $url1
	})

	# Create the second button for URL 2
	$global:url2Button = New-Object System.Windows.Forms.Button
	$url2Button.Text = $url2Name
	$url2Button.Location = New-Object System.Drawing.Point(500, 675)
	$url2Button.Size = New-Object System.Drawing.Size(250, 23)
	$url2Button.Visible = $false
	$url2Button.Add_Click({
	    Start-Process $url2
	})

	# Add the buttons to the main form
	$form.Controls.Add($url1Button)
	$form.Controls.Add($url2Button)

}
ShowURLButtons

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
		CheckFinalizeVisibility		
    }
    else {
		$workspaceLabel.Visible = $false
		$workspaceListBox.Visible = $false
		$workspaceButton.Visible = $false
		
		CheckFinalizeVisibility
    }
}

function CheckFinalizeVisibility() {
Write-Host "CheckFinalizeVisibility"
Write-Host "selectedSaveIndex: $selectedSaveIndex"
Write-Host "checkBox.Checked: $checkBox.Checked"
Write-Host "selectedWorkspaceIndex: $selectedWorkspaceIndex"

	if ($selectedSaveIndex -eq -1 -or ($checkbox.Checked -and $selectedWorkspaceIndex -eq -1)) {
		$url1Button.Visible = $false
		$url2Button.Visible = $false
		$finalizeButton.Visible = $false
		$insLabel1.Visible = $false
		$insLabel2.Visible = $false
	} else {
		$finalizeButton.Visible = $true
		$url1Button.Visible = $true
		$url2Button.Visible = $true
		$insLabel1.Visible = $true
		$insLabel2.Visible = $true
	}
}

function PackageBugReport() {

	$bugTitle = $bugTitleTextBox.Text
	$bugDescr = $bugDescrTextbox.Text

	$selectedCampaign = $campaignsaveListBox.SelectedItem
	$selectedCampaignIndex = $campaignsaveListBox.SelectedIndex 

	$selectedSave = $saveListBox.SelectedItem
	$selectedSaveIndex = $saveListBox.SelectedIndex


	$zipLogFiles = $bugTitle + "_logs"
	$zipLogTmp = Join-Path $zipFilePath $zipLogFiles
	$global:zipSavePath = $zipLogTmp + ".zip"

	Write-Host "Checking for existing zip file"
	if (Test-Path $zipSavePath) {
	    Write-Host ""
	    Write-Host "The file: $zipSavePath  exists, old file is being deleted"
	    Write-Host ""
		if (Test-Path $zipSavePath) {
			Remove-Item $zipSavePath
		}
	} else {
	    $goodFile = 1
	}

	##############################
	# Initializing zip file names
	$zipSaveFiles = $zipLogFiles
	$zipSaveTmp = $zipLogTmp

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

	Write-Host "Creating zip file: $zipSavePath"
	Write-Host "Adding file1Path to zip file: $file1Path"
	Write-Host "Adding file2Path to zip file: $file2Path"
	Write-Host "Adding bugDescrFilePath to zip file: $bugDescrFilePath"

	# Create the .zip file containing the logs
	Compress-Archive -Path $file1Path, $file2Path, $bugDescrFilePath -DestinationPath $zipSavePath
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
	Compress-Archive -Path $saveArray -Update -DestinationPath $zipSavePath
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
	}
	##############################
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

	$global:selectedWorkspaceIndex  = -1
	$checkBox.Visible = $false
	CheckWorkspaceVisibility
})

$saveButton.Add_Click({
	$checkBox.Visible = $true
	$workspacePath = Join-Path $saveFolderPath "Workspaces"
	$global:selectedSaveIndex = $saveListBox.SelectedIndex

    $global:workspaceFiles = Get-ChildItem -Path $workspacePath -Filter *.json | Sort-Object -Property LastWriteTime -Descending
	if ($workspaceFiles -ne $null) {
		$workspaceListBox.Items.AddRange($workspaceFiles)
	}
Write-Host "3. setting selectedWorkspaceIndex = -1"
	$selectedWorkspaceIndex = -1
	#$checkBox.Checked = $false
	CheckFinalizevisibility
	

    #$form.Close()
})

$workspaceButton.Add_Click({
    $global:selectedWorkspaceIndex = $workspaceListBox.SelectedIndex 
	Write-Host "4. setting selectedWorkspaceIndex = $selectedWorkspaceIndex"
    $global:workspaceFilePath = [System.IO.Path]::ChangeExtension($workspaceFiles[$workspaceIndex - 1].FullName, $null)
	CheckFinalizevisibility

})

$finalizeButton.Add_Click({
	PackageBugReport
	$folder = Split-Path $zipSavePath -Parent
	Invoke-Item $folder
})

$closeButton.Add_Click({
	$form.Close()
})
###############

$form.ShowDialog() | Out-Null



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

