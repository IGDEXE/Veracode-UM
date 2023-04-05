# Veracode-UM
 Projeto para gerenciamento de usuarios utilizando as novas APIs da Veracode

# Antes de usar:
Instale os componentes que a Veracode precisa para utilizar:<br>
pip install httpie<br>
pip install veracode-api-signing

# Lista de funções e objetivos:
New-VeracodeUser - Criar novos usuários 
New-VeracodeTeam - Criar um novo time
Get-VeracodeUserID - Pega o ID de um usuário com base no email
Get-VeracodeTeamID - Pega o ID de um time com base no nome
Get-VeracodeRoles - Pega a lista de roles com base no cargo
Update-VeracodeUserRoles - Atualiza a lista de roles de um usuário
Block-VeracodeUser - Bloqueia o usuário com base no email
Delete-VeracodeUser - Deleta o usuário com base no email