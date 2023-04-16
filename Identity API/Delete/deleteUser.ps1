param (
    $emailUsuario
)

# Importa o modulo com as funcoes
$pastaModulos = Get-Location
$pastaAtual = Split-Path -Path (Get-Location) -Leaf
$pastaModulos = $pastaModulos.path.split("\$pastaAtual")
$pastaModulos = $pastaModulos[0]
Import-Module -Name "$pastaModulos\VeracodeUM.psm1"

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