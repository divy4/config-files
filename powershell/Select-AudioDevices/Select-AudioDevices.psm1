$DEVICE_FILE = "$PSScriptRoot\devices.json"

Function Select-AudioDevices {
  $devices = Load-AudioDevices
  #$devices.Ignored[0].InstanceId
  Save-AudioDevices $devices
}

Function Load-AudioDevices {
  if (Test-Path "$DEVICE_FILE") {
    $devices = Get-Content -Path $DEVICE_FILE | ConvertFrom-Json
  } else {
    $devices = @{
      "Output" = [System.Collections.ArrayList]::new()
      "Input" = [System.Collections.ArrayList]::new()
      "Ignored" = [System.Collections.ArrayList]::new()
    }
  }

  $ids = [System.Collections.Generic.HashSet[string]]@()
  foreach ($list in @($devices.Output, $devices.Input, $devices.Ignored)) {
    foreach ($item in $list) {
      $ids.Add($item.InstanceId)
    }
  }
  
  foreach ($item in Get-PnpDevice -Class AudioEndpoint) {
    if (!$ids.Contains($item.InstanceId)) {
      #$devices.Ignored += $item
      Write-Host $item
    }
  }
  #Write-Host $devices.Ignored[0]
  return $devices
}

Function Save-AudioDevices {
Param (
[Parameter()] [Object] $devices
)
  $devices | ConvertTo-Json | Out-File -FilePath $DEVICE_FILE
}

Export-ModuleMember -Function Select-AudioDevices
