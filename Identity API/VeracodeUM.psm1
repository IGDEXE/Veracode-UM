# Valores de teste
$nome = "Joao"
$sobrenome = "Silva"
$email = "prevendas+testeUM" + (Get-Date -Format sshhmmddMM) + "@m3corp.com.br"
$cargo = "Desenvolvedor"
$time = "DEMOs"

# Lista de funções
function New-VeracodeUser {
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
}

function Get-VeracodeTeamID {
    param (
        $teamName
    )
    $infoTeam = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/teams?all_for_org=true&size=1000" | ConvertFrom-Json
    $infoTeam = $infoTeam._embedded.teams
    $teamID = ($infoTeam | Where-Object { $_.team_name -eq "$teamName" }).team_id
    return $teamID
}

function Generate-UserJson {
    param (
        $nome,
        $sobrenome,
        $email,
        $cargo,
        $time,
        $pastaTemplates = ".\Create\Templates"
    )

    try {
        # Recebe as informações do template
        $infoUser = Get-Content $pastaTemplates\newUser.json | ConvertFrom-Json
    
        # Valida as roles pelo cargo
        if ($cargo -eq "Desenvolvedor") {
            $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesDev
        } if ($cargo -eq "gestor") {
            $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesManager
        }
    
        # Pega o ID do time
        $timeID = Get-VeracodeTeamID $time
        $timeTemplate = Get-Content $pastaTemplates\exemploTimes.json
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
    
}

function Block-VeracodeUser {
    param (
        $emailUsuario,
        $caminhoJSON
    )
    
}

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

# Teste funcoes
# Cria usuario
$caminhoJSON = Generate-UserJson $nome $sobrenome $email $cargo $time
New-VeracodeUser $caminhoJSON