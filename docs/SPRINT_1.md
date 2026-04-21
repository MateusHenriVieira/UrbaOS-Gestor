# Documentação Técnica - UrbaOS (Administração)
## Relatório de Conclusão: Sprint 1 - Fundação, Autenticação e RBAC

**Data de Conclusão:** Abril de 2026
**Foco:** Estabelecer a arquitetura base, integrar o Firebase, criar o motor de controle de acesso baseado em funções (RBAC) e definir o Design System da aplicação.

---

### 1. Arquitetura e Padrões Adotados
O projeto foi inicializado utilizando **Feature-First Clean Architecture**, garantindo que cada módulo do sistema seja independente e testável.

* **Gerenciamento de Estado:** BLoC (`flutter_bloc`). Escolhido pela sua robustez em lidar com fluxos complexos e separação rigorosa de regras de negócio.
* **Injeção de Dependências:** Service Locator com `get_it`. Permite instanciar repositórios e BLoCs sob demanda sem acoplamento rígido.
* **Roteamento:** `go_router`. Utilizado para interceptação de rotas e redirecionamento dinâmico baseado no estado da autenticação.
* **Design System:** Foi abandonado o Material Design padrão em favor de um tema "Zinc" (minimalista, monocromático, bordas secas, inspirado no Svelte/Shadcn UI) para adequação visual corporativa/governamental.

---

### 2. Configuração do Backend (Firebase)
A conexão com o Firebase foi estabelecida utilizando o padrão moderno do **FlutterFire CLI**, eliminando a necessidade de gerenciar arquivos nativos (`google-services.json` ou `GoogleService-Info.plist`).

* **Pacotes Integrados:** `firebase_core`, `firebase_auth`.
* **Segurança:** A inicialização ocorre no ponto mais alto da aplicação (`main.dart`) de forma assíncrona antes da renderização da interface.

---

### 3. Autenticação e Regras de Negócio (RBAC)
O controle de acesso atende ao requisito de *Multitenancy* (Obras vs. Recursos Hídricos). A autenticação não apenas valida e-mail e senha, mas também extrai e interpreta as **Custom Claims** geradas no Firebase.

#### 3.1. Entidade de Domínio (`LoggedUser`)
Criada para transitar pelo app sem dependência do pacote do Firebase, contendo:
* `uid`, `email`, `name`
* `role`: Identifica se é `manager` (Gestor) ou `coordinator` (Coordenador).
* `department`: Identifica a secretaria (`obras`, `hidricos`, ou `all` para Gestores).

#### 3.2. Camada de Dados (`FirebaseAuthRepository`)
Responsável por:
* Realizar o login via Email/Senha no Firebase Auth.
* Forçar o refresh do *Token JWT* no login para garantir a leitura imediata de novas Custom Claims.
* Traduzir os códigos de erro do Firebase para mensagens amigáveis em português.

#### 3.3. Gerenciamento de Estado (`AuthBloc`)
Escuta três eventos principais (`AuthCheckRequested`, `AuthSignInRequested`, `AuthSignOutRequested`) e emite estados que refletem a sessão atual, disparando *loadings* e capturando erros do repositório.

---

### 4. Roteamento de Guarda (Route Guards)
O arquivo `app_router.dart` foi configurado para escutar a *stream* do `AuthBloc` em tempo real. As regras de guarda são rígidas:
* **Não autenticado:** Trancado na rota `/login`.
* **Autenticado como Gestor (`role: manager`):** Redirecionamento forçado para `/dashboard/manager`.
* **Autenticado como Coordenador (`role: coordinator`):** Redirecionamento forçado para `/dashboard/coordinator`.

---

### 5. Interface Gráfica (UI)
* **AppTheme:** Centralizado no arquivo `app_theme.dart`. Define globalmente a tipografia, cores (tons de *Zinc*), remoção de sombras (elevation: 0) e bordas padronizadas para botões e inputs de texto.
* **Tela de Login (`LoginPage`):** Tela responsiva (limitada a 360px de largura para ficar legível em tablets), utilizando um fundo com *CustomPainter* (grid arquitetônico) e `BlocConsumer` para desabilitar inputs durante o carregamento e exibir `SnackBar` de erro.

---

### Resumo do que foi entregue
1. [x] Estrutura de pastas Clean Architecture.
2. [x] Configuração Firebase CLI.
3. [x] Configuração `GetIt` (Injeção de dependência).
4. [x] Criação de Modelos e Entidades de Usuário.
5. [x] Implementação de login e extração de Custom Claims.
6. [x] BLoC de Autenticação.
7. [x] GoRouter com validação de perfil (Gestor vs. Coordenador).
8. [x] Design System Global (Zinc) e Tela de Login concluída.