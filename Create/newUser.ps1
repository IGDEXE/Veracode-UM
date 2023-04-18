param (
    $caminhoJSON
)

# Importa o modulo com as funcoes
$pastaModulos = Get-Location
$pastaAtual = Split-Path -Path (Get-Location) -Leaf
$pastaModulos = $pastaModulos.path.split("\$pastaAtual")
$pastaModulos = $pastaModulos[0]
Import-Module -Name "$pastaModulos\VeracodeUM.psm1"

try {
    # Faz a chamada da API
    $retornoAPI = Get-Content $caminhoJSON | http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users"
    $retornoAPI = $retornoAPI | ConvertFrom-Json
    $validador = Debug-VeracodeAPI $retornoAPI

    # Valida se fez a criação
    if ($validador -eq "OK") {
       # Pega as infos do usuario
       $nomeUsuario = $retornoAPI.first_name
       $sobrenomeUsuario = $retornoAPI.last_name
       $emailUsuario = $retornoAPI.email_address
       # Exibe a mensagem de confirmação
       Write-Host "Usuario criado com sucesso:"
       Write-Host "$nomeUsuario $sobrenomeUsuario"
       Write-Host "$emailUsuario"
    } else {
        # Exibe a mensagem de erro
        Write-Error "Algo não esperado ocorreu"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Erro no Powershell:"
    Write-Error "$ErrorMessage"
}
