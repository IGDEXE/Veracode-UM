# Valores de teste
$nome = "Joao"
$sobrenome = "Silva"
$email = "prevendas+testeUM" + (Get-Date -Format sshhmmddMM) + "@m3corp.com.br"
$cargo = "Desenvolvedor"
$time = "DEMOs"

# Exemplo de como importar o modulo
$pastaModulos = Get-Location
Import-Module -Name "$pastaModulos\VeracodeUM.psm1" -Verbose

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
        $pastaTemplates = ".\Templates"
    )

    try {
        # Recebe as informações do template
        $infoUser = Get-Content $pastaTemplates\newUser.json | ConvertFrom-Json
    
        # Valida as roles pelo cargo
        $roles = Get-VeracodeRoles $cargo
    
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
        $caminhoJSON = "./TEMP/$novoJSON"
        $infoUser | ConvertTo-Json -depth 100 | Out-File "$caminhoJSON"
        return $caminhoJSON
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
        $caminhoJSON = ".\Templates\block.json"
    )

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
        Write-Error "$ErrorMessage"
    }
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
    } elseif (!$retornoAPI) {
        Write-Host "Ocorreu um erro:"
        Write-Error "A API não retornou nenhum dado"
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
    try {
        $infoUsers = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?size=1000" | ConvertFrom-Json
        $validador = Debug-VeracodeAPI $infoUsers
        if ($validador -eq "OK") {
            $infoUsers = $infoUsers._embedded.users
            $userID = ($infoUsers | Where-Object { $_.user_name -eq "$emailUsuario" }).user_id
            if ($userID) {
                return $userID
            } else {
                # Exibe a mensagem de erro
                Write-Error "Não foi encontrado ID para o usuario: $emailUsuario"
            }
            
        } else {
            # Exibe a mensagem de erro
            Write-Error "Algo não esperado ocorreu"
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
}

function New-VeracodeTeam {
    param (
        $teamName,
        $pastaTemplates = ".\Templates"
    )

    try {
        # Recebe as informações do template
        $timeTemplate = Get-Content $pastaTemplates\newTeam.json | ConvertFrom-Json
    
        # Altera as propriedades
        $timeTemplate.team_name = $teamName
    
        # Salva num novo JSON
        $novoJSON = "team" + (Get-Date -Format sshhmmddMM) + ".json"
        $caminhoJSON = "./TEMP/$novoJSON"
        $timeTemplate | ConvertTo-Json -depth 100 | Out-File "$caminhoJSON"
        
        # Cria o time 
        $retornoAPI = Get-Content $caminhoJSON | http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/teams"
        $retornoAPI = $retornoAPI | ConvertFrom-Json
        $validador = Debug-VeracodeAPI $retornoAPI

        # Valida se fez a criação
        if ($validador -eq "OK") {
            # Pega as infos do usuario
            $nomeTime = $retornoAPI.team_name
            $idTime = $retornoAPI.team_id
            # Exibe a mensagem de confirmação
            Write-Host "Time criado com sucesso:"
            Write-Host "$nomeTime"
            Write-Host "$idTime"
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

function Get-VeracodeRoles {
    param (
        $tipoFuncionario,
        $pastaTemplates = ".\Templates"
    )

    try {
        # Valida as roles pelo cargo
        switch ($tipoFuncionario) {
            Desenvolvedor { $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesDev; Break }
            QA { $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesQa; Break }
            SOC { $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesSoc; Break }
            DEVOPS { $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesSRE; Break }
            BLUETEAM { $roles = (Get-Content $pastaTemplates\exemploRoles.json | ConvertFrom-Json).rolesBlueTeam; Break }
            Default { Write-Error "Não foi encontrado nenhum perfil para $tipoFuncionario"}
        }

        # Retorna as roles
        return $roles
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Erro no Powershell:"
        Write-Error "$ErrorMessage"
    }
    
}

function Update-VeracodeUserRoles {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Email da conta conforme cadastrado na Veracode (Caso seja uma conta de API, informar o UserName dela)")]
        $emailUsuario,
        [parameter(position=1,Mandatory=$True,HelpMessage="Tipo de roles desejado (ex: QA, SOC, Desenvolvedor)")]
        $tipoFuncionario,
        $pastaTemplates = ".\Templates"
    )

    # Recebe o ID do usuario e as roles
    $idUsuario = Get-VeracodeUserID $emailUsuario
    $roles = Get-VeracodeRoles $tipoFuncionario

    # Atualiza as roles com base no modelo
    $infoUser = Get-Content "$pastaTemplates\extruturaRoles.json" | ConvertFrom-Json
    $infoUser.roles = $roles

    # Salva num novo JSON
    $novoJSON = "roles" + (Get-Date -Format sshhmmddMM) + ".json"
    $caminhoJSON = "./TEMP/$novoJSON"
    $infoUser | ConvertTo-Json -depth 100 | Out-File "$caminhoJSON"

    # Atualiza as roles
    $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUsuario + "?partial=true"
    $retornoAPI = Get-Content $caminhoJSON | http --auth-type=veracode_hmac PUT "$urlAPI" | ConvertFrom-Json
    $validador = Debug-VeracodeAPI $retornoAPI
    if ($validador -eq "OK") {
        $Usuario = $retornoAPI.user_name
        if ($Usuario) {
            Write-Host "Usuario $Usuario foi atualizado"
        } else {
            Write-Error "Não foi localizado nenhum ID para: $emailUsuario"
        }
        
    } else {
        Write-Error "Comportamento não esperado"
    }
    
}

# Teste funcoes
# Cria usuario
#$caminhoJSON = New-UserJson $nome $sobrenome $email $cargo $time
#New-VeracodeUser $caminhoJSON