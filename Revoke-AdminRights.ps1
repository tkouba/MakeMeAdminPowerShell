
<#PSScriptInfo

.VERSION 1.0

.GUID 92881876-4f92-4bc8-b3bb-308845c1fb7c

.AUTHOR Tomas Kouba, based on example from Jonas Walfort

.COMPANYNAME

.COPYRIGHT (c) Tomas Kouba. All rights reserved.

.TAGS admin-rights makemeadmin

.LICENSEURI https://raw.githubusercontent.com/tkouba/MakeMeAdminPowerShell/refs/heads/master/LICENSE.txt

.PROJECTURI https://github.com/tkouba/MakeMeAdminPowerShell

.ICONURI https://raw.githubusercontent.com/tkouba/MakeMeAdminPowerShell/refs/heads/master/SecurityLock.ico

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#
.SYNOPSIS
 Revoke temporary administrators right using Make Me Admin service.

.DESCRIPTION
 Uses Make Me Admin service to remove user account from Administrators.
 See Make Me Admin wiki https://github.com/pseymour/MakeMeAdmin/wiki.

.INPUTS
NONE

.OUTPUTS
NONE

.EXAMPLE
C:\PS> .\Revoke-AdminRights.ps1

Description
-----------
 Revoke administrators right using Make Me Admin service

.NOTES
Version : 1.0, 2025-02-25
Requires : PowerShell Desktop

.LINK
https://github.com/pseymour/MakeMeAdmin/wiki
https://github.com/tkouba/MakeMeAdminPowerShell

#>
[CmdletBinding()]
Param()
PROCESS {
    #disable debug confirmation messages
    if ($PSBoundParameters['Debug']) { $DebugPreference = "Continue" }
    try {
        $source = @"
        using System;
        using System.ServiceModel;
        namespace SinclairCC.MakeMeAdmin
        {
            public enum RemovalReason : int
            {
                Timeout,
                ServiceStopped,
                UserLogoff,
                UserRequest
            }
            [ServiceContract(Namespace = "http://apps.sinclair.edu/makemeadmin/2017/10/")]
            public interface IAdminGroup
            {
                [OperationContract]
                void AddUserToAdministratorsGroup();
                [OperationContract]
                void RemoveUserFromAdministratorsGroup(RemovalReason reason);
            }
        }
"@

        # Import the required .NET assemblies
        Add-Type -TypeDefinition $source -ReferencedAssemblies System.ServiceModel
        Add-Type -AssemblyName System.ServiceModel

        # Load the required .NET assemblies
        [System.Reflection.Assembly]::LoadWithPartialName("System.ServiceModel") | Out-Null

        # Create a NetNamedPipeBinding object
        $binding = New-Object System.ServiceModel.NetNamedPipeBinding

        # Define the endpoint address
        $endpointAddress = "net.pipe://localhost/MakeMeAdmin/Service"

        Write-Debug "Using endpoint address '$endpointAddress'"

        # Create a channel factory to communicate with the service
        $channelFactory = New-Object 'System.ServiceModel.ChannelFactory[SinclairCC.MakeMeAdmin.IAdminGroup]' -ArgumentList $binding, $endpointAddress

        # Create a channel using the channel factory
        $channel = $channelFactory.CreateChannel()

        # Call the RemoveUserFromAdministratorsGroup method on the channel
        $channel.RemoveUserFromAdministratorsGroup([SinclairCC.MakeMeAdmin.RemovalReason]::UserRequest)

        # Close the channel factory
        $channelFactory.Close()

        Write-Output 'You are no longer a member of the Administrators group.'
    }
    catch {
        #show error message (non terminating error so that the rest of the pipe input get processed)
        Write-Error $_
    }
}
