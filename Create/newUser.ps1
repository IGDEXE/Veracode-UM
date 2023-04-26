param (
    [parameter(position=0,Mandatory=$True,HelpMessage="Caminho do arquivo JSON com os dados para criar um novo usuario")]
    $caminhoJSON
)

function Debug-VeracodeAPI {
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
