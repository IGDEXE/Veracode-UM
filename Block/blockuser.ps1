param (
    $emailUsuario,
    $caminhoJSON
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
    
    # Faz o bloqueio
    $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUsuario + "?partial=true"
    $retornoAPI = Get-Content $caminhoJSON | http --auth-type=veracode_hmac PUT "$urlAPI" | ConvertFrom-Json

    $validador = Debug-VeracodeAPI $retornoAPI
    if ($validador -eq "OK") {
        $Usuario = $retornoAPI.user_name
        if ($Usuario) {
            Write-Host "Usuario $Usuario foi bloqueado"
        } else {
            Write-Error "Não foi localizado nenhum ID para: $emailUsuario"
        }
        
    } else {
        Write-Error "Comportamento não esperado"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Erro no Powershell:"
    Write-Host "$ErrorMessage"
}