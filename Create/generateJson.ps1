param (
        $nome,
        $sobrenome,
        $email,
        $cargo,
        $time
    )

try {
    # Recebe as informações do template
    $infoUser = Get-Content .\newUser.json | ConvertFrom-Json

    # Valida as roles pelo cargo
    if ($cargo -eq "Desenvolvedor") {
        $roles = (Get-Content .\exemploRoles.json | ConvertFrom-Json).rolesDev
    } if ($cargo -eq "gestor") {
        $roles = (Get-Content .\exemploRoles.json | ConvertFrom-Json).rolesManager
    }

    # Pega o ID do time
    $infoTimes = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/teams" | ConvertFrom-Json
    $infoTimes = $infoTimes._embedded.teams
    $timeID = ($infoTimes | Where-Object { $_.team_name -eq "$time" }).team_id

    # Altera as propriedades
    $infoUser.email_address = $email
    $infoUser.user_name = $email
    $infoUser.first_name = $nome
    $infoUser.last_name = $sobrenome
    $infoUser.title = $cargo
    $infoUser.roles = $roles
    #$infoUser.teams

    # Salva num novo JSON
    $novoJSON = "user" + (Get-Date -Format sshhmmddMM) + ".json"
    $infoUser | ConvertTo-Json -depth 100 | Out-File "$novoJSON"
    return $novoJSON
}
catch {
    <#Do this if a terminating exception happens#>
}