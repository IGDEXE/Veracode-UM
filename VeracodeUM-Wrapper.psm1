function Novo-UsuarioVeracode {
    param (
        $nome,
        $sobrenome,
        $email,
        $cargo,
        $time
    )

    try {
        # Com base no cargo define as roles
        if ($cargo -eq "Desenvolvedor") {
            $roles = "Creator,Submitter,eLearning"
        } if ($cargo -eq "Gestor") {
            $roles = ""
        }

        # Faz a criação do usuario
        VeracodeAPI.exe -action createuser -firstname $nome -lastname $sobrenome -emailaddress $email -roles $roles -teams $time
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
    
}