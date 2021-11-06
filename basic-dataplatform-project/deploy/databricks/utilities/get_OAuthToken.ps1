function Get-OAuthToken {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $tenantId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientSecret,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $scope = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" # AzureDatabricks Resource ID
  )

  $headers = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
  }

  $body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "$scope/.default"
  }

  $url = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
  $response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $body

  return $response.access_token
}

function Get-OAuthTokenUsingCertificate {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $tenantId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    $certificate,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $scope = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" # AzureDatabricks Resource ID
  )
  
  # Create base64 hash of certificate
  $certBase64Hash = [System.Convert]::ToBase64String($certificate.GetCertHash())
  
  # Create JWT timestamp for expiration
  $epochStartTime = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
  $expTimeSpan = (New-TimeSpan -Start $epochStartTime -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
  $exp = [System.Math]::Round($expTimeSpan, 0)
  
  # Create JWT validity start timestamp
  $nbfTimeSpan = (New-TimeSpan -Start $epochStartTime -End ((Get-Date).ToUniversalTime())).TotalSeconds
  $nbf = [System.Math]::Round($nbfTimeSpan, 0)
  
  # Create JWT header
  $jwtHeader = @{
    alg = "RS256"
    typ = "JWT"
    # Use the certBase64Hash and replace/strip to match web encoding of base64
    x5t = $certBase64Hash -replace '\+','-' -replace '/','_' -replace '='
  }
  
  # Create JWT payload
  $jwtPayload = @{
    # What endpoint is allowed to use this JWT
    aud = "https://login.microsoftonline.com/" + $tenantId + "/oauth2/token"

    # Expiration timestamp
    exp = $exp
  
    # Issuer = your application
    iss = $clientId
  
    # JWT ID: random guid
    jti = [Guid]::NewGuid()
  
    # Not to be used before
    nbf = $nbf
  
    # JWT Subject
    sub = $clientId
  }
  
  # Convert header and payload to base64
  $jwtHeaderAsBytes = [System.Text.Encoding]::UTF8.GetBytes(($jwtHeader | ConvertTo-Json))
  $encodedHeader = [System.Convert]::ToBase64String($jwtHeaderAsBytes)
  
  $jwtPayloadAsBytes =  [System.Text.Encoding]::UTF8.GetBytes(($jwtPayload | ConvertTo-Json))
  $encodedPayload = [System.Convert]::ToBase64String($jwtPayloadAsBytes)
  
  # Join header and payload with "." to create a valid (unsigned) JWT
  $jwt = $encodedHeader + "." + $encodedPayload
  
  # Get the private key object of your certificate
  $privateKey = $certificate.PrivateKey
  
  # Define RSA signature and hashing algorithm
  $rsaPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
  $hashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256
  
  # Create a signature of the JWT
  $signature = [Convert]::ToBase64String($privateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($jwt), $hashAlgorithm, $rsaPadding)) -replace '\+','-' -replace '/','_' -replace '='
  
  # Join the signature to the JWT with "."
  $jwt = $jwt + "." + $signature

  # Create a hash with body parameters
  $body = @{
    client_id = $clientId
    client_assertion = $jwt
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    scope = "$scope/.default"
    grant_type = "client_credentials"
  }

  $url = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

  # Use the self-generated JWT as Authorization
  $header = @{
    Authorization = "Bearer $jwt"
  }

  # Finally execute the request
  $response = Invoke-RestMethod $url -Method 'POST' -Headers $header -ContentType 'application/x-www-form-urlencoded' -Body $body

  return $response.access_token
}
