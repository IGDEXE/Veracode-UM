# Veracode-UM
 Projeto para gerenciamento de usuários utilizando as novas APIs da Veracode

# Antes de usar:
Instale os componentes que a Veracode precisa para utilizar:<br>
pip install httpie<br>
pip install veracode-api-signing<br>

# Lista de funções implementadas:
New-VeracodeUser - Criar novos usuários<br>
New-UserJson - Cria o JSON para usar na New-VeracodeUser<br>
New-VeracodeTeam - Criar um novo time<br>
Get-VeracodeUserID - Pega o ID de um usuário com base no email<br>
Get-VeracodeTeamID - Pega o ID de um time com base no nome<br>
Get-VeracodeRoles - Pega a lista de roles com base no cargo<br>
Block-VeracodeUser - Bloqueia o usuário com base no email<br>
Debug-VeracodeAPI - Valida o retorno da API<br>
Update-VeracodeUserRoles - Atualiza a lista de roles de um usuário<br>
Remove-VeracodeUser - Deleta o usuário com base no email<br>

# Como usar?
Faça a importação do modulo VeracodeUM.psm1 no Powershell<br>
Reaproveite as funções em seus próprios scripts<br>
Caso queira usar num formato de scripts, use os das pastas correspondentes<br>

# Como usar no Linux?
Recomendo que consulte a documentação para verificar todos os detalhes:<br>
https://learn.microsoft.com/pt-br/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3<br>
Esse projeto foi testado no Ubuntu 22.04.1 LTS<br>
Depois da instalação do Powershell on Linux, basta utilizar sem nenhuma alteração<br>
