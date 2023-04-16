param (
    $emailUsuario
)

function Check-VeracodeAPI {
    param (
        $retornoAPI
    )
    
    # Filtra a resposta
    $status = $retornoAPI.http_status
    $mensagem = $retornoAPI.message
    $codigoErro = $retornoAPI.http_code

    if ($status) {
        Write-Host "Ocorreu um erro:"
        Write-Host $mensagem
        Write-Error $codigoErro
        exit
    } elseif (!$retornoAPI) {
        Write-Host "Ocorreu um erro:"
        Write-Error "A API não retornou nenhum dado"
        exit
    } else {
        $validador = "OK"
        return $validador
    }
}

function Get-VeracodeUserID {
    param (
        $emailUsuario
    )
    $retornoAPI = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?user_name=$emailUsuario" | ConvertFrom-Json
    $validador = Check-VeracodeAPI $retornoAPI

    if ($validador -eq "OK") {
        $idUsuario = $retornoAPI._embedded.users.user_id
        if ($idUsuario) {
            return $idUsuario
        } else {
            Write-Error "Não foi localizado nenhum ID para: $emailUsuario"
            exit
        }
        
    } else {
        Write-Error "Comportamento não esperado"
        exit
    }
}

try {
    # Recebe o ID com base no nome
    $idUsuario = Get-VeracodeUserID $emailUsuario

    # Deleta o usuario
    http --auth-type=veracode_hmac DELETE "https://api.veracode.com/api/authn/v2/users/$idUsuario"
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Erro no Powershell:"
    Write-Host "$ErrorMessage"
}