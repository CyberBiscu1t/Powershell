# This script is designed to reduce user error during password changes on Windows Devices
#
# Note: This script does not check provided passwords for special characters that are not supported by
# pspasswd.exe.  Special characters are (?): &()[]{}^=;!'+,`~
#
# Script will return to menu after the end of each function until quit
#
# Authros: CyberBiscu1t
#
#
# Needs:
#    1. Better error handling
#    2. Verification of secure PW handling
#    3. Improved Success logging

#Check if current session is elevated
#
# Changes to make working:
# Change [Search] to your user search term for workstations
#
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "### Warning: Script not running with administrator privileges. Please run from an elevated prompt or account."
    exit
}
do 
{
Write-host "`n===============Windows Password Changer==============="
Write-Host "`t What would you like to do?"
Write-Host "`t'I' to change a specific password"
Write-host "`t'W' to change an account password on all workstations"
Write-host "`t'S' to change an account password on all Servers"
Write-host "`t'Q' to quit"
Write-host "==========================================================="
$choice = Read-Host "`nEnter Choice: "
}
until (($choice -eq 'I') -or ($choice -eq 'W') -or ($choice -eq 'S') -or ($choice -eq 'Q'))
switch ($choice) {
    'I'
    {
        Write-Host "`nYou have chosen to Change a specific password`n"
        $hostpw = Read-Host -Prompt "Server/Workstation where password needs to be changed"
        If (Test-Connection $hostpw -Count 1 -Quiet)
            {
                Write-Host "$hostpw is online."
                $user = Read-Host -Prompt "User account to change"
                $pword = read-host "Enter New Password for $user" -AsSecureString
                $pword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword))
                .\pspasswd.exe \\$hostpw $user $pword -accepteula -nobanner
                $thedate = Get-Date
                $isuccess = "$user" + "'s" + " password has changed on $hostpw. " + "($thedate)"
                Out-File -FilePath "PWSuccessInfo.txt" -InputObject $isuccess -Append
                [runtime.interopservices.marshall]::ZeroFreeBSTR($BSTR)
            }
            Else
            {
                $thedate = Get-Date
                $output = "$hostpw is not available, password cannot changed " + $thedate
                Out-File -Filepath "OneTimePWChangeInfo.txt" -InputObject $output -Append
            }
        & '.\Password Script New_Draftv1.ps1'
    }
    'W'
    {
        Write-Host "`nYou have chosen to Change an account password for ALL workstations`n"
        Get-ADComputer -Filter 'Name -like "[Search]*"' | foreach { $_.name } | Out-File computer.txt
        $user = Read-Host -Prompt "User account to change"
        $pword = read-host "Enter New Password for $user" -AsSecureString
        $pword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword))
        $computers = Get-Content computer.txt
        foreach($computer in $computers)
        {
            If (Test-Connection $computer -Count 1 -Quiet)
            {
                Write-Host "$computer is online, changing PW..."
                .\pspasswd.exe \\$computer $user $pword -accepteula -nobanner
                $thedate = Get-Date
                $wsuccess = "$user" + "'s" + " password has changed on $computer. " + "($thedate)"
                Out-File -FilePath "PWSuccessInfo.txt" -InputObject $wsuccess -Append
            }
            Else
            {
                $thedate = Get-Date
                $output = "$computer is not available, password not changed " + $thedate
                Out-File -Filepath "PWChangeInfo.txt" -InputObject $output -Append
            }
        }
        [runtime.interopservices.marshall]::ZeroFreeBSTR($BSTR)
        $newdate = Get-Date
        $endout = "Password Script Complete on " + $newdate + " Review above logs for failures."
        Out-File -Filepath "PWChangeInfo.txt" -InputObject $endout -Append
        & '.\Password Script New_Draftv1.ps1'
    }
    'S'
    {
        Write-Host "`nYou have chosen to Change an account password for ALL servers (Excluding DCs)`n"
        $serverlist = (Get-ADComputer -Filter "OperatingSystem  -like 'Windows Server*'" | ? {$_.DistinguishedName -notmatch 'Domain Controllers'}).Name
        Out-File -FilePath "Servers.txt" -InputObject $serverlist
        $users = Read-Host -Prompt "User account to change"
        $pwords = read-host "Enter New Password for $user" -AsSecureString
        $pwords = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwords))
        $confirm = Read-Host "Have you confirmed the list fo servers in Servers.txt? (y/n)"
        if ($confirm -eq 'y') 
        {
        foreach($server in $serverlist)
        {
            If (Test-Connection $server -Count 1 -Quiet)
            {
                Write-Host "$server is online, changing PW..."
                .\pspasswd.exe \\$server $users $pwords -accepteula -nobanner
            }
            Else
            {
                $thedates = Get-Date
                $outputs = "$server is not available, password not changed " + $thedates
                Out-File -Filepath "PWChangeInfo.txt" -InputObject $output -Append
            }
        }
        $newdate = Get-Date
        $endout = "Password Script Complete on " + $newdate + " Review above logs for failures."
        write-host "Remember that the DC's do not change automatically, please ensure those PW's are changed."
        }
        else
        {
        write-host "Passwords not changed..."
        }
        [runtime.interopservices.marshall]::ZeroFreeBSTR($BSTR)
        & '.\Password Script New_Draftv1.ps1'
    }
    'Q'
    {
        Write-Host "`nYou have chosen to Quit, goodbye!`n"
        Clear-Variable -Name pw*
        pause 2
        return
    }
}