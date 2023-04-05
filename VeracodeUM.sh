novoUsuario(){
    caminhoJson=$1
    http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users" < $caminhoJSON
}

atualizarUsuario(){
    caminhoJson=$1
    http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users" < $caminhoJSON
}

infoUsuario() {
    emailUsuario=$1
    infos=$(http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?user_name=$emailUsuario")
    return $infos
}