# Dependencias
import sys
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

# Recebe o caminho do arquivo
caminhoJSON = (sys.argv[1])

# Faz a criação do usuario
http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users" < caminhoJSON