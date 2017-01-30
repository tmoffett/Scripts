function Get-NamePrefixList {

<#
.Synopsis
   Generate an array of names with a specific prefix
.DESCRIPTION
   This cmdlet will generate an array of string objects that has a specific prefix. It supports input from the pipeline
   for the InputRangeArray parameter which controls how many names to create.
.EXAMPLE
   Get-NamePrefixList -InputRangeArray (1..10) -Prefix Server -Domain MyDomain.com

    Server01.Mydomain.com
    Server02.Mydomain.com
    Server03.Mydomain.com
    Server04.Mydomain.com
    Server05.Mydomain.com
    Server06.Mydomain.com
    Server07.Mydomain.com
    Server08.Mydomain.com
    Server09.Mydomain.com
    Server10.Mydomain.com
.EXAMPLE
   1..10 | Get-NamePrefixList -Prefix Server -Domain MyDomain.com

    Server01.Mydomain.com
    Server02.Mydomain.com
    Server03.Mydomain.com
    Server04.Mydomain.com
    Server05.Mydomain.com
    Server06.Mydomain.com
    Server07.Mydomain.com
    Server08.Mydomain.com
    Server09.Mydomain.com
    Server10.Mydomain.com
.OUTPUTS
   [string[]]
.NOTES
   Use at your own Risk!
.COMPONENT
   Swizz army script collection
.ROLE
   The cool admin owns this
.FUNCTIONALITY
   Automatic list generation
#>
[cmdletbinding()]
[OutputType([String[]])]
Param(
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true, 
        ValueFromRemainingArguments=$false, 
        Position=0)]
    [object[]]$InputRangeArray
    ,
    [string]$Prefix
    #,
    #[string]$Domain = "$env:USERDOMAIN"
)
    Begin
    {
        Write-Verbose -Message "Generating $($InputRangeArray.Count) names"
    }

    Process
    {
        Foreach ($number in $InputRangeArray)
        { 
            Write-Output "$Prefix$($number.ToString("00"))"
        }
    }

    End
    { 
    }
}

Function Connect-RDP {
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $computername
    )
    do
    {
        $connectiontest = (Test-NetConnection -ComputerName $computername -CommonTCPPort RDP).TcpTestSucceeded
    }
    until ($connectiontest -eq "True")
    mstsc /v:$computername
}

<#
.Synopsis
   Reclaim disk space by clearing out various temp folders on a local or remote machines.
.DESCRIPTION
   
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Clear-DiskSpace {

    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1
    )

    Begin
    {
    }
    Process
    {
    }
    End
    {
    }
}