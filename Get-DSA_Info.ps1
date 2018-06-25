Clear-Host

# Version 0.7 is functional for all modules.  Need cleaning up the duplicate output. 

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -Assembly System.Windows.Forms 


function CheckProduct{
	$Product = @{}
	$DS_key = 'HKLM:\SOFTWARE\TrendMicro\Deep Security Agent'
	$VP_key = 'HKLM:\SOFTWARE\TrendMicro\Vulnerability Protection Agent'
	
	If (Test-Path $VP_key){
		$Product.ProductName = "Vulnerability Protection Agent"
		$Product.InstallationFolder = (Get-ItemProperty -Path $VP_key -Name InstallationFolder).InstallationFolder
	}ElseIf (Test-Path $DS_key){
		$Product.ProductName = "Deep Security Agent"
		$Product.InstallationFolder = (Get-ItemProperty -Path $DS_key -Name InstallationFolder).InstallationFolder
	}Else{
		$Product.ProductName = "None"	
	}	
	Return $Product
}

function String2Array {
	Param(	[Parameter(Mandatory=$true)][String]$String)
	$stringItems = $String -split ','
	return $stringItems
}

function ArrayToHash {
    $hash = @{}
    $a | foreach { $hash[$_.name] = $_.state }
    return $hash
}

$Product = CheckProduct
If ($Product.ProductName -ne "None"){
	Push-Location $Product.InstallationFolder
}Else{
	Write-Host "Trend Micro Product was not found"
	Exit
}

$DSAStatus	=  Invoke-Expression -Command ".\dsa_query --cmd GetAgentStatus"

$i=0
$DSAStatus | Foreach { 		
	$AgentState1 = $DSAStatus[$i] | Select-String -Pattern "AgentStatus.agentState"
	If ($AgentState1 -ne $null) {
		$AgentStateTemp = $DSAStatus[$i]
		$a0 = $AgentStateTemp.indexof(":")
		$a0 = $a0 + 2
		$b0 = $AgentStateTemp.get_Length()
		$c0 = $b0 - $a0
		$AgentState = $AgentStateTemp.Substring($a0,$c0)
	}	
	$i++	
}

#Agent Service Status
$DSA_Service = get-service -ComputerName . -Name "Trend Micro Deep Security Agent"
$DSA_Service_Status = $DSA_Service.status

#Agent Configuration
$DSAConfigRaw		= Invoke-Expression -Command ".\sendCommand.cmd --get GetConfiguration"
$DSAConfigTemp	= $DSAConfigRaw  | select -skip 3		#Remove top three lines from output
$DSAConfig	= [xml]$DSAConfigTemp

$ManagerURL = $DSAConfig.SecurityConfiguration.AgentConfiguration.dsmUrl
$SecurityProfile = $DSAConfig.SecurityConfiguration.SecurityProfile.name   #Security Profile

#region GUI
$form = New-Object System.Windows.Forms.Form
$form.text = "Deep Security Agent Information"
$form.StartPosition = "CenterScreen" 
$form.Width = 650 
$form.Height = 650 

#region TABS
################ Tabs ########################
$tabcontrols = New-Object System.Windows.Forms.TabControl
$tabcontrols.Width	=	600
$tabcontrols.Height	=	600
$form.Controls.Add($tabcontrols)

$tabGeneralInfo = New-Object System.Windows.Forms.TabPage
$tabGeneralInfo.Text = "General Information"
$tabcontrols.Controls.Add($tabGeneralInfo)

$tabAM = New-Object System.Windows.Forms.TabPage
$tabAM.Text = "Anti-Malware"
$tabcontrols.Controls.Add($tabAM)

$tabIPS = New-Object System.Windows.Forms.TabPage
$tabIPS.Text = "Intrusion Prevention"
$tabcontrols.Controls.Add($tabIPS)

$tabFW = New-Object System.Windows.Forms.TabPage
$tabFW.Text = "Firewall"
$tabcontrols.Controls.Add($tabFW)

$tabIM = New-Object System.Windows.Forms.TabPage
$tabIM.Text = "Integrity Monitoring"
$tabcontrols.Controls.Add($tabIM)

$tabLI = New-Object System.Windows.Forms.TabPage
$tabLI.Text = "Log Inspection"
$tabcontrols.Controls.Add($tabLI)
#endregion TABS

#region General Tab
$lblProductName				= New-Object system.Windows.Forms.Label
$lblProductName.Text		= "Product Name:"
$lblProductName.Top			= 10
$lblProductName.Left		= 5
$lblProductName.Width		= 100
$lblProductName.Height		= 10
$lblProductName.Autosize	= $true

$txtProductName				= New-Object system.Windows.Forms.Label
$txtProductName.multiline	= $false
$txtProductName.top			= 10
$txtProductName.left		= 200
$txtProductName.width		= 100
$txtProductName.Autosize	= $true
$txtProductName.Text		= $Product.ProductName

$lblManagerURL				= New-Object system.Windows.Forms.Label
$lblManagerURL.Text			= "Manager URL:"
$lblManagerURL.Top			= 30
$lblManagerURL.Left			= 5
$lblManagerURL.Width		= 100
$lblManagerURL.Height		= 10
$lblManagerURL.Autosize		= $true

$txtManagerURL				= New-Object system.Windows.Forms.Label
$txtManagerURL.multiline	= $false
$txtManagerURL.top			= 30
$txtManagerURL.left			= 200
$txtManagerURL.width		= 100
$txtManagerURL.Autosize		= $true
$txtManagerURL.Text			= $ManagerURL

$lblAgentState				= New-Object system.Windows.Forms.Label
$lblAgentState.Text			= "Agent State:"
$lblAgentState.Top			= 50
$lblAgentState.Left			= 5
$lblAgentState.Width		= 100
$lblAgentState.Height		= 10
$lblAgentState.Autosize		= $true

$txtAgentState				= New-Object system.Windows.Forms.Label
$txtAgentState.multiline	= $false
$txtAgentState.top			= 50
$txtAgentState.left			= 200
$txtAgentState.width		= 100
$txtAgentState.Autosize		= $true
$txtAgentState.Text			= $AgentState

$lblAgentStatus				= New-Object system.Windows.Forms.Label
$lblAgentStatus.text		= "Agent Service Status:"
$lblAgentStatus.Top			= 70
$lblAgentStatus.Left		= 5
$lblAgentStatus.width		= 100
$lblAgentStatus.AutoSize	= $true

$txtAgentStatus				= New-Object system.Windows.Forms.Label
$txtAgentStatus.multiline	= $false
$txtAgentStatus.Top			= 70
$txtAgentStatus.Left		= 200
$txtAgentStatus.width		= 100
$txtAgentStatus.AutoSize	= $true
$txtAgentStatus.Text		= $DSA_Service_Status

$lblPolicyName				= New-Object system.Windows.Forms.Label
$lblPolicyName.text			= "Policy Name:"
$lblPolicyName.top			= 90
$lblPolicyName.left			= 5
$lblPolicyName.width		= 100
$lblPolicyName.Autosize		= $true

$txtPolicyName				= New-Object system.Windows.Forms.Label
$txtPolicyName.multiline	= $false
$txtPolicyName.top			= 90
$txtPolicyName.left			= 200
$txtPolicyName.width		= 100
$txtPolicyName.AutoSize		= $true
$txtPolicyName.Text			= $SecurityProfile

$lblModuleStatus			= New-Object system.Windows.Forms.Label
$lblModuleStatus.text		= "Enabled Modules:"
$lblModuleStatus.Top		= 110
$lblModuleStatus.Left		= 5
$lblModuleStatus.width		= 25
$lblModuleStatus.AutoSize	= $true

$txtModuleStatus			= New-Object system.Windows.Forms.ListBox
$txtModuleStatus.Top		= 110
$txtModuleStatus.Left		= 200
$txtModuleStatus.width		= 100
$txtModuleStatus.height		= 100

$DSAFeaturesRaw	= $DSAConfig.SecurityConfiguration.AgentConfiguration.Features.Feature
#$DSAFeatures = ArrayToHash ($DSAFeaturesRaw)   #Enabled Features
$DSAFeaturesRaw | Foreach { 
	If (($_.state) -eq "1") {
		[Void]$txtModuleStatus.Items.Add($_.Name)
	}
}

$tabGeneralInfo.Controls.AddRange(@($lblAgentState,$txtAgentState,$lblManagerURL,$txtManagerURL,$lblProductName,$txtProductName,$lblPolicyName,$txtPolicyName,$lblAgentStatus,$txtAgentStatus,$lblModuleStatus,$txtModuleStatus))
#endregion General Tab

#region IPS Tab
$lblIPS_Rules				= New-Object system.Windows.Forms.Label
$lblIPS_Rules.text			= "IPS Rules:"
$lblIPS_Rules.Top			= 10
$lblIPS_Rules.left			= 5
$lblIPS_Rules.width			= 100
$lblIPS_Rules.AutoSize		= $true
$txtIPS_Rules				= New-Object system.Windows.Forms.ListView
$txtIPS_Rules.view			= "Detail"
$txtIPS_Rules.Top			= 10
$txtIPS_Rules.Left			= 100
$txtIPS_Rules.width			= 480
$txtIPS_Rules.height		= 550
$txtIPS_Rules.GridLines		= 1
$txtIPS_Rules.Scrollable	= 1

$txtIPS_Rules.Columns.Add('Rule ID', 50)
$txtIPS_Rules.Columns.Add('Rule Name', 500)

$IPSRules = $DSAConfig.SecurityConfiguration.PayloadFilter2s.PayloadFilter2
$IPSRules = $IPSRules | Sort identifier
$IPSRules | Foreach {  
	$Rule_Item = New-Object System.Windows.Forms.ListViewItem($_.identifier)
	$Rule_Item.SubItems.Add($_.name)
	[Void]$txtIPS_Rules.Items.Add($Rule_Item)
}

$tabIPS.Controls.AddRange(@($lblIPS_Rules,$txtIPS_Rules))
#endregion IPS Tab

#region FW Tab
$lblFW_Rules				= New-Object system.Windows.Forms.Label
$lblFW_Rules.text			= "FW Rules:"
$lblFW_Rules.Top			= 10
$lblFW_Rules.Left			= 5
$lblFW_Rules.width			= 25
$lblFW_Rules.AutoSize		= $true
$txtFW_Rules				= New-Object system.Windows.Forms.ListView
$txtFW_Rules.view			= "Detail"
$txtFW_Rules.Top			= 10
$txtFW_Rules.Left			= 100
$txtFW_Rules.width			= 480
$txtFW_Rules.height			= 550
$txtFW_Rules.GridLines		= 1
$txtFW_Rules.Scrollable		= 1

$txtFW_Rules.Columns.Add('Name', 300)
$txtFW_Rules.Columns.Add('Action', 100)
$txtFW_Rules.Columns.Add('Direction', 100)

$FirewallFilters = $DSAConfig.SecurityConfiguration.PacketFilters.PacketFilter
If ($FirewallFilters.count -gt 0){
	$FirewallFilters = $FirewallFilters | Sort filterAction
	$FirewallFilters | Foreach {
		$Rule_Item = New-Object System.Windows.Forms.ListViewItem($_.name)
	    If (($_.packetDirection) -eq 1){
	        $FWDirection = "Incoming"
	    }else{
	        $FWDirection = "Outgoing"    
	    }
	    switch ($_.filterAction)
	    {
	        0 {$FWAction = "Log Only"}
	        1 {$FWAction = "Allow"}
	        2 {$FWAction = "Deny"}
	        3 {$FWAction = "Force Allow"}
	        4 {$FWAction = "Bypass"}        
	        Default {$FWAction = "Unkbown Action"}
	    }
		$Rule_Item.SubItems.Add($FWAction)
		$Rule_Item.SubItems.Add($FWDirection)		
	    [Void]$txtFW_Rules.Items.Add($Rule_Item)
	}
}

$tabFW.Controls.AddRange(@($lblFW_Rules,$txtFW_Rules))

#endregion FW Tab

#region IM Tab
$lblIM_Rules				= New-Object system.Windows.Forms.Label
$lblIM_Rules.text			= "IM Rules:"
$lblIM_Rules.Top			= 10
$lblIM_Rules.Left			= 5
$lblIM_Rules.width			= 25
$lblIM_Rules.AutoSize		= $true
$txtIM_Rules				= New-Object system.Windows.Forms.ListView
$txtIM_Rules.View			= "Detail"
$txtIM_Rules.Top			= 10
$txtIM_Rules.Left			= 100
$txtIM_Rules.width			= 480
$txtIM_Rules.height			= 550
$txtIM_Rules.GridLines		= 1
$txtIM_Rules.Scrollable		= 1

$txtIM_Rules.Columns.Add('Rule ID', 50)
$txtIM_Rules.Columns.Add('Rule Name', 500)

#Integrity Monitoring Rules
$IMRules = $DSAConfig.SecurityConfiguration.IntegrityRules.IntegrityRule
if ($IMRules.count -ne 0){
	$IMRules = $IMRules | Sort identifier
	$IMRules | Foreach {  
		$Rule_Item = New-Object System.Windows.Forms.ListViewItem($_.identifier)
		$Rule_Item.SubItems.Add($_.name)
		[Void]$txtIM_Rules.Items.Add($Rule_Item)
	}
}

$tabIM.Controls.AddRange(@($lblIM_Rules,$txtIM_Rules))
#endregion IM Tab

#region LI Tab
$lblLI_Rules				= New-Object system.Windows.Forms.Label
$lblLI_Rules.text			= "LI Rules:"
$lblLI_Rules.Top			= 10
$lblLI_Rules.Left			= 5
$lblLI_Rules.width			= 25
$lblLI_Rules.AutoSize		= $true
$txtLI_Rules				= New-Object system.Windows.Forms.ListView
$txtLI_Rules.View			= "Detail"
$txtLI_Rules.Top			= 10
$txtLI_Rules.Left			= 100
$txtLI_Rules.width			= 480
$txtLI_Rules.height			= 550
$txtLI_Rules.GridLines		= 1
$txtLI_Rules.Scrollable		= 1

$txtLI_Rules.Columns.Add('Rule ID', 50)
$txtLI_Rules.Columns.Add('Rule Name', 500)

#Integrity Monitoring Rules
$LIRules = $DSAConfig.SecurityConfiguration.LogInspectionRules.ChildNodes
if ($LIRules.count -ne 0){
	$LIRules = $LIRules | Sort identifier
	$LIRules | Foreach {  
		$Rule_Item = New-Object System.Windows.Forms.ListViewItem($_.identifier)
		$Rule_Item.SubItems.Add($_.name)
		[Void]$txtLI_Rules.Items.Add($Rule_Item)
	}
}

$tabLI.Controls.AddRange(@($lblLI_Rules,$txtLI_Rules))
#endregion LI Tab

#region AM Tab
$AntiMalwareSettings = $DSAConfig.SecurityConfiguration.AntiMalwares
$WebReputationSetting = $DSAConfig.SecurityConfiguration.WebReputationConfiguration
$RealTimeInfo = $AntiMalwareSettings.AntiMalware[0]
$Exclusion_Directory = $DSAConfig.SecurityConfiguration.ScanDirectoryLists.ScanDirectoryList

$RealTimeScanConfigurationName = $RealTimeInfo.Name
$Exclusion_Directory = $DSAConfig.SecurityConfiguration.ScanDirectoryLists.ScanDirectoryList
$Exclusion_File = $DSAConfig.SecurityConfiguration.ScanFileLists.ScanFileList
$Exclusion_Extension = $DSAConfig.SecurityConfiguration.ScanFileExtLists.ScanFileExtList

$Exclusion_Directory_Items = $Exclusion_Directory.Items
$Exclusion_File_Items = $Exclusion_File.Items
$Exclusion_Extension_Items = $Exclusion_Extension.Items

$Exclusion_Directory_List	= String2Array -String $Exclusion_Directory_Items
$Exclusion_File_List		= String2Array -String $Exclusion_File_Items
$Exclusion_Extension_List	= String2Array -String $Exclusion_Extension_Items

$lblScanConfigurationName			= New-Object system.Windows.Forms.Label
$lblScanConfigurationName.Text		= "Scan Configuration Name:"
$lblScanConfigurationName.Top		= 10
$lblScanConfigurationName.Left		= 5
$lblScanConfigurationName.Width		= 100
$lblScanConfigurationName.Height	= 10
$lblScanConfigurationName.Autosize	= $true

$txtScanConfigurationName			= New-Object system.Windows.Forms.Label
$txtScanConfigurationName.multiline	= $false
$txtScanConfigurationName.top		= 10
$txtScanConfigurationName.left		= 200
$txtScanConfigurationName.width		= 100
$txtScanConfigurationName.Autosize	= $true
$txtScanConfigurationName.Text		= $RealTimeScanConfigurationName

$lblDirExclusion				= New-Object system.Windows.Forms.Label
$lblDirExclusion.text			= "Realtime Directory Exclusions:"
$lblDirExclusion.Top			= 30
$lblDirExclusion.Left			= 5
$lblDirExclusion.width			= 25
$lblDirExclusion.AutoSize		= $true
$txtDirExclusion				= New-Object system.Windows.Forms.ListBox
$txtDirExclusion.Text			= "Realtime Directory Exclusions"
$txtDirExclusion.Top			= 30
$txtDirExclusion.Left			= 200
$txtDirExclusion.width			= 350
$txtDirExclusion.height			= 100
$txtDirExclusion.Scrollable		= 1
$Exclusion_Directory_List | Foreach {  
	$Exclusion_Item = New-Object System.Windows.Forms.ListViewItem([System.String[]]$_)
	[Void]$txtDirExclusion.Items.AddRange($Exclusion_Item.Text)
}

$lblFileExclusion				= New-Object system.Windows.Forms.Label
$lblFileExclusion.text			= "Realtime File Exclusions:"
$lblFileExclusion.Top			= 140
$lblFileExclusion.Left			= 5
$lblFileExclusion.width			= 25
$lblFileExclusion.AutoSize		= $true
$txtFileExclusion				= New-Object system.Windows.Forms.ListBox
$txtFileExclusion.text			= "Realtime File Exclusions"
$txtFileExclusion.Top			= 140
$txtFileExclusion.Left			= 200
$txtFileExclusion.width			= 250
$txtFileExclusion.height		= 100
$Exclusion_File_List | Foreach {  
	$Exclusion_Item = New-Object System.Windows.Forms.ListViewItem([System.String[]]$_)
	[Void]$txtFileExclusion.Items.Add($Exclusion_Item.Text)
}

$lblExtExclusion				= New-Object system.Windows.Forms.Label
$lblExtExclusion.text			= "Realtime Extension Exclusions:"
$lblExtExclusion.Top			= 250
$lblExtExclusion.Left			= 5
$lblExtExclusion.width			= 25
$lblExtExclusion.AutoSize		= $true
$txtExtExclusion				= New-Object system.Windows.Forms.ListBox
$txtExtExclusion.text			= "Realtime Extension Exclusions"
$txtExtExclusion.Top			= 250
$txtExtExclusion.Left			= 200
$txtExtExclusion.width			= 250
$txtExtExclusion.height			= 100
$Exclusion_Extension_List | Foreach {  
	$Exclusion_Item = New-Object System.Windows.Forms.ListViewItem([System.String[]]$_)
	[Void]$txtExtExclusion.Items.Add($Exclusion_Item.Text)
}

$tabAM.Controls.AddRange(@($lblScanConfigurationName,$txtScanConfigurationName,$lblDirExclusion,$txtDirExclusion,$lblFileExclusion,$txtFileExclusion,$lblExtExclusion,$txtExtExclusion))
#endregion AM Tab

[void]$Form.ShowDialog()

#endregion GUI 







