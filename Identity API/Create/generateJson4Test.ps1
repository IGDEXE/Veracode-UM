# Valores de teste
$nome = "Joao"
$sobrenome = "Silva"
$email = "prevendas+testeUM" + (Get-Date -Format sshhmmddMM) + "@m3corp.com.br"
$cargo = "Desenvolvedor"
$time = "DEMOs"

# Lista de funcoes
function Get-VeracodeTeamID {
    param (
        $teamName
    )
    $infoTeam = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/teams?all_for_org=true&size=1000" | ConvertFrom-Json
    $infoTeam = $infoTeam._embedded.teams
    $teamID = ($infoTeam | Where-Object { $_.team_name -eq "$teamName" }).team_id
    return $teamID
}

try {
    # Recebe as informações do template
    $infoUser = Get-Content .\newUser.json | ConvertFrom-Json

    # Valida as roles pelo cargo
    if ($cargo -eq "Desenvolvedor") {
        $roles = (Get-Content .\Templates\exemploRoles.json | ConvertFrom-Json).rolesDev
    } if ($cargo -eq "gestor") {
        $roles = (Get-Content .\Templates\exemploRoles.json | ConvertFrom-Json).rolesManager
    }

    # Pega o ID do time
    $timeID = Get-VeracodeTeamID $time
    $timeTemplate = Get-Content .\Templates\exemploTimes.json
    $time = $timeTemplate.replace("#TIMEID#", "$timeID")
    $time = ($time | ConvertFrom-Json).teams

    # Altera as propriedades
    $infoUser.email_address = $email
    $infoUser.user_name = $email
    $infoUser.first_name = $nome
    $infoUser.last_name = $sobrenome
    $infoUser.title = $cargo
    $infoUser.roles = $roles
    $infoUser.teams = $time

    # Salva num novo JSON
    $novoJSON = "user" + (Get-Date -Format sshhmmddMM) + ".json"
    $infoUser | ConvertTo-Json -depth 100 | Out-File "$novoJSON"
    return $novoJSON
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Erro no Powershell:"
    Write-Host "$ErrorMessage"
}