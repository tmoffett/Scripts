
function Clear-DiskSpace
{
<#
.Synopsis
   Reclaim disk space by clearing out various temp folders on one or more computers.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$ComputerName
    )

    Begin
    {
        $obj = $null
        $array = @()
        $properties = $null
        $FreeSpaceBefore = $null
        $FreeSpaceAfter = $null
        $PSRemoting = $null
        $Session = $null
        $StateFlag = "StateFlag0023"
    }
    
    Process
    {
            Write-Verbose "Processing $ComputerName."
            
            #Does PSRemoting work?       
            [bool]$PSRemoting = Test-PSRemoting -Computername $ComputerName
            Write-Verbose "PSRemoting test result is $PSRemoting"

            $Session = New-PSSession -ComputerName $ComputerName
            
            #Get the beginning free space.
            $FreeSpaceBefore = Get-FreeSpace -ComputerName $ComputerName

            Configure-CleanMgr -Session $Session -StateFlag $StateFlag

            Run-CleanMgr -ComputerName $ComputerName -Session $Session

            Remove-PSSession -Session $Session

            $FreeSpaceAfter = Get-FreeSpace -ComputerName $ComputerName
                        
            #Collect all of the various properties we want to hang on to.
            $properties = @{ComputerName = $ComputerName
                            FreeSpaceBefore = $FreeSpaceBefore
                            FreeSpaceAfter = $FreeSpaceAfter}

            #Create a new object and add the $properties to it.
            $obj = New-Object -TypeName PSObject -Property $properties

            #Add the object to the array
            $array += $obj
    }
   
    End
    {
                
    }
}


function Get-FreeSpace {
<#
.Synopsis
   
.DESCRIPTION
   
.EXAMPLE
   Get-FreeSpace -Computer "server01"
.EXAMPLE
   Another example of how to use this cmdlet
#>

    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName
    )

    Begin
    {
        $RawFreespace = $null
        $FreeSpaceGB = $null
    }

    Process
    {
        $RawFreespace = (Get-WmiObject Win32_logicaldisk `
                            -ComputerName $ComputerName `
                            -ErrorAction Stop `
                            | Where-Object {$_.DeviceID -eq 'C:'}).freespace

        $FreeSpaceGB = [decimal]("{0:N2}" -f($RawFreespace/1gb))
    }

    End
    {
        Write-Verbose "Current Free Space on the OS Drive : $FreeSpaceGB GB"
        Write-Output $FreeSpaceGB
    }
}


Function Test-PSRemoting {
<#
.Synopsis
   Test to see if PSRemoting is functioning on the computer.
.DESCRIPTION
   Stolen from https://www.petri.com/test-network-connectivity-powershell-test-connection-cmdlet.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
#requires -version 3.0
[cmdletbinding()]
Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName,
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)
 
Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
      }
 
Process {
  Write-Verbose -Message "Testing $computername"
  Try 
      {
        $r = Test-WSMan -ComputerName $Computername -Credential $Credential -Authentication Default -ErrorAction Stop
        Write-Output $True 
      }
  Catch [System.InvalidOperationException] 
        {
            Write-Verbose "The computer $ComputerName cannot be found."
            Write-Output $False
        }
}
 
End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}


function Run-CleanMgr
{
<#
.Synopsis
   Run Cleanmgr.exe (Disk Cleanup) using default selections.
.DESCRIPTION
   Long description
.EXAMPLE
   Run-CleanMgr -Computer COMPUTERNAME -Session SESSIONNAME
.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName,
        $Session
    )

    Begin
    {
        $CleanMgr = $null
    }
    Process
    {
        Try {
            $CleanMgr = Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                    Write-Verbose "Starting cleanmgr.exe." -Verbose
                    Start-Process -FilePath Cleanmgr.exe -ArgumentList '/sagerun:0023' -Wait -ErrorAction Stop -ErrorVariable EV | Wait-Process
                    Write-Output $true
                }
             }

        Catch [System.Management.Automation.RemoteException] 
              {
                Write-Verbose "It appears that CleanMgr.exe (Disk Cleanup) is not installed on $ComputerName."
              }
    }
    End
    {
        Write-Verbose "The value of the CleanMgr variable is: $CleanMgr"
        Write-Verbose $Error[0].Exception.GetType().FullName
    }
}


function Configure-CleanMgr
{
<#
.Synopsis
   Configure CleanMgr.exe/Disk Cleanup
.DESCRIPTION
   Create StateFlag registry entries to enable the various portions of CleanMgr.exe.
.EXAMPLE
   Configure-CleanMgr -ComputerName COMPUTERNAME
.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Session,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $StateFlag
    )

    Begin
    {
        
    }
    Process
    {
        Write-Verbose "Starting Configure-CleanMgr"
        $Config = Invoke-Command -Session $Session -ArgumentList $StateFlag -ErrorAction Stop -ScriptBlock {
            param($StateFlag)
            
            Try
            {
                Write-Verbose "Clearing CleanMgr.exe automation settings." -Verbose
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*' -Name $StateFlag -ErrorAction SilentlyContinue | Remove-ItemProperty -Name $StateFlag -ErrorAction SilentlyContinue
            }

            Catch
            {
                Write-Warning "[CATCH] Errors found during attempt:`n$_"
            }        
            
            
            Try
            {

                Write-Verbose "Set a StateFlag for each available volume cache in order to enable each option in Cleanmgr." -Verbose
                $VolumeCache = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
                foreach ($v in $VolumeCache) 
                    { 
                        New-ItemProperty -Path $v.PSPath -Name $StateFlag -Value 2 -PropertyType DWord
                    }

                Write-Verbose "Ending Configure-CleanMgr"
            }

            Catch
            {
                Write-Warning "[CATCH] Errors found during attempt:`n$_"
            }
        }
    }
    End
    {
        Write-Verbose "Ending Configure-CleanMgr."
    }
}