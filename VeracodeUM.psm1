# Lista de funções
function New-VeracodeUser {
    <#
    .SYNOPSIS
        Função para criar novos usuarios Veracode

    .DESCRIPTION
        Com base num JSON de parametrização, essa função simplifica o processo de criação de um novo usuario na plataforma da Veracode

    .PARAMETER caminhoJSON
        Caminho do arquivo JSON configurado conforme a documentação da Veracode. Recomendo usar a função New-UserJson para cria-lo.

    .EXAMPLE
        New-VeracodeUser "D:/TEMP/user.json"

    .INPUTS
        Caminho de um arquivo

    .OUTPUTS
        Mensagem de confirmação ou de erro

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
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
    <#
    .SYNOPSIS
        Função para obter o ID de um time Veracode

    .DESCRIPTION
        Com base num nome, busca o ID de um time na plataforma da Veracode

    .PARAMETER teamName
        Nome do time que quer localizar o ID

    .EXAMPLE
        Get-VeracodeTeamID "DEMOs"

    .INPUTS
        String

    .OUTPUTS
        ID do time

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Nome do time cadastrado na plataforma da Veracode")]
        $teamName
    )

    try {
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
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Erro no Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function New-UserJson {
    <#
    .SYNOPSIS
        Função para gerar um JSON para criação de um novo usuario

    .DESCRIPTION
        Gera um JSON com os dados necessarios para criar um novo usuario na Veracode

    .PARAMETER nome
        Nome do usuario

    .PARAMETER sobrenome
        Sobrenome do usuario

    .PARAMETER email
        Email do usuario

    .PARAMETER cargo
        Cargo (conforme estabelecido no template de roles) do usuario

    .PARAMETER time
        Nome do time cadastrado na Veracode

    .EXAMPLE
        New-UserJson $nome $sobrenome $email $cargo $time

    .INPUTS
        String

    .OUTPUTS
        JSON configurado

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Nome do usuario")]
        $nome,
        [parameter(position=1,Mandatory=$True,HelpMessage="Sobrenome do usuario")]
        $sobrenome,
        [parameter(position=2,Mandatory=$True,HelpMessage="Email do usuario")]
        $email,
        [parameter(position=3,Mandatory=$True,HelpMessage="Cargo do usuario")]
        $cargo,
        [parameter(position=4,Mandatory=$True,HelpMessage="Equipe do usuario")]
        $time,
        [parameter(position=5,HelpMessage="Caminho para os templates")]
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
    <#
    .SYNOPSIS
        Função para bloquear usuarios Veracode

    .DESCRIPTION
        Com base no email, faz o bloqueio do usuario na plataforma da Veracode

    .PARAMETER emailUsuario
        Email do usuario que quer bloquear

    .PARAMETER caminhoJSON
        Caminho do arquivo JSON de template (por padrão vem com o valor da estrutura de pastas original do projeto).

    .EXAMPLE
        Block-VeracodeUser $emailUsuario

    .INPUTS
        Email de um usuario e caminho de um template

    .OUTPUTS
        Mensagem de confirmação ou de erro

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Email do usuario")]
        $emailUsuario,
        [parameter(position=1,HelpMessage="Caminho para o template JSON")]
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
    <#
    .SYNOPSIS
        Função para validar o retorno das APIs

    .DESCRIPTION
        Analisa o retorno da API para validar se teve uma resposta valida

    .PARAMETER retornoAPI
        Retorno da chamada de API

    .EXAMPLE
        $retornoAPI = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?size=1000" | ConvertFrom-Json
        Debug-VeracodeAPI $retornoAPI

    .INPUTS
        Retorno da chamada de API

    .OUTPUTS
        Mensagem de erro ou de confirmação

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Retorno da API que quer analisar")]
        $retornoAPI
    )

    try {
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
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Erro no Powershell:"
        Write-Host "$ErrorMessage"
    }
}

function Get-VeracodeUserID {
    <#
    .SYNOPSIS
        Função para obter o ID de um usuario Veracode

    .DESCRIPTION
        Com base num email, retorna o ID do usuario

    .PARAMETER emailUsuario
        Email do usuario alvo

    .EXAMPLE
        Get-VeracodeUserID "user@corp.com"

    .INPUTS
        Email do usuario

    .OUTPUTS
        ID do usuario

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
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
        $ErrorMessage = $_.Exception.Message
        Write-Host "Erro no Powershell:"
        Write-Host "$ErrorMessage"
    }
}

function New-VeracodeTeam {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Nome da equipe")]
        $teamName,
        [parameter(position=1,HelpMessage="Caminho da pasta de templates")]
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
    <#
    .SYNOPSIS
        Função para obter roles

    .DESCRIPTION
        Com base num tipo de cargo/função, retorna uma lista de roles compativeis com a atividade

    .PARAMETER tipoFuncionario
        Tipo de cargo/função

    .PARAMETER caminhoJSON
        Caminho do arquivo JSON de template (por padrão vem com o valor da estrutura de pastas original do projeto).

    .EXAMPLE
        Get-VeracodeRoles "Desenvolvedor"

    .INPUTS
        Cargo do usuario e caminho de um template

    .OUTPUTS
        Roles

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Nome do cargo conforme estabelecido no template")]
        $tipoFuncionario,
        [parameter(position=1,HelpMessage="Caminho da pasta de templates")]
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
    <#
    .SYNOPSIS
        Função para atualizar as roles de um usuario

    .DESCRIPTION
        Atualiza as roles de um usuario com base em um cargo/função

    .PARAMETER emailUsuario
        Email do usuario

    .PARAMETER tipoFuncionario
        Tipo de cargo/função

    .PARAMETER caminhoJSON
        Caminho do arquivo JSON de template (por padrão vem com o valor da estrutura de pastas original do projeto).

    .EXAMPLE
        Update-VeracodeUserRoles "user@corp.com" "Desenvolvedor"

    .INPUTS
        Email e cargo do usuario, caminho de um template

    .OUTPUTS
        Mensagem de confirmação ou de erro

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Email da conta conforme cadastrado na Veracode (Caso seja uma conta de API, informar o UserName dela)")]
        $emailUsuario,
        [parameter(position=1,Mandatory=$True,HelpMessage="Tipo de roles desejado (ex: QA, SOC, Desenvolvedor)")]
        $tipoFuncionario,
        [parameter(position=2,HelpMessage="Caminho da pasta de templates")]
        $pastaTemplates = ".\Templates"
    )

    try {
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
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Erro no Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function Remove-VeracodeUser {
    <#
    .SYNOPSIS
        Função para deletar usuarios Veracode

    .DESCRIPTION
        Com base no email, faz a remoção do usuario na plataforma da Veracode

    .PARAMETER emailUsuario
        Email do usuario que quer deletar

    .EXAMPLE
        Remove-VeracodeUser $emailUsuario

    .INPUTS
        Email de um usuario

    .OUTPUTS
        Mensagem de confirmação ou de erro

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Email da conta conforme cadastrado na Veracode (Caso seja uma conta de API, informar o UserName dela)")]
        $emailUsuario
    )
    
    try {
        # Recebe o ID com base no nome
        $idUsuario = Get-VeracodeUserID $emailUsuario
    
        if ($idUsuario) {
            # Deleta o usuario
            $retornoAPI = http --auth-type=veracode_hmac DELETE "https://api.veracode.com/api/authn/v2/users/$idUsuario" | ConvertFrom-Json
            if ($retornoAPI) {
                Debug-VeracodeAPI $retornoAPI
            } else {
                Write-Host "Usuario $emailUsuario foi deletado"
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Erro no Powershell:"
        Write-Error "$ErrorMessage"
    }
}

# Valores de teste
# $nome = "Joao"
# $sobrenome = "Silva"
# $email = "prevendas+testeUM" + (Get-Date -Format sshhmmddMM) + "@m3corp.com.br"
# $cargo = "Desenvolvedor"
# $time = "DEMOs"

# Exemplo de como importar o modulo
# $pastaModulos = Get-Location
# Import-Module -Name "$pastaModulos\VeracodeUM.psm1" -Verbose

# Teste de funções
# $caminhoJSON = New-UserJson $nome $sobrenome $email $cargo $time
# New-VeracodeUser $caminhoJSON
# Update-VeracodeUserRoles $emailUsuario $tipoFuncionario
# Block-VeracodeUser $emailUsuario
# Remove-VeracodeUser $emailUsuario
# $novoTime = "UM-Teste-" + (Get-Date -Format sshhmmddMM)
# New-VeracodeTeam "$novoTime"
# Get-VeracodeTeamID $novoTime