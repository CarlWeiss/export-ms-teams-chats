[cmdletbinding()]
Param([bool]$verbose)
$VerbosePreference = if ($verbose) { 'Continue' } else { 'SilentlyContinue' }
$ProgressPreference = "SilentlyContinue"

# $resourceScores = "Chat.Read User.Read offline_access"
# https://learn.microsoft.com/EN-US/azure/active-directory/develop/scopes-oidc#openid
# $openIdScopes = "offline_access openid"

$scopes = "Chat.Read User.ReadBasic.All offline_access"
$accessToken = $null
$refreshToken = $null
$expires = $null
$interval = $null


function Get-GraphMsalAuth($clientId, $tenantId) {
    # MSAL handlex token refresh and token expiration automatically

    <# 
    Note Scopes can be defined as a list of scopes or set to the default: https://graph.microsoft.com/.default
    #>    
    $scopes = 'https://graph.microsoft.com/.default'

    $MsalParams = @{
    ClientId = $clientId
    TenantId = $tenantId
    Scopes   = $scopes
    Silent = $true
    }
    Write-Verbose "Getting MSAL auth token for client ID: $clientId and tenant ID: $tenantId"
    # try Silent auth first 
    try {
        $MsalResponse = Get-MsalToken @MsalParams
        $accessToken  = $MsalResponse.AccessToken
        Write-Verbose "Access token obtained successfully."
    }
    catch {
            Write-Verbose "Silent auth failed, falling back to interactive auth."
          try {
            $MsalParams.Remove('Silent')
            $MsalResponse = Get-MsalToken @MsalParams
            $accessToken = $MsalResponse.AccessToken
            Write-Verbose "Access token obtained successfully after interactive auth."
    }
          catch {
            Write-Verbose "Failed to obtain access token after interactive auth."
            throw
          }
    }
    $script:refreshToken = $MsalResponse.RefreshToken
    return $accessToken
}

function Get-GraphDeviceToken($clientId, $tenantId){
    Write-Verbose "No access token, getting token."
        
    $codeBody = @{ 
        client_id = $clientId
        scope     = $scopes
    }

    $deviceCodeRequest = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode" <# -ContentType $contentType #> -Body $codeBody
    Write-Host $deviceCodeRequest.message

    $tokenBody = @{
        grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
        device_code = $deviceCodeRequest.device_code
        client_id   = $clientId
    }
    return $tokenBody
}

function Get-GraphAccessToken ($clientId, $tenantId) {

    if ($Global:useMsal) {
        Write-Verbose "Using delegated auth for client ID: $clientId and tenant ID: $tenantId"
        return Get-GraphMsalAuth -clientId $clientId -tenantId $tenantId
    }
    elseif ([string]::IsNullOrEmpty($refreshToken) -and -not $Global:useMsal) {
        Get-GraphDeviceToken -clientId $clientId -tenantId $tenantId
    }

    elseif ($expires -ge ((Get-Date) + 600)) {
        return $accessToken
    }
    else {
        Write-Verbose "Access token expired, getting new token."
        
        $tokenBody = @{
            grant_type    = "refresh_token"
            scope         = $scopes
            refresh_token = $refreshToken
            client_id     = $clientId       
        }
    }
      
  
    # Get OAuth Token
    while ([string]::IsNullOrEmpty($authRequest.access_token)) { 
        $authRequest = try {
            Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $tokenBody
        }
        catch {
            Write-Verbose ($_ | Out-String)
            Write-Verbose $_.ErrorDetails.Message
            $errorMessage = $_.ErrorDetails.Message | ConvertFrom-Json
  
            # If not waiting for auth, throw error
            if ($errorMessage.error -ne "authorization_pending") {
                throw
            }

            Start-Sleep $interval
        }
    }
    
    # $script:accessToken = ConvertTo-SecureString $authRequest.access_token -AsPlainText -Force
    # secure string doesn't seems necessary in this context, lmk if i'm wrong about this
    $script:accessToken = $authRequest.access_token
    $script:refreshToken = $authRequest.refresh_token
    $script:expires = (Get-Date).AddSeconds($authRequest.expires_in)

    $accessToken
}