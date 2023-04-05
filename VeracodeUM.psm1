# Valores de teste
$nome = "Joao"
$sobrenome = "Silva"
$email = "prevendas+testeUM" + (Get-Date -Format sshhmmddMM) + "@m3corp.com.br"
$cargo = "Desenvolvedor"
$time = "DEMOs"

# Teste funcoes
New-VeracodeUser $nome $sobrenome $email $cargo $time

# Lista de funções
function New-VeracodeUser {
    param (
        $nome,
        $sobrenome,
        $email,
        $cargo,
        $time
    )

    # Valida as roles com base no cargo
    if ($cargo -eq "Desenvolvedor") {
        $roles = "Creator,Submitter,eLearning"
    } if ($cargo -eq "Gestor") {
        $roles = ""
    }

    # Faz a criacao do usuario
    http --auth-type=veracode_hmac -o newuserinfo.xml "https://analysiscenter.veracode.com/api/3.0/createuser.do" "first_name==$nome" "last_name==$sobrenome" "email_address==$email" "teams==$time" "roles==$roles" "title==$cargo"
}

function Get-VeracodeTeamID {
    param (
        $teamName
    )
    $infoTeam = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/teams?all_for_org=true" | ConvertFrom-Json
    $infoTeam = $infoTeam._embedded.teams
    $teamID = ($infoTeam | Where-Object { $_.team_name -eq "$teamName" }).team_id
    return $teamID
}