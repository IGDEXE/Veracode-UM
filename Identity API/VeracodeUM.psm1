# Valores de teste
$nome = "Joao"
$sobrenome = "Silva"
$email = "prevendas+testeUM" + (Get-Date -Format sshhmmddMM) + "@m3corp.com.br"
$cargo = "Desenvolvedor"
$time = "DEMOs"
$pastaModulos = Get-Location
Import-Module -Name "$pastaModulos\Identity API\VeracodeUM.psm1" -Verbose

# Lista de funções
function New-VeracodeUser {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Caminho do arquivo JSON com os dados para criar um novo usuario")]
        $caminhoJSON
    )

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
}

function Get-VeracodeTeamID {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Nome do time cadastrado na plataforma da Veracode")]
        $teamName
    )

    $infoTeam = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/teams?all_for_org=true&size=1000" | ConvertFrom-Json
    $validador = Debug-VeracodeAPI $infoTeam
    if ($validador -eq "OK") {
        $infoTeam = $infoTeam._embedded.teams
        $teamID = ($infoTeam | Where-Object { $_.team_name -eq "$teamName" }).team_id
        if ($teamID) {
            return $teamID
        } else {
            # Exibe a mensagem de erro
            Write-Error "Não foi encontrado ID para o Time: $teamName"
        }
        
    } else {
        # Exibe a mensagem de erro
        Write-Error "Algo não esperado ocorreu"
    }
}

function New-UserJson {
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
        Write-Error "$ErrorMessage"
    }
    
}

function Block-VeracodeUser {
    param (
        $emailUsuario,
        $caminhoJSON
    )
    
}

function Debug-VeracodeAPI {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Retorno da API que quer analisar")]
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
        [parameter(position=0,Mandatory=$True,HelpMessage="Email da conta conforme cadastrado na Veracode (Caso seja uma conta de API, informar o UserName dela)")]
        $emailUsuario
    )
    $retornoAPI = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?user_name=$emailUsuario" | ConvertFrom-Json
    $validador = Debug-VeracodeAPI $retornoAPI

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
#$caminhoJSON = New-UserJson $nome $sobrenome $email $cargo $time
#New-VeracodeUser $caminhoJSON