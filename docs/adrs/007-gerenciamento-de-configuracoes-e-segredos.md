# ADR-007: Separação entre configurações e informações sensíveis

## Status

Aceito

## Contexto

A aplicação necessita de variáveis de ambiente para sua execução.

Essas variáveis possuem diferentes níveis de sensibilidade.

Algumas configurações podem ser armazenadas diretamente na infraestrutura, enquanto informações como senhas e chaves não devem ser versionadas no repositório.

## Decisão

As configurações não sensíveis serão armazenadas utilizando Kubernetes ConfigMaps.

Exemplos:

- DJANGO_DEBUG;
- DJANGO_SETTINGS_MODULE;
- DJANGO_ALLOWED_HOSTS;
- DB_HOST;
- DB_PORT;
- STATIC_ROOT.

Informações sensíveis serão armazenadas utilizando Kubernetes Secrets.

Exemplos:

- DJANGO_SECRET_KEY;
- POSTGRES_PASSWORD;
- credenciais do banco de dados.

Os valores reais dos Secrets não serão versionados no repositório.

Será mantido apenas um arquivo de exemplo.

## Consequências

### Positivas

- Configurações não sensíveis ficam separadas de informações confidenciais.
- O repositório não precisa armazenar senhas reais.
- Os ambientes podem possuir configurações diferentes.
- Os manifests podem utilizar referências aos Secrets.

### Negativas

- Kubernetes Secrets precisam ser gerenciados durante o provisionamento.
- É necessário definir uma estratégia segura para criação dos Secrets no ambiente.
- Secrets do Kubernetes não são automaticamente criptografados apenas por serem Secrets.

## Alternativas consideradas

### Armazenar todas as variáveis diretamente no Deployment

Não foi escolhido porque aumentaria a duplicação e dificultaria o gerenciamento.

### Versionar credenciais no Git

Não foi escolhido porque representaria um risco de segurança.
