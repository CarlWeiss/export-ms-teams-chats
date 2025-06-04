<#

    .SYNOPSIS
        Searches Exported Microsoft Chat History

    .DESCRIPTION
        This script searches the exported chat history from the Get-MicrosoftTeamsChat.ps1 script

    .PARAMETER exportFolder
        Export location of where the HTML files will be saved. For example, "D:\ExportedHTML\"

    .PARAMETER outputDirectory
        The output directory where the search results will be saved. For example, "D:\SearchResults\"

    .PARAMETER regexPattern
        The regex patter to search for in the exported chat files.

    .EXAMPLE
        .\Search-ExportedChat.ps1 -exportFolder "D:\ExportedHTML" -outputDirectory -"D:\SearchResults -regexPattern ".*\.html$"'

    .NOTES
        Author: Carl Weiss
        Pre-requisites: An exported chat history from Get-MicrosoftTeamsChat.ps1

#>

[cmdletbinding()]
Param(
    [Parameter(Mandatory = $false, HelpMessage = "Export location of where the HTML files were saved from Get-MicrosoftTeamsChat.ps1")] [string] $exportFolder = "out",
    [Parameter(Mandatory = $false, HelpMessage = "The directory where the matching chats should be saved")] [string] $outputDirectory = "SerachResults",
    [Parameter(Mandatory = $false, HelpMessage = "Regular Expression used to find messages in the exported chats")] [string] $regexPattern = @())

    Copy-MatchingFiles $exportFolder $outputDirectory  $regexPattern