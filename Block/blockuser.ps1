param (
    $emailUsuario,
    $caminhoJSON
)

# Recebe o ID com base no nome
$infoUsuario = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?user_name=$emailUsuario" | ConvertFrom-Json
$idUsuario = $infoUsuario._embedded.users.user_id

# Faz o bloqueio
$urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUsuario + "?partial=true"
Get-Content $caminhoJSON | http --auth-type=veracode_hmac PUT "$urlAPI"