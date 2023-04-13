param (
    $caminhoJSON
)

try {
    # Faz a chamada da API
    $retornoAPI = Get-Content $caminhoJSON | http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users"

    # Valida se fez a criação
    $retornoAPI = $retornoAPI | ConvertFrom-Json
    $status = $retornoAPI.http_status
    if ($status -eq "Bad Request") {
       Write-Host "Ocorreu um erro:"
       Write-Host $retornoAPI.message
    } else {
        # Pega as infos do usuario
        $nomeUsuario = $retornoAPI.first_name
        $sobrenomeUsuario = $retornoAPI.last_name
        $emailUsuario = $retornoAPI.email_address
        # Exibe a mensagem de confirmação
        Write-Host "Usuario criado com sucesso:"
        Write-Host "$nomeUsuario $sobrenomeUsuario"
        Write-Host "$emailUsuario"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Erro no Powershell:"
    Write-Host "$ErrorMessage"
}
