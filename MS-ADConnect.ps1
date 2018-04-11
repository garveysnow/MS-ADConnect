function MS-ADConnect 
{
	<#

	.SYNOPSIS
	 Creates a remote session on a specific Active Directory Server then imports that sessions localy on the client machine
	.DESCRIPTION
	 Creates and connect to a LDAP Server
	.EXAMPLE
	 LDAP-CONNECT -domainController '[The Domain controller] -credentials [system.object]
	.PARAMETER domainController [Mandatory]
	 The name of the Active Directory server you would like to connect to
	.PARAMETER Credentials
	 The name of a file to write failed computer names to. Defaults to errors.txt.+

	#>


param( 
        [STRING[]][PARAMETER(Mandatory=$true)]$domainController,
        [object]$credentials
     )


     <# Remove any active PSsesion with the name adex_ad1 
     ----------------------------------------------------#>
     try{ 
            Remove-PSSession -Name adex_ad1 -ErrorAction SilentlyContinue 
        } 
        catch [system.exception] { 
                                    WRITE-SEGLINE -numlines 1 -notification -firstline 'Could not find active PS-Session with name "ADEX_AD1" Continuing';
                                 }

     <# populate user domain 
     -----------------------#>
     $CS = gwmi -class win32_computersystem; $username = $userdomain = $CS.Domain + '\';
     
     <# if no credentials are passed through then prompt 
     ---------------------------------------------------#>
     if ( $credentials -eq $null )
     { 
        $credentials = Get-Credential -UserName $userdomain -Message "Please enter your username/password, user account must have access to query Active Directory";
     }
     
     try
     {
       # Attempt to make a connection the Local Domain Controller 
       # --------------------------------------------------------
       write-segline -numlines 2 -firstline 'Attempting to create Remote LDAP Session to' -action -color yellow -secondline $domainController
       $ldap_session = New-PSSession -Name "adex_ad1" -computerName $domainController -Credential $credentials -Authentication Kerberos -ErrorAction Stop
       write-segline -numlines 2 -firstline 'Remote LDAP Session Successfull to' -response -color green -secondline $domainController

       #Import Module on the remote Domain controller through the PSSession > Active Directory
       write-segline -numlines 1 -firstline "Invoking Command - Import-Moddule ActiveDirectory on $domainController" -action -color yellow
       Invoke-Command -scriptblock { Import-Module ActiveDirectory } -session $ldap_session
       
       #After importing the module of the remote domain controller then import the session to the local instance of powershell/ISE
       write-segline -numlines 1 -firstline 'Importing Remote PSsession with module "Active Directory"' -response
       $activeImport = Import-PSSession -session $ldap_session -module ActiveDirectory 
       Write-segline -numlines 2 -firstline 'ACTIVE SESSION ON' -secondline $activeImport.Name -response
       Get-PSSession -Name 'adex_ad1'

     } 
     catch [System.Exception] {
                                write-segline -Error -numlines 1 -firstline $_.exception -color red
                              }     


}



####################################
## EMBEEDED WRITE-SEGLINE FUNCTION #
####################################
<####################################################
o---|-Name: Write-SegmentedLine
o---|-Auther: Garvey Snow
o---|-Version: 0.1b
o---|-Description: Short for write segmented line is a wrapper for the cmdlet write-host
             Makes it eaiser
o---|-Dependancies: none
#####################################################>
function WRITE-SEGLINE{
    # Set Parems
    param(
           [int][parameter(Mandatory=$true)][Alias('nl')]$numlines,
          #---------
           [string[]][parameter(Mandatory=$false)][Alias('c')]$color,
          #---------
           [string[]][parameter(Mandatory=$true)][Alias('fl')]$firstline,
          #---------
           [string[]][parameter(Mandatory=$false)][Alias('sl')]$secondline,
          #---------
           [string[]][parameter(Mandatory=$false)][Alias('tl')]$thirdline,
          #---------
           [string[]][parameter(Mandatory=$false)][Alias('fhl')]$fourthline,
          #---------
           [string[]][parameter(Mandatory=$false)][Alias('ffhl')]$fifthline,
          #---------
           [switch][parameter(Mandatory=$false)][Alias('a')]$Action,
          #---------
           [switch][parameter(Mandatory=$false)][Alias('r')]$response,
          #---------
           [switch][parameter(Mandatory=$false)][Alias('e')]$error,
          #---------
           [switch][parameter(Mandatory=$false)][Alias('n')]$Notification,
          #---------
           [switch][parameter(Mandatory=$false)][Alias('ri')]$requestinput,
          #---------
           [switch][parameter(Mandatory=$false)][Alias('nnl')]$nonewline
           )

    # set default color
    if($color.length -lt 1 ){ $color = "Gray" }

    # one line write
    if($numlines -eq 1)
    {
        # Line write supporting single value
        if($Notification)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor DarkRed 'Notification' -nonewline; 
            write-host -ForegroundColor DarkCyan '--------<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline;
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }
        }
        if($requestinput)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor DarkGreen 'Request User Input' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }
        }
        if($error){
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor red 'Error Exception' -nonewline; 
            write-host -ForegroundColor DarkCyan '------<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }       
        }
        if($Action){
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor Blue 'Action' -nonewline; 
            write-host -ForegroundColor DarkCyan '---------<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }       
        }
        if($response){
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor yellow 'response' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }       
        }
    }
   # two line write
   if($numlines -eq 2)
   {
        # Line write supporting single value
        if($Notification)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor DarkRed 'Notification' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            write-host -ForegroundColor DarkCyan ' ) ' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor Magenta $secondline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }
        }
        if($requestinput)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor DarkGreen 'Request User Input' -nonewline;
            write-host -ForegroundColor DarkCyan '--< ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            write-host -ForegroundColor DarkCyan ' ) ' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor Magenta $secondline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }
        }
        if($error)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor Red 'Error Exception' -nonewline; 
            write-host -ForegroundColor DarkCyan '--< ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            write-host -ForegroundColor DarkCyan ' ) ' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor Magenta $secondline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }
        }
        if($Action)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor Blue 'Action' -nonewline; 
            write-host -ForegroundColor DarkCyan '--< ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            write-host -ForegroundColor DarkCyan ' ) ' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor Magenta $secondline -NoNewline; 
            if($nonewline){ write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine; } 
            else { write-host -ForegroundColor DarkCyan ' ) ' }
        }
        if($response)
        {
            write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
            write-host -ForegroundColor DarkGreen 'response' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor $color $firstline -NoNewline; 
            write-host -ForegroundColor DarkCyan ' ) ' -nonewline; 
            write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline; 
            write-host -ForegroundColor Magenta $secondline -NoNewline; 
            if($nonewline) {write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;}
            else {write-host -ForegroundColor DarkCyan ' ) '}
        }
   }
    # Three line write
    if($numlines -eq 3)
    {
    
        if($Notification)
        {
          
              write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
              write-host -ForegroundColor DarkRed 'Notification' -nonewline;
              write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline;
                write-host -ForegroundColor $color $firstline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Magenta $secondline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $thirdline -NoNewline;
              if($nonewline){write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;}
              else{write-host -ForegroundColor DarkCyan ' ) ' }
    
        }
        if($Action)
        {
          
              write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
              write-host -ForegroundColor Blue 'Action ' -nonewline;
              write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline;
                write-host -ForegroundColor $color $firstline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Magenta $secondline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $thirdline -NoNewline;
              if($nonewline){
                 write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;
              }else{
                 write-host -ForegroundColor DarkCyan ' ) ' 
              }
    
        }

    }#End Function

    # Three line write
    if($numlines -eq 4)
    {
        <#-------
        Notification
        ---------#>
        if($Notification)
        {
          
              write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
              write-host -ForegroundColor DarkRed 'Notification' -nonewline;
              write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline;
                write-host -ForegroundColor $color $firstline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Magenta $secondline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $thirdline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $fourthline -NoNewline;
              if($nonewline){
                 write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;
              }else{
                 write-host -ForegroundColor DarkCyan ' ) ' 
              }
    
        }
        <#-------
        Action
        ---------#>
        if($Action)
        {
          
              write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
              write-host -ForegroundColor yellow 'Action' -nonewline;
              write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline;
                write-host -ForegroundColor $color $firstline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Magenta $secondline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $thirdline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $fourthline -NoNewline;
              if($nonewline){
                 write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;
              }else{
                 write-host -ForegroundColor DarkCyan ' ) ' 
              }
    
        }

    }#End Function
    if($numlines -eq 5)
    {
        <#-------
        Notification
        ---------#>
        if($Notification)
        {
          
              write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
              write-host -ForegroundColor DarkRed 'Notification' -nonewline;
              write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline;
                write-host -ForegroundColor $color $firstline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Magenta $secondline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $thirdline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $fourthline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $fifthline -NoNewline;
              if($nonewline){
                 write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;
              }else{
                 write-host -ForegroundColor DarkCyan ' ) ' 
              }
    
        }
        <#-------
        Action
        ---------#>
        if($Action)
        {
          
              write-host -ForegroundColor DarkCyan '---<(  ' -nonewline; 
              write-host -ForegroundColor Blue 'Action' -nonewline;
              write-host -ForegroundColor DarkCyan '---<(  ' -NoNewline;
                write-host -ForegroundColor $color $firstline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Magenta $secondline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $thirdline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $forthline -NoNewline;
              write-host -ForegroundColor DarkCyan ' ) ' -NoNewline;
              write-host -ForegroundColor DarkCyan ' ---<(  ' -NoNewline;
                write-host -ForegroundColor Green $fifthline -NoNewline;
              if($nonewline){
                 write-host -ForegroundColor DarkCyan ' ) ' -NoNewLine;
              }else{
                 write-host -ForegroundColor DarkCyan ' ) ' 
              }
    
        }

    }#End Function

   }
