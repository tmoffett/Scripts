
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
    }
    
    Process
    {
            Write-Verbose "Processing $ComputerName."
            
            #Does PSRemoting work?       
            [bool]$PSRemoting = Test-PSRemoting -Computername $ComputerName
            Write-Verbose "PSRemoting test result is $PSRemoting"
            
            #Get the beginning free space.
            $FreeSpaceBefore = Get-FreeSpace -ComputerName $ComputerName
            
            
            #Collect all of the various properties we want to hang on to.
            $properties = @{ComputerName = $ComputerName
                            FreeSpaceBefore = $FreeSpaceBefore}

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
  Try {
    $r = Test-WSMan -ComputerName $Computername -Credential $Credential -Authentication Default -ErrorAction Stop
    Write-Output $True 
  }
  Catch {
    Write-Verbose $_.Exception.Message
    Write-Output $False
 
  }
}
 
End {
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}