param (
    $emailUsuario,
    $caminhoJSON
)

function Get-VeracodeUserID {
    param (
        $emailUsuario
    )
    $infoUsuario = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?user_name=$emailUsuario" | ConvertFrom-Json
    # Filtra a resposta
    $status = $retornoAPI.http_status
    $mensagem = $retornoAPI.message
    $codigoErro = $retornoAPI.http_code

    if ($status -eq "Bad Request") {
        Write-Host "Ocorreu um erro:"
        Write-Host $mensagem
        Write-Error $codigoErro
        exit
    } if ($status -eq "Unauthorized") {
        Write-Host "Erro de autenticação:"
        Write-Host $mensagem
        Write-Host "Favor entrar em contato com o suporte"
        Write-Error $codigoErro
        exit
    } else {
        $idUsuario = $infoUsuario._embedded.users.user_id
        return $idUsuario
    }
}

try {
    # Recebe o ID com base no nome
    $idUsuario = Get-VeracodeUserID $emailUsuario

    # Faz o bloqueio
    $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUsuario + "?partial=true"
    Get-Content $caminhoJSON | http --auth-type=veracode_hmac PUT "$urlAPI"
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Erro no Powershell:"
    Write-Host "$ErrorMessage"
}