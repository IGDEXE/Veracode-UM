# Veracode-UM
 Projeto para gerenciamento de usuarios utilizando as novas APIs da Veracode

# Antes de usar:
Instale os componentes que a Veracode precisa para utilizar:<br>
pip install httpie<br>
pip install veracode-api-signing<br>

# Lista de funções implementadas:
New-VeracodeUser - Criar novos usuários<br>
Get-VeracodeUserID - Pega o ID de um usuário com base no email<br>
Get-VeracodeTeamID - Pega o ID de um time com base no nome<br>
Block-VeracodeUser - Bloqueia o usuário com base no email<br>
New-UserJson - Cria o JSON para usar na New-VeracodeUser<br>
Debug-VeracodeAPI - Valida o retorno da API<br>
New-VeracodeTeam - Criar um novo time<br>
Get-VeracodeRoles - Pega a lista de roles com base no cargo<br>

# Lista de funções mapeadas:
Update-VeracodeUserRoles - Atualiza a lista de roles de um usuário<br>
Delete-VeracodeUser - Deleta o usuário com base no email<br>