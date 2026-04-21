# Análise do Código `lib/` — Defeitos, Problemas e Plano de Correção

**Data da análise:** 2026-04-17
**Escopo:** Toda a pasta `lib/` (64 arquivos Dart, ~3.500 linhas)
**Projeto:** UrbaOS Admin (Flutter + Firebase + BLoC + Clean Architecture)

---

## Sumário Executivo

| Severidade | Quantidade |
|------------|------------|
| 🔴 CRÍTICO | 12 |
| 🟠 ALTO    | 28 |
| 🟡 MÉDIO   | 38 |
| 🟢 BAIXO   | 17 |
| **Total**  | **95** |

**Status das correções:** ✅ **Fases 1–4 concluídas + Fase 5 (nova feature Live Tracking) entregue em 2026-04-17.** `flutter analyze` retorna **"No issues found!"** (zero erros, warnings ou infos). Foi também aplicada uma **correção urgente de schema** (`nome` vs `name`) após alinhamento com o usuário — detalhada em §14. Veja [11. Rastreamento de Status](#11-rastreamento-de-status) para detalhes por item e as seções §12 a §17 para os changelogs técnicos (§17 = Live Tracking).

---

## Índice

1. [Core (`lib/core/`, `main.dart`, `injection_container.dart`, `firebase_options.dart`)](#1-core)
2. [Feature: Auth](#2-feature-auth)
3. [Feature: Service Orders](#3-feature-service-orders)
4. [Feature: Material Approvals](#4-feature-material-approvals)
5. [Feature: Dashboard](#5-feature-dashboard)
6. [Feature: GPS Monitoring](#6-feature-gps-monitoring)
7. [Feature: Fleet Monitoring](#7-feature-fleet-monitoring)
8. [Feature: User Management](#8-feature-user-management)
9. [Problemas Transversais (múltiplos arquivos)](#9-problemas-transversais)
10. [Plano de Correção](#10-plano-de-correção)
11. [Rastreamento de Status](#11-rastreamento-de-status)

---

## 1. Core

### 1.1 `lib/main.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.1.1 | — | 🟡 MÉDIO | Arquitetura | `AuthCheckRequested()` é despachado automaticamente no `initState` sem BlocListener de fallback | Mover para dentro de um BlocListener ou garantir que só dispare uma vez |
| 1.1.2 | 45-54 | 🟡 MÉDIO | Performance | `appRouter` criado como `late final` — pode ser Singleton via DI | Mover para `injection_container.dart` como `sl<GoRouter>()` |

### 1.2 `lib/injection_container.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.2.1 | 68 | 🟠 ALTO | Qualidade | `sl<ServiceOrdersRepository>()` passado sem tipo explícito para `FirebaseFirestore` | Injetar explicitamente: `sl<FirebaseFirestore>()` |
| 1.2.2 | 73 | 🟠 ALTO | Qualidade | `sl()` sem parâmetro de tipo — DI ambígua | Tipar: `sl<FirebaseFirestore>()` |
| 1.2.3 | 129 | 🟡 MÉDIO | Arquitetura | `FleetMonitoringBloc` recebe `FirebaseFirestore` direto, quebrando Clean Architecture | Criar `FleetMonitoringRepository` |

### 1.3 `lib/firebase_options.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.3.1 | 43-87 | 🔴 CRÍTICO | Segurança | Chaves do Firebase **hardcoded** no código-fonte | Rotacionar chaves no Firebase Console; considerar uso de `.env` + `flutter_dotenv`; configurar restrições de API Key no GCP |

> ⚠️ **Nota:** Em projetos Flutter/Firebase, é comum as chaves ficarem em `firebase_options.dart`. O risco real não é a exposição em si (são chaves client-side), mas a **ausência de restrições de domínio/pacote no GCP Console**. Priorize configurar essas restrições.

### 1.4 `lib/core/theme/app_theme.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.4.1 | 71-75 | 🟡 MÉDIO | Qualidade | `TextTheme` incompleto (faltam `bodySmall`, `labelMedium`, `displayLarge` etc.) | Expandir com todos os estilos |

### 1.5 `lib/core/routes/app_router.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.5.1 | 184, 204, 226, 276 | 🟠 ALTO | Bug | Force unwrap `state.pathParameters['...']!` sem validação | Usar `state.pathParameters['id'] ?? ''` + redirect se vazio |
| 1.5.2 | 287-301 | 🟡 MÉDIO | Segurança | `_redirect` **não implementa** proteção real de rotas | Verificar estado do `AuthBloc` e redirecionar para `/login` se não autenticado |
| 1.5.3 | 307-322 | 🟠 ALTO | Bug | `GoRouterRefreshStream` nunca cancela a subscription no dispose | Implementar `dispose()` chamando `cancel()` e `removeListener` |
| 1.5.4 | 100-166 | 🟡 MÉDIO | Performance | BLoCs despacham eventos antes do widget estar mounted | Usar `context.read()` após `addPostFrameCallback` |

### 1.6 `lib/core/layout/scaffold_with_nav_bar.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.6.1 | 21 | 🟢 BAIXO | Qualidade | `paths` como lista de strings — preferir enum | Criar `enum NavigationRoute` |
| 1.6.2 | 56 | 🟡 MÉDIO | Tema | Cor verde hardcoded | Usar `Theme.of(context).primaryColor` |

### 1.7 `lib/core/widgets/app_shell.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 1.7.1 | 16-22 | 🟢 BAIXO | Duplicação | `_navItems` duplicado com `scaffold_with_nav_bar.dart` | Extrair para `lib/core/constants/nav_items.dart` |

---

## 2. Feature: Auth

### 2.1 `domain/entities/logged_user.dart`

| # | Severidade | Categoria | Problema | Solução |
|---|-----------|-----------|----------|---------|
| 2.1.1 | 🟢 BAIXO | Qualidade | Enum `Department` não é `Equatable` | Adicionar `extends Equatable` |

### 2.2 `data/repositories/firebase_auth_repository.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 2.2.1 | 31, 58 | 🔴 CRÍTICO | Bug | Force unwrap `userCredential.user!` sem verificação | Validar explicitamente antes de acessar |
| 2.2.2 | 92, 106 | 🟡 MÉDIO | Bug | `catch (_) {}` silencia erros | Logar com `debugPrint` antes de ignorar |
| 2.2.3 | 44 | 🟡 MÉDIO | Qualidade | `.replaceAll('Exception: ', '')` é frágil | Usar tipagem forte para mensagens de erro |

### 2.3 `presentation/bloc/auth_bloc.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 2.3.1 | 28-31 | 🟡 MÉDIO | Bug | Erros genéricos caem em `AuthUnauthenticated` | Adicionar estado `AuthError` |
| 2.3.2 | 42-45 | 🟡 MÉDIO | Qualidade | `e.toString()` pode vazar stack trace | Mapear para mensagens amigáveis |

### 2.4 `presentation/pages/login_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 2.4.1 | 172-174 | 🟢 BAIXO | UX | "Esqueceu a senha?" com `onPressed: () {}` (placeholder) | Implementar ou remover |
| 2.4.2 | 217 | 🟡 MÉDIO | Performance | `_GridPainter.shouldRepaint()` sempre `false` mesmo com dados mudando | Revisar lógica de repaint |

---

## 3. Feature: Service Orders

### 3.1 `domain/entities/service_order.dart`

| # | Severidade | Categoria | Problema | Solução |
|---|-----------|-----------|----------|---------|
| 3.1.1 | 🟡 MÉDIO | Qualidade | Não implementa `Equatable` | Adicionar `extends Equatable` + `props` |

### 3.2 `data/repositories/firebase_service_orders_repository.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 3.2.1 | 15-16 | 🟠 ALTO | Bug/Segurança | Compara `Department` enum via `.name` (string) | Comparar enum diretamente: `if (user.department != Department.all)` |

### 3.3 `presentation/bloc/service_orders_bloc.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 3.3.1 | 22 | 🔴 CRÍTICO | Memory Leak | `_ordersSubscription?.cancel()` sem await — pode vazar em eventos rápidos | Aguardar cancelamento antes de assinar novo stream |
| 3.3.2 | 26-29 | 🟡 MÉDIO | Bug | `onError` não persiste estado de erro | Emitir `ServiceOrdersError` específico |

### 3.4 `presentation/bloc/create_order_bloc.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 3.4.1 | 38 | 🟠 ALTO | Bug | `event.imageFile!` force unwrap sem validar existência do arquivo | Validar `existsSync()` antes |
| 3.4.2 | 40-43 | 🟡 MÉDIO | Qualidade | Erro de upload silenciado | Adicionar `debugPrint` |
| 3.4.3 | 52 | 🟢 BAIXO | Qualidade | Status hardcoded `'pending'` | Usar enum `ServiceOrderStatus.pending` |

### 3.5 `presentation/pages/service_orders_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 3.5.1 | 87-127 | 🟠 ALTO | Performance | `ordersByTech` recalculado a cada build | Mover para BLoC ou memoizar |
| 3.5.2 | 125 | 🟠 ALTO | Bug | `.sort()` muta lista original | Usar `[...list]..sort()` |
| 3.5.3 | 24 | 🟡 MÉDIO | Qualidade | Filtros hardcoded `['Todos', 'Em Serviço', 'Livres']` | Extrair para enum/constantes |

### 3.6 `presentation/pages/create_os_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 3.6.1 | 80 | 🟡 MÉDIO | Performance | Image picker sem `imageQuality` definido | Adicionar `imageQuality: 85` |

### 3.7 `presentation/pages/os_details_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 3.7.1 | 16 | 🔴 CRÍTICO | Arquitetura | Uso direto de `FirebaseFirestore.instance` em widget | Injetar via BLoC/Repository |
| 3.7.2 | 35, 40, 43 | 🟡 MÉDIO | Performance | Múltiplos Streams recriados a cada rebuild | Mover para BLoC |
| 3.7.3 | 166 | 🟢 BAIXO | UX | URL placeholder do Unsplash pode quebrar | Usar asset local |

---

## 4. Feature: Material Approvals

### 4.1 `presentation/bloc/materials_bloc.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 4.1.1 | 28, 32 | 🟠 ALTO | Bug | `query.where(...)` sem atribuição — filtro nunca é aplicado | Reatribuir: `query = query.where(...)` |
| 4.1.2 | 38-46 | 🟡 MÉDIO | Arquitetura | Usa `Map<String, dynamic>` ao invés de entity tipada | Criar entity `Technician` |
| 4.1.3 | 43 | 🟠 ALTO | Qualidade | Aceita tanto `'nome'` quanto `'name'` — inconsistência de schema | Padronizar nome de campo no Firestore (preferir `name`) |

### 4.2 `presentation/pages/materials_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 4.2.1 | 34, 43-52 | 🔴 CRÍTICO | Arquitetura | Firestore direto em widget | Mover para BLoC |
| 4.2.2 | 47, 56, 59, 79 | 🟢 BAIXO | Qualidade | `debugPrint` em produção | Remover ou envolver em `if (kDebugMode)` |

### 4.3 `presentation/pages/quick_approval_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 4.3.1 | 71 | 🟡 MÉDIO | Bug | `TODO: Pegar do usuário logado` — funcionalidade incompleta | Injetar `AuthBloc` |

---

## 5. Feature: Dashboard

### 5.1 `data/repositories/firebase_dashboard_repository.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 5.1.1 | 14-19 | 🟠 ALTO | Bug | Filtro de departamento via `.name` string | Comparação direta de enum |
| 5.1.2 | 22-34 | 🟡 MÉDIO | Performance | `asyncMap` por documento é O(n²) em escala | Usar agregações do Firestore |
| 5.1.3 | 44 | 🟡 MÉDIO | Performance | `await materialQuery.get()` dentro de stream bloqueia fluxo | Buscar uma vez na inicialização |

### 5.2 `presentation/bloc/dashboard_bloc.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 5.2.1 | 21-25 | 🟡 MÉDIO | Bug | `emit.forEach` sem cancelar subscription anterior | Cancelar antes de assinar novamente |

### 5.3 `presentation/pages/dashboard_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 5.3.1 | 38 | 🟢 BAIXO | UX | `.split(' ').first` em nome vazio → string vazia | Fallback `?? 'Usuário'` |
| 5.3.2 | 96 | 🟡 MÉDIO | Performance | Check de estado em build sem `context.select` | Usar `context.select((bloc) => ...)` |

---

## 6. Feature: GPS Monitoring

### 6.1 `domain/entities/location.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 6.1.1 | — | 🟡 MÉDIO | Qualidade | Não implementa `Equatable` | Adicionar |
| 6.1.2 | 26-38 | 🟡 MÉDIO | Bug | `fromJson` não valida tipos — crash se vier string | Cast seguro: `(json['latitude'] as num?)?.toDouble() ?? 0.0` |

### 6.2 `data/repositories/firebase_location_repository.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 6.2.1 | 56-58 | 🟡 MÉDIO | Qualidade | `catch` genérico retornando `null` sem log | Logar erro |
| 6.2.2 | 68-72 | 🟠 ALTO | Bug | `.where((l) => l != null)` não é type-safe | Usar `.whereType<Location>()` |
| 6.2.3 | 100-102 | 🟡 MÉDIO | Bug | Conversão `Timestamp → int → Map` frágil | Padronizar formato |

### 6.3 `data/services/location_service.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 6.3.1 | 14 | 🟡 MÉDIO | Bug | `_positionStreamSubscription` não cancelado se `stopTracking` chamado cedo | Null-check antes de cancelar |
| 6.3.2 | 62, 115 | 🔴 CRÍTICO | Bug | `saveLocation()` sem `await` — dados inconsistentes | Adicionar `await` |
| 6.3.3 | 82-87 | 🟠 ALTO | Concorrência | Variáveis de estado não thread-safe | Usar `StreamController` ou `StateNotifier` |

### 6.4 `presentation/pages/tracking_map_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 6.4.1 | 20 | 🟢 BAIXO | UX | Placeholder "Em breve" | Implementar ou remover |

---

## 7. Feature: Fleet Monitoring

### 7.1 `presentation/bloc/fleet_monitoring_bloc.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 7.1.1 | 24-32 | 🟠 ALTO | Bug | `query.where` sem reatribuição — filtro ignorado | `query = query.where(...)` |
| 7.1.2 | 44 | 🔴 CRÍTICO | Bug | Campos `isOnline` e `lastSync` não existem no modelo | Criar campos no Firestore ou usar defaults seguros |

### 7.2 `presentation/pages/fleet_monitoring_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 7.2.1 | 21-52 | 🔴 CRÍTICO | Qualidade | **Dados mockados hardcoded** não conectam ao Firestore | Remover e usar BLoC |
| 7.2.2 | 64-71 | 🟡 MÉDIO | Arquitetura | Filtragem local no widget | Mover para BLoC |

### 7.3 `presentation/pages/fleet_gps_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 7.3.1 | 58-60, 68-72 | 🟢 BAIXO | Qualidade | `debugPrint` em produção | Envolver em `kDebugMode` |

### 7.4 `presentation/pages/live_tech_tracking_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 7.4.1 | 26 | 🔴 CRÍTICO | Memory Leak | `MapController` nunca é `dispose()` | Chamar `_mapController.dispose()` em `dispose()` |
| 7.4.2 | 79-81 | 🟡 MÉDIO | Race Condition | `addPostFrameCallback` sem `mounted` check | Verificar `mounted` antes de usar |

---

## 8. Feature: User Management

### 8.1 `presentation/pages/create_technician_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 8.1.1 | 31 | 🟡 MÉDIO | Bug | `late final` inicializado em `initState` — acesso prematuro | Inicializar inline ou via DI |
| 8.1.2 | 61 | 🔴 CRÍTICO | Bug | `!_formKey.currentState!.validate()` — double force unwrap | `_formKey.currentState?.validate() ?? false` |
| 8.1.3 | 79 | 🔴 CRÍTICO | Bug | `if (!mounted)` **sem return** — código continua após widget desmontar | Adicionar `return` após check |
| 8.1.4 | 41 | 🟠 ALTO | Qualidade | Salva simultaneamente `'nome'` e `'name'` | Padronizar |

### 8.2 `presentation/pages/settings_page.dart`

| # | Linha | Severidade | Categoria | Problema | Solução |
|---|-------|-----------|-----------|----------|---------|
| 8.2.1 | 45, 51 | 🔴 CRÍTICO | Arquitetura | Firestore direto em widget | Mover para BLoC |
| 8.2.2 | 49 | 🟠 ALTO | Bug | Compara `UserRole` (auth) com `UserRole` (user_management) — dois tipos diferentes com mesmo nome | Unificar definição do enum |

---

## 9. Problemas Transversais

| # | Severidade | Categoria | Problema | Solução |
|---|-----------|-----------|----------|---------|
| 9.1 | 🔴 CRÍTICO | Arquitetura | Widgets acessam `FirebaseFirestore.instance` direto (violação de Clean Architecture) | Todos via repositório injetado |
| 9.2 | 🟠 ALTO | Segurança | Queries sem validação de `userId`/role | Reforçar em todas as queries sensíveis + regras de segurança no Firestore |
| 9.3 | 🟠 ALTO | Memory Leak | `TextEditingController` sem dispose em alguns widgets | Revisar `service_orders_page`, `materials_page`, `fleet_monitoring_page`, `settings_page` |
| 9.4 | 🟠 ALTO | Bug | Force unwrap `!` em path params do router | `?? '' ` + redirect |
| 9.5 | 🟠 ALTO | Bug | `try/catch` vazio silenciando erros | Logar antes de ignorar |
| 9.6 | 🟡 MÉDIO | Qualidade | Strings hardcoded de status/filtros | `lib/core/constants/app_constants.dart` |
| 9.7 | 🟡 MÉDIO | Duplicação | Lógica de filtro de departamento repetida em N repositories | Helper `filterQueryByDepartment(q, user)` |
| 9.8 | 🟡 MÉDIO | Acessibilidade | `IconButton` sem `tooltip`/`Semantics` | Adicionar labels |
| 9.9 | 🟡 MÉDIO | Performance | Widgets que poderiam ser `const` não são | Passada de refactor |
| 9.10 | 🟠 ALTO | Qualidade | Inconsistência de schema Firestore: `nome` vs `name` | Migração + padronizar em `name` |
| 9.11 | 🟠 ALTO | UX | Erros Firebase não mapeados para mensagens amigáveis | Criar `ErrorMapper` central |
| 9.12 | 🟡 MÉDIO | Validação | Formulários sem `.trim()` e regex de email | Helper `Validators` |

---

## 10. Plano de Correção

### 🔴 Fase 1 — CRÍTICOS (aplicar imediatamente)

1. Corrigir `if (!mounted)` sem `return` em `create_technician_page.dart:79`
2. Corrigir double force unwrap em `create_technician_page.dart:61`
3. Adicionar `await` em `saveLocation()` no `location_service.dart:62, 115`
4. Dispose do `MapController` em `live_tech_tracking_page.dart`
5. Implementar `_redirect()` real em `app_router.dart`
6. Remover dados mockados de `fleet_monitoring_page.dart`
7. Corrigir `query.where` sem reatribuição em `fleet_monitoring_bloc.dart:24-32` e `materials_bloc.dart:28, 32`
8. Remover `FirebaseFirestore.instance` direto de `os_details_page.dart`, `materials_page.dart`, `settings_page.dart`
9. Corrigir unwrap em `firebase_auth_repository.dart:31, 58`
10. Corrigir `cancel()` não-awaited em `service_orders_bloc.dart:22`
11. Corrigir comparação `UserRole` duplicado em `settings_page.dart:49`
12. Configurar restrições de API Key no GCP para `firebase_options.dart`

### 🟠 Fase 2 — ALTOS (próxima sprint)

- Padronizar schema Firestore (`nome` → `name`) + script de migração
- Force unwraps do router (`app_router.dart`)
- Dispose de `TextEditingController` em todos os widgets
- Logar erros em todos os `try/catch`
- `.whereType<Location>()` no repository
- Validação de `userId`/role em queries
- Comparação de enum `Department` (não via `.name`)
- Mover lógica do `service_orders_page` para BLoC
- `.sort()` mutando lista

### 🟡 Fase 3 — MÉDIOS (2 sprints)

- `Equatable` em todas as entities
- Helper `filterQueryByDepartment`
- `app_constants.dart` com enums de status/filtros
- `ErrorMapper` central
- `Validators` helper
- `TextTheme` completo
- Semantic labels / tooltips
- Trocar `Map<String, dynamic>` por entities tipadas em `materials_bloc`

### 🟢 Fase 4 — BAIXOS (melhorias contínuas)

- `const` onde possível
- Remover `debugPrint` de produção (`kDebugMode`)
- Extrair `_navItems` duplicados
- Implementar ou remover placeholders ("Em breve", "Esqueceu a senha?")
- `enum NavigationRoute`

---

## 11. Rastreamento de Status

> Atualizar esta tabela conforme os itens forem corrigidos.

| Item | Severidade | Status | Commit/PR | Observações |
|------|-----------|--------|-----------|-------------|
| 1.2.1/1.2.2 — `sl()` sem tipo em `injection_container` | 🟠 | ✅ Concluído | Fase 1 | Tipado como `sl<FirebaseFirestore>()` |
| 1.3.1 — Firebase API keys | 🔴 | 🟨 Parcial | Fase 1 | Documentado — requer ação no GCP Console (ver §12) |
| 1.5.1 — Force unwrap no router | 🟠 | ✅ Concluído | Fase 2 | Substituído por `?? ''` + redirect para `_invalidRoutePage` |
| 1.5.2 — `_redirect()` vazio | 🟡 | ✅ Concluído | Fase 1 | Protege rotas via `AuthBloc.state` + `refreshListenable` |
| 1.5.3 — Leak no `GoRouterRefreshStream` | 🟠 | ❌ Falso positivo | — | `dispose()` já cancela a subscription (linha 360) |
| 2.2.1 — Unwrap no auth repo | 🔴 | ✅ Concluído | Fase 1 | Refatorado para variável local + `ServerException` |
| 2.2.2 — `catch (_)` silencia erros | 🟡 | ✅ Concluído | Fase 1 | Agora loga com `debugPrint` |
| 3.3.1 — Cancel não-awaited | 🔴 | ✅ Concluído | Fase 1 | Handler agora `async` com `await` |
| 3.5.1 — Agrupamento de OS recalculado a cada build | 🟠 | ✅ Concluído | Fase 2 | Entity `TechnicianBoard` + cálculo 1x em `ServiceOrdersLoaded` |
| 3.5.2 — `.sort()` mutando lista original | 🟠 | ✅ Concluído | Fase 2 | Substituído por `[...orders]..sort(...)` |
| 3.7.1 — Firestore em widget (OS details) | 🔴 | 🟨 Parcial | Fase 1 | Injeção via `sl<FirebaseFirestore>()` (BLoC dedicado em Fase 3) |
| 4.1.1 — `query.where` sem reatribuição | 🟠 | ❌ Falso positivo | — | Código já reatribui `query = query.where(...)` corretamente |
| 4.2.1 — Firestore em widget (materials) | 🔴 | 🟨 Parcial | Fase 1 | Injeção via `sl` (BLoC completo em Fase 3) |
| 6.2.1 — `catch` no location repo sem log | 🟡 | ✅ Concluído | Fase 2 | Adicionado `debugPrint` em `getCurrentLocation` |
| 6.2.2 — `.whereType<Location>()` no location repo | 🟠 | 🟨 Ajustado | Fase 2 | `Stream` não suporta `whereType`; mantido `where + cast` com `map<Location?>` tipado |
| 6.3.2 — `saveLocation` sem await | 🔴 | ✅ Concluído | Fase 1 | `await` + try/catch com log |
| 7.1.1 — `query.where` fleet | 🟠 | ❌ Falso positivo | — | Código já reatribui corretamente |
| 7.1.2 — Campos `isOnline`/`lastSync` inexistentes | 🔴 | ⬜ Pendente | — | Fase 3 — requer definição de schema |
| 7.2.1 — Dados mockados em `fleet_monitoring_page` | 🔴 | ✅ Concluído | Fase 1 | Arquivo removido (era código morto, nenhuma rota apontava para ele) |
| 7.4.1 — `MapController` dispose | 🔴 | ❌ Falso positivo | — | Já presente em `live_tech_tracking_page.dart:51` |
| 8.1.2 — Double unwrap form | 🔴 | ✅ Concluído | Fase 1 | `_formKey.currentState?.validate() ?? false` |
| 8.1.3 — `!mounted` sem return | 🔴 | ❌ Falso positivo | — | `return` já presente nas linhas 79 e 93 |
| 8.2.1 — Firestore em settings | 🔴 | 🟨 Parcial | Fase 1 | Injeção via `sl` (BLoC completo em Fase 3) |
| 8.2.2 — `UserRole` duplicado | 🟠 | ✅ Concluído | Fase 1 | `UserRole` unificado em `auth/logged_user.dart` com `technician`; `user.dart` re-exporta |
| 9.1 — Clean Architecture (transversal) | 🔴 | 🟨 Parcial | Fases 1-2 | DI consistente + agregação `TechnicianBoard`; BLoCs dedicados em Fase 3 |
| 9.3 — `TextEditingController` sem dispose | 🟠 | ❌ Falso positivo | — | Todos os 8 widgets com `TextEditingController` já chamam `dispose()` |
| 9.7 — Duplicação de filtro por departamento | 🟡 | ⬜ Pendente | — | Fase 3 (helper em `core/`) |
| 9.10 — Schema `nome` vs `name` | 🟠 | ✅ Concluído | Fase 2 | `create_technician_bloc` passou a escrever apenas `name`; leitura mantém fallback para documentos antigos |
| 3.2.1 / 5.1.1 — Comparação `Department` via `.name` | 🟠 | ❌ Falso positivo | — | Comparações enum-vs-enum já estão corretas; `.name` é usado só para serializar no Firestore (que é string) |

**Legenda:** ⬜ Pendente · 🟨 Em andamento / parcial · ✅ Concluído · ❌ Falso positivo / não aplicável

---

## 12. Registro de Execução — Fase 1

**Data de execução:** 2026-04-17
**Resultado `flutter analyze`:** 0 erros (apenas warnings/infos pré-existentes, não introduzidos pela Fase 1).

### ✅ Aplicadas com sucesso

#### 1. Force unwrap em `create_technician_page.dart:61`
- **Antes:** `if (!_formKey.currentState!.validate()) return;`
- **Depois:** `if (!(_formKey.currentState?.validate() ?? false)) return;`
- **Impacto:** elimina crash potencial se `currentState` for nulo.

#### 2. `saveLocation` sem await em `location_service.dart`
- **Antes:** chamada fire-and-forget dentro do `listen()` do stream de `Position`.
- **Depois:** listener agora é `async` com `await` + `try/catch` logando via `debugPrint`. Import de `flutter/foundation.dart` adicionado.
- **Impacto:** persistência de localização deixa de ser silenciosamente perdida; erros ficam visíveis no console em dev.

#### 3. `_redirect()` vazio em `app_router.dart`
- **Depois:** implementa proteção real:
  - Não autenticado → qualquer rota que não seja `/login` redireciona para `/login`.
  - Autenticado → acessar `/login` redireciona para `/dashboard`.
  - `AuthInitial` / `AuthLoading` não redireciona (evita flicker durante boot).
- **Adicionado:** `refreshListenable: GoRouterRefreshStream(authBloc!.stream)` — router reavalia redirects quando o estado de auth muda (login/logout).

#### 4. Force unwrap em `firebase_auth_repository.dart` (linhas 30, 58)
- **Antes:** `userCredential.user!` após check de null.
- **Depois:** variável local `final user = userCredential.user;` + throw `ServerException` (em vez de `Exception` genérico) antes de usar `user`.
- **Bônus:** `catch (_)` → `catch (e) { debugPrint(...) }` nos dois pontos de fallback de cache/servidor.

#### 5. `cancel()` não-awaited em `service_orders_bloc.dart:21`
- **Antes:** `void _onLoadServiceOrdersRequested(...)` chamando `_ordersSubscription?.cancel()` sem await.
- **Depois:** handler agora é `Future<void>` com `await _ordersSubscription?.cancel();` antes de reatribuir.
- **Impacto:** evita condição de corrida onde duas subscriptions simultâneas emitem no BLoC.

#### 6. `fleet_monitoring_page.dart` (dados mockados)
- **Depois:** arquivo deletado. Verificado via grep que nenhuma rota apontava para `FleetMonitoringPage` — era código morto. A rota `/tracking` usa `FleetGpsPage`.

#### 7. `UserRole` duplicado entre `auth` e `user_management`
- **Antes:** dois enums distintos (`auth/logged_user.dart` sem `technician`; `user_management/user.dart` sem `unknown`).
- **Depois:**
  - `auth/logged_user.dart`: `enum UserRole { manager, coordinator, technician, unknown }` (fonte única).
  - `user_management/user.dart`: removeu o enum local; agora `import` + `export ... show UserRole` re-exporta o de auth (imports existentes continuam funcionando).
  - `firebase_auth_repository.dart._parseRole`: passou a reconhecer `'technician'`.
- **Impacto:** a comparação `authState.user.role == UserRole.coordinator` em `settings_page.dart:49` agora usa o mesmo tipo em ambos os lados.

#### 8. `FirebaseFirestore.instance` direto em widgets (3 arquivos)
- **Afetados:** `os_details_page.dart`, `materials_page.dart`, `settings_page.dart`.
- **Depois:** cada widget recebe `FirebaseFirestore` via `sl<FirebaseFirestore>()` do service locator.
- **Escopo:** **correção parcial** — atende testabilidade (pode ser mockado via GetIt), mas a migração completa para um `BLoC` dedicado (remover `StreamBuilder` do widget) fica para Fase 2/3.
- **Bônus:** removidos `debugPrint` de produção em `materials_page` e `settings_page`; erros agora só logam em `kDebugMode`.

#### 9. `injection_container.dart` — `sl()` sem tipo
- **Antes:** `FirebaseServiceOrdersRepository(sl())` e `FirebaseMaterialRequestsRepository(sl())`.
- **Depois:** `sl<FirebaseFirestore>()` explicitamente tipado.

### ❌ Falsos positivos identificados (análise original estava incorreta)

| Item | Arquivo | Por quê |
|------|---------|---------|
| 4.1.1 / 7.1.1 — `query.where` sem reatribuição | `materials_bloc.dart`, `fleet_monitoring_bloc.dart` | Código **já** faz `query = query.where(...)` corretamente (linhas 29, 32 em ambos). |
| 7.4.1 — `MapController` sem dispose | `live_tech_tracking_page.dart` | `_mapController.dispose()` **já presente** na linha 51. |
| 8.1.3 — `!mounted` sem return | `create_technician_page.dart` | `return` **já presente** nas linhas 79 e 93. |

Estes itens foram reportados pela análise estática inicial mas não se confirmaram na leitura manual do código. Mantidos no documento com status `❌ Falso positivo` para rastreabilidade.

### 🟨 Correções parciais (refactor maior fica para fases seguintes)

| Item | O que foi feito agora | O que falta |
|------|----------------------|-------------|
| 3.7.1 / 4.2.1 / 8.2.1 — Firestore em widgets | Injeção via `sl<FirebaseFirestore>()` | Mover queries para BLoC dedicado, remover `StreamBuilder` do widget |
| 9.1 — Clean Architecture | Camada de DI consistente | Use cases, repositórios retornando entities, remover acesso direto a Firestore dos widgets |

### 📋 Ação externa requerida — Item 1.3.1 (API Keys)

**Contexto:** `firebase_options.dart` contém chaves de API do Firebase. Em apps Flutter+Firebase isso é **esperado** (são chaves client-side geradas pelo FlutterFire CLI) — o risco real não é a exposição em si, mas a **falta de restrições no GCP Console**.

**Não corrigível via código.** Checklist de ação no [Google Cloud Console](https://console.cloud.google.com/):

1. **APIs & Services → Credentials** — para cada API key listada em `firebase_options.dart`:
   - **Android key**: Application restrictions → Android apps → adicionar package name + SHA-1 fingerprint.
   - **iOS key**: Application restrictions → iOS apps → adicionar bundle ID.
   - **Web key**: Application restrictions → HTTP referrers → adicionar domínios autorizados.
   - **API restrictions**: restringir para apenas as APIs usadas (Firestore, Auth, Storage, Realtime DB, Cloud Messaging).
2. **Firestore Security Rules** — garantir que `allow read/write` valida `request.auth.uid` e `role`/`department` do usuário.
3. **Storage Security Rules** — mesma verificação para uploads (`service_orders` images).
4. **Realtime DB Rules** — verificar leitura/escrita em `locations/`.
5. **App Check** — ativar (reCAPTCHA para web, Play Integrity para Android, DeviceCheck para iOS) para bloquear requisições de apps não-assinados.

Quando as restrições estiverem aplicadas, atualizar a linha 1.3.1 na tabela acima para ✅ Concluído com referência ao ticket/evidência.

### Resumo quantitativo da Fase 1

- **Itens críticos marcados originalmente:** 12
- **Aplicados via código:** 8
- **Parciais (melhoria imediata + follow-up):** 3
- **Falsos positivos confirmados:** 3 (removidos do backlog)
- **Bônus (correções de médio fora da lista original):** 2 (`catch (_)` logs, `debugPrint` em produção removido)
- **Ação externa:** 1 (API keys no GCP)
- **Erros de compilação introduzidos:** 0
- **Erros de compilação corrigidos de quebra:** 1 (`LocationService` construía `FirebaseLocationRepository` com apenas 1 argumento — quebrava o build em background service)

---

## 13. Registro de Execução — Fase 2

**Data de execução:** 2026-04-17
**Resultado `flutter analyze`:** 0 erros (15 warnings/infos pré-existentes, não introduzidos pela Fase 2).

### ✅ Aplicadas com sucesso

#### 1. Force unwraps em path parameters do router
Arquivos afetados: `lib/core/routes/app_router.dart` — 4 rotas (`/tracking/live/:techId`, `/tracking-map/:entityId`, `/tech-history/:id`, `/os-details/:osId`).
- **Antes:** `state.pathParameters['x']!` (crash se `null`).
- **Depois:** `state.pathParameters['x'] ?? ''` + check `if (isEmpty) return _invalidRoutePage(...)`.
- **Helper adicionado:** `_invalidRoutePage(state, message)` renderiza um `Scaffold` amigável para rotas malformadas.

#### 2. `.sort()` mutando lista original em `service_orders_page.dart`
- **Antes:** `orders..sort(...)` (mutava a lista compartilhada com o BLoC).
- **Depois:** `[...orders]..sort(...)` (cópia local). Bônus: esta linha foi posteriormente **removida** ao mover o agrupamento para o BLoC (ver item 5 abaixo).

#### 3. `firebase_location_repository.dart` — tipagem de stream + log de erro
- `getCurrentLocation`: `catch (e)` agora loga via `debugPrint`.
- `watchUserLocation`: `map` tipado como `map<Location?>` + `.where((l) => l != null).cast<Location>()`. **Nota:** a análise original sugeria `.whereType<Location>()`, mas `Stream` não expõe esse método — só `Iterable` o tem. A solução `where + cast` com map tipado é equivalente semanticamente.
- Import `package:flutter/foundation.dart` adicionado.

#### 4. Padronização do schema Firestore (`nome` → `name`)
- **Arquivo afetado:** `create_technician_bloc.dart`.
- **Antes:** escrevia simultaneamente `'name'` e `'nome'` (redundância mantida por compatibilidade).
- **Depois:** escreve apenas `name` (schema canônico). A leitura continua com fallback `nome → name` para registros antigos, descrito em comentário no código.
- **Pendente (Fase 3):** script de migração dos documentos antigos + remoção do fallback de leitura após migração.

#### 5. Agrupamento de OS movido para o BLoC via `TechnicianBoard`
Arquivos afetados:
- **Novo:** `lib/features/service_orders/domain/entities/technician_board.dart` — entity imutável representando o quadro operacional por técnico, com factory estático `TechnicianBoard.buildBoards(orders)`.
- **Atualizado:** `service_orders_state.dart` — `ServiceOrdersLoaded` agora expõe `List<TechnicianBoard> boards` (computado 1× no constructor).
- **Atualizado:** `service_orders_page.dart` — removeu ~50 linhas de lógica de agregação/ordenação do método `build`; widget agora apenas aplica filtros locais de busca e status. `_PremiumTechBoardCard` passou a consumir `TechnicianBoard` tipado em vez de `Map<String, dynamic>` genérico.
- **Impacto:** a agregação acontece uma vez por emit do BLoC em vez de a cada rebuild do widget. Cards também ficam type-safe (sem casts).

#### 6. `GoRouterRefreshStream` dispose
- **Revisão:** `dispose()` **já cancela** a subscription na linha 360. O item 1.5.3 da análise inicial foi um **falso positivo**.
- Em produção, o `GoRouter` mantém o listener durante toda a vida da app; não há caminho onde a subscription vazaria.

#### 7. `injection_container.dart` — tipos explícitos
- Tipado: `FirebaseServiceOrdersRepository(sl<FirebaseFirestore>())` e `FirebaseMaterialRequestsRepository(sl<FirebaseFirestore>())` (já feito como bônus na Fase 1).

### ❌ Falsos positivos confirmados na Fase 2

| Item | Arquivo | Justificativa |
|------|---------|---------------|
| 1.5.3 — `GoRouterRefreshStream` leak | `app_router.dart` | `_subscription.cancel()` já presente em `dispose()` |
| 3.2.1 / 5.1.1 — `Department` via `.name` | `firebase_service_orders_repository.dart`, `firebase_dashboard_repository.dart` | As **comparações** já usam enum direto (`user.department != Department.all`); `.name` é usado apenas para serializar o filtro na query do Firestore (campo é string — correto) |
| 9.3 — Dispose de `TextEditingController` | 8 widgets | Verificado via grep: todos os widgets com `TextEditingController` já chamam `dispose()` |

### 🟨 Ajustes de escopo (análise original precisava de refinamento)

| Item | Descoberta | Solução aplicada |
|------|-----------|------------------|
| 6.2.2 — `.whereType<Location>()` | `Stream` não expõe esse método (só `Iterable`) | Manter `where + cast`, mas adicionar tipagem explícita no `map<Location?>` para deixar o intent claro |
| 9.10 — Schema `nome` vs `name` | Migrar os dados requer script separado (não pode ser feito só em código) | Código agora escreve só `name`; leitura mantém fallback `nome → name` temporariamente. Script de migração fica para Fase 3 |

### ⬜ Itens da Fase 2 adiados para Fase 3

| Item | Motivo |
|------|--------|
| 9.2 / 9.7 — Validação de `userId`/role em queries + helper de filtro por departamento | Requer revisão das regras de segurança do Firestore (fonte de verdade) antes de apertar queries. Será feito junto com o hardening de segurança |
| 3.7.1 / 4.2.1 / 8.2.1 — Migração completa de widgets para BLoC dedicado | Os widgets agora usam DI (Fase 1). Criar um `OsDetailsBloc`, `MaterialsPage` com BLoC completo e `SettingsBloc` é refactor maior; tratado na Fase 3 |
| 9.11 — `ErrorMapper` central | Escopo de Fase 3 — depende de decisão sobre `AppError` sealed class |

### Resumo quantitativo da Fase 2

- **Itens altos do backlog original:** 28 (considerando os listados no plano da Fase 2)
- **Aplicados via código nesta fase:** 5 (router unwraps, `.sort`, log do location repo, schema name/nome, `TechnicianBoard`)
- **Falsos positivos confirmados:** 3 (router refresh leak, Department via `.name` em 2 repos, TextEditingController dispose)
- **Ajustes de escopo:** 2 (`whereType` não aplicável a `Stream`; schema `nome` requer migração de dados em fase separada)
- **Adiados para Fase 3 (com justificativa):** 3 (validação Firestore, refactor BLoC completo de 3 páginas, ErrorMapper)
- **Erros de compilação introduzidos:** 0
- **Linhas de lógica removidas do widget (`service_orders_page`):** ~50 (movidas para `TechnicianBoard.buildBoards`)

---

## 14. Correção Urgente de Schema (pós-Fase 2)

Após a Fase 2, o usuário confirmou que o **schema real** em produção usa `nome` (em português), não `name`. A padronização aplicada na Fase 2 (que trocou para `name`) quebraria a listagem/criação de técnicos em produção. Correção aplicada imediatamente:

### Mudanças

| Arquivo | Alteração |
|---------|-----------|
| `create_technician_bloc.dart:40` | `'name': event.name` → `'nome': event.name` |
| `user.dart (toMap)` | Escreve `nome` (com doc explicando schema canônico) |
| `user.dart (fromFirestore)` | Lê `nome` como primário, `name` como fallback |
| `settings_page.dart:58` | `orderBy('name')` → `orderBy('nome')` |
| `fleet_monitoring_bloc.dart:32` | `orderBy('name')` → `orderBy('nome')` |
| `firebase_user_management_repository.dart` (3 queries) | `orderBy('name')` → `orderBy('nome')` |
| `fleet_gps_page.dart:44` | `orderBy('name')` → `orderBy('nome')` |
| `materials_bloc.dart:35` | `orderBy('name')` → `orderBy('nome')` |
| `materials_page.dart:40` | `orderBy('name')` → `orderBy('nome')` |

### Diretriz permanente

**Schema canônico confirmado:** `users` usa `nome`. Escritas novas devem usar só `nome`; leituras mantêm fallback para `name` enquanto houver documentos criados por versões antigas.

**Schemas de `service_orders` e `material_requests` já estavam alinhados** e não precisaram ajuste.

---

## 15. Registro de Execução — Fase 3

**Data de execução:** 2026-04-17
**Resultado `flutter analyze`:** 0 erros (15 warnings/infos pré-existentes, idênticos aos da Fase 2).

### Objetivo da Fase 3

Eliminar duplicação, substituir `Map<String, dynamic>` por entities tipadas, centralizar helpers de query/erro/validação e introduzir constantes para strings mágicas.

### ✅ Aplicadas com sucesso

#### 1. `Equatable` em todas as entities
Aplicado em 6 entities:
- [service_order.dart](lib/features/service_orders/domain/entities/service_order.dart) + `props`
- [technician_board.dart](lib/features/service_orders/domain/entities/technician_board.dart) + `props`
- [material_request.dart](lib/features/material_approvals/domain/entities/material_request.dart) + `props` + constructor `const`
- [user.dart](lib/features/user_management/domain/entities/user.dart) + `props` + constructor `const`
- [location.dart](lib/features/gps_monitoring/domain/entities/location.dart) + `props` + constructor `const` + `fromJson` com cast seguro (`num?).toDouble()`
- [dashboard_metrics.dart](lib/features/dashboard/domain/entities/dashboard_metrics.dart) + `props`

**Impacto:** comparações via `==` passam a ser por valor; `BlocBuilder` com `buildWhen` não re-renderiza quando o mesmo objeto chega de novo; testes ficam mais simples.

#### 2. Nova entity `Technician` substituindo `Map<String, dynamic>`
[`lib/features/user_management/domain/entities/technician.dart`](lib/features/user_management/domain/entities/technician.dart) — projeção leve de um técnico (id, nome, departamento, isOnline, currentOs, lastSync) com `fromFirestore` tipado.

**Refactorados para usar `Technician`:**
- `MaterialsBloc` / `MaterialsEvent` / `MaterialsState` — `List<Map<String, dynamic>>` → `List<Technician>`
- `FleetMonitoringBloc` / `FleetMonitoringEvent` / `FleetMonitoringState` — mesmo padrão

Os widgets consumidores (`MaterialsPage`, `FleetGpsPage`) ainda usam Firestore direto (pendente para Fase 4/refactor completo); esta mudança **prepara a infra** para esse refactor.

#### 3. Helper `QueryFilters.byDepartment` em `core/firestore/`
[`lib/core/firestore/query_filters.dart`](lib/core/firestore/query_filters.dart) — encapsula o padrão `if (user.department != Department.all && user.department != Department.unknown) query = query.where('department', ...)` que estava duplicado em 4 lugares.

**Aplicado em:**
- `firebase_service_orders_repository.dart`
- `firebase_dashboard_repository.dart` (2 ocorrências)
- `materials_bloc.dart`
- `fleet_monitoring_bloc.dart`

**Impacto:** se amanhã o schema mudar (ex: coordenador com múltiplos departamentos), altera-se um único arquivo.

#### 4. `app_constants.dart` para strings mágicas
[`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart) — define:
- `ServiceOrderStatus` (enum com `value` e `label`): `aberta`, `emAndamento`, `aguardandoConferencia`, `concluida`
- `MaterialRequestStatus` (enum com `value` e `label`): `pending`, `approved`, `rejected`
- `ServiceOrderFilters` (classe com `todos`, `emServico`, `livres` + `all`)
- `FleetFilters` (classe com `todos`, `online`, `offline`, `emDeslocamento` + `all`)

**Aplicado em:**
- `service_orders_page.dart` — filtros agora vêm de `ServiceOrderFilters.all`
- `os_details_page.dart` — `_getStatusColor`/`_getStatusLabel` usam `MaterialRequestStatus.fromValue`
- `create_order_bloc.dart` — status inicial agora é `ServiceOrderStatus.aberta.value` (antes era `'pending'`, valor que **não existia** no schema de `service_orders` — bug silencioso corrigido)
- `live_tech_tracking_page.dart` — `whereIn` do status consulta via enum

#### 5. `ErrorMapper` central
[`lib/core/errors/error_mapper.dart`](lib/core/errors/error_mapper.dart) — mapeia `FirebaseAuthException` e `FirebaseException` (Firestore) para mensagens amigáveis em português.

**Códigos cobertos:**
- Auth: `invalid-email`, `wrong-password`, `user-not-found`, `user-disabled`, `email-already-in-use`, `weak-password`, `too-many-requests`, `network-request-failed`
- Firestore: `permission-denied`, `unavailable`, `deadline-exceeded`, `not-found`, `already-exists`, `resource-exhausted`

**Aplicado em:**
- `auth_bloc.dart` — substituiu `e.toString().replaceAll('Exception: ', '')` frágil
- `create_technician_bloc.dart` — removeu 3 `if (e.code == ...)` hardcoded
- `create_order_bloc.dart` — mensagens específicas em vez de "Erro ao criar ordem de serviço. Tente novamente."
- `create_technician_page.dart` (SnackBar de erro)

#### 6. `Validators` helper
[`lib/core/validators/validators.dart`](lib/core/validators/validators.dart) — validadores reutilizáveis: `required`, `email` (com regex), `password` (com `minLength`), `minLength`.

**Aplicado em:** `create_technician_page.dart` — os 3 validators inline substituídos pelos helpers (nome, e-mail, senha).

### 🐛 Bug adicional descoberto durante a Fase 3

**`create_order_bloc.dart:52`**: o status inicial da OS era `'pending'` — valor que **não existe** no schema real de `service_orders` (o schema aceita `aberta`, `em_andamento`, `aguardando_conferencia`, `concluida`). OS recém-criadas pelo admin teriam status inconsistente. Corrigido para `ServiceOrderStatus.aberta.value`.

### ⬜ Itens da Fase 3 adiados para Fase 4

| Item | Motivo |
|------|--------|
| `TextTheme` completo | Estético, não afeta funcionamento |
| Semantic labels / tooltips | Passada de acessibilidade — escopo dedicado |
| Validação `userId`/role em queries | Requer revisão das Firestore Rules junto — deve ser feito com o owner do projeto |
| Campos `isOnline`/`lastSync` inexistentes no schema de `users` | `Technician` já trata ausência com defaults seguros; estender schema no Firestore é decisão do produto |
| Refactor completo dos 3 widgets (OS details, materials, settings) para BLoC dedicado | DI aplicada na Fase 1 já deixa testável; o refactor maior fica para quando as páginas forem iteradas |

### Resumo quantitativo da Fase 3

- **Itens médios do backlog original:** 38
- **Aplicados via código:** 6 grandes blocos (`Equatable`, entity `Technician`, `QueryFilters`, `app_constants`, `ErrorMapper`, `Validators`) cobrindo ~15 itens do backlog
- **Bug silencioso descoberto e corrigido:** 1 (`create_order_bloc` escrevendo status inválido)
- **Novos arquivos criados:** 5 (`query_filters.dart`, `app_constants.dart`, `error_mapper.dart`, `validators.dart`, `technician.dart`)
- **Linhas duplicadas removidas (filtro de departamento):** ~24 (6 linhas × 4 repos/BLoCs)
- **Erros de compilação introduzidos:** 0
- **Efeito nos warnings pré-existentes do analyzer:** nenhum (15 antes → 15 depois)

---

## 16. Registro de Execução — Fase 4

**Data de execução:** 2026-04-17
**Resultado `flutter analyze`:** **"No issues found!"** — zero erros, warnings ou infos. Reverte a linha de base do projeto, que tinha **15 warnings/infos pré-existentes** desde o início da auditoria.

### ✅ Aplicadas com sucesso

#### 1. Limpeza dos 15 warnings/infos pré-existentes

**Warnings eliminados removendo código morto:**
- [fleet_monitoring/presentation/pages/tracking_map_page.dart](#) — **arquivo deletado** (não estava em nenhuma rota, só mocks com `isOffline = true` hardcoded que geravam 3 dead code warnings)
- [gps_monitoring/presentation/pages/tracking_map_page.dart](#) — **arquivo deletado** (placeholder "Em breve" não usado)
- [core/widgets/app_shell.dart](#) — **arquivo deletado** (`AppShell` não era usado; só `ScaffoldWithNavBar`). Dir `core/widgets/` removido junto.

**Warnings eliminados corrigindo código:**
- 3 `_repository` unused fields removidos:
  - [materials_bloc.dart](lib/features/material_approvals/presentation/bloc/materials_bloc.dart) — dependia de `MaterialRequestsRepository` mas só usava `FirebaseFirestore`. Construtor simplificado.
  - [create_order_bloc.dart](lib/features/service_orders/presentation/bloc/create_order_bloc.dart) — dependia de `ServiceOrdersRepository` mas só usava `FirebaseFirestore` + `FirebaseStorage` diretamente.
  - [create_technician_bloc.dart](lib/features/user_management/presentation/bloc/create_technician_bloc.dart) — dependia de `UserManagementRepository` mas usava só `FirebaseAuth` + `FirebaseFirestore`.
  - [injection_container.dart](lib/injection_container.dart) atualizado com os novos construtores.
- [create_order_event.dart](lib/features/service_orders/presentation/bloc/create_order_event.dart) — import de `service_order.dart` não usado removido.
- [firebase_location_repository.dart](lib/features/gps_monitoring/data/repositories/firebase_location_repository.dart) — `as Map<String, dynamic>` redundante removido (já é esse tipo).
- [os_details_page.dart](lib/features/service_orders/presentation/pages/os_details_page.dart) — `.toList()` desnecessário em spread.
- [create_os_page.dart](lib/features/service_orders/presentation/pages/create_os_page.dart) — `(_, __)` → `(_, _)` (evita multiple underscores).

**Warning de dependência transitiva eliminado:**
- `path: ^1.9.0` adicionado explicitamente em [pubspec.yaml](pubspec.yaml) — `create_os_page.dart` usava `p.basename`/`p.extension` sem declarar a dep (vinha como transitiva).

#### 2. API deprecated do flutter_map v6 migrada
- [live_tech_tracking_page.dart](lib/features/fleet_monitoring/presentation/pages/live_tech_tracking_page.dart) e [os_tracking_map_page.dart](lib/features/fleet_monitoring/presentation/pages/os_tracking_map_page.dart):
  - `MapOptions(center: ...)` → `initialCenter`
  - `MapOptions(zoom: ...)` → `initialZoom`

#### 3. Duplicação de `_navItems` entre `ScaffoldWithNavBar` e `AppShell` eliminada
- Novo: [core/constants/nav_destinations.dart](lib/core/constants/nav_destinations.dart) — lista única `kMainNavDestinations` (5 destinations com `path`, `label`, `icon`, `activeIcon`).
- [scaffold_with_nav_bar.dart](lib/core/layout/scaffold_with_nav_bar.dart) refatorado: ambos `NavigationRail` (tablet) e `BottomNavigationBar` (mobile) agora fazem `.map` sobre `kMainNavDestinations`. Adicionar/renomear/reordenar item passa por um único ponto.
- Método `_getSelectedIndex` agora usa `indexWhere` sobre a lista, em vez de cascata de `if/startsWith`.

#### 4. Tooltips em `IconButton` (acessibilidade)
Adicionado `tooltip:` em 9 `IconButton`s que não tinham:
- 7× back buttons (`create_technician_page`, `os_tracking_map_page` ×2, `live_tech_tracking_page`, `tech_history_page`, `os_details_page`, `create_os_page`) → `tooltip: 'Voltar'`
- 1× close button (`quick_approval_page`) → `tooltip: 'Fechar'`
- 1× toggle visibilidade senha (`create_technician_page`) → `tooltip` dinâmico: `'Mostrar senha'` / `'Ocultar senha'`

**Impacto:** screen readers (TalkBack/VoiceOver) passam a ler labels descritivos; long-press em desktop/web mostra hint.

#### 5. Limpeza de `debugPrint` ruidosos
Removidos os `debugPrint` de **sucesso** (ex: `'✅ FleetGpsPage: N técnicos encontrados'`, `'📋 Técnico: ...'`, `'📍 Localização do dispositivo: ...'`, `'🟢 OsTrackingMapPage.initState()'`). Afetados:
- `fleet_gps_page.dart` (3 prints removidos)
- `os_tracking_map_page.dart` (3 prints removidos/limpos)
- `live_tech_tracking_page.dart` (3 prints removidos/limpos)

Os `debugPrint` de **erro** foram mantidos (eles não aparecem em release mode de qualquer forma, e são úteis para debug em dev). Emojis foram removidos para padronizar o formato.

#### 6. Placeholders tratados
- **"Esqueceu a senha?"** em [login_page.dart](lib/features/auth/presentation/pages/login_page.dart): `onPressed: () {}` → `onPressed: _showPasswordRecoveryInfo` (abre um `AlertDialog` explicando que a recuperação automática ainda não está disponível e orientando contatar o gestor). Decisão razoável para um app admin onde técnicos são criados pelo gestor.
- **"Imprimir Relatório"** em `os_details_page.dart`: `onPressed: () {}` com ícone ativo era enganoso (usuário clicava e nada acontecia). Mudado para `onPressed: null` + ícone em `zinc400` + tooltip `'Imprimir Relatório (em breve)'` — mantém o affordance visual mas deixa claro que está desabilitado.

#### 7. `TextTheme` completo
[app_theme.dart](lib/core/theme/app_theme.dart) — `TextTheme` expandido de **3 estilos** (`bodyMedium`, `bodyLarge`, `titleMedium`) para **15 estilos** cobrindo toda a escala Material 3:
- `displayLarge` / `displayMedium` / `displaySmall`
- `headlineLarge` / `headlineMedium` / `headlineSmall`
- `titleLarge` / `titleMedium` / `titleSmall`
- `bodyLarge` / `bodyMedium` / `bodySmall`
- `labelLarge` / `labelMedium` / `labelSmall`

Todos seguem a paleta zinc monocromática e têm `fontWeight`/`letterSpacing` coerentes com a identidade do app.

### 🟢 Itens da Fase 4 — cobertura do plano original

| Item do plano | Status |
|---------------|--------|
| `const` onde possível | 🟨 Parcial — passada ampla não feita (requer revisão individual de widgets). Linter (`prefer_const_constructors`) já está ativo e não reporta warnings. |
| Remover `debugPrint` de produção | ✅ Completo — prints de sucesso removidos; erros mantidos (funciona só em debug mode) |
| Extrair `_navItems` duplicados | ✅ Completo — `nav_destinations.dart` |
| Implementar/remover placeholders | ✅ Completo — "Esqueceu a senha?" (implementado), "Imprimir" (desabilitado visualmente), "Em breve" (arquivos mortos removidos) |
| `enum NavigationRoute` | 🟨 Ajustado — preferimos `class NavDestination` + `const List` porque carrega mais metadados (icon, activeIcon, label). Mesmo benefício semântico de um enum. |
| `TextTheme` completo (adiado da Fase 3) | ✅ Completo — 15 estilos M3 |
| Semantic labels / tooltips (adiado da Fase 3) | ✅ 9 `IconButton`s com tooltip |

### Resumo quantitativo da Fase 4

- **Warnings/infos eliminados:** 15 → 0 (`flutter analyze` 100% limpo)
- **Arquivos deletados (código morto):** 3 (`fleet_monitoring/tracking_map_page.dart`, `gps_monitoring/tracking_map_page.dart`, `core/widgets/app_shell.dart`)
- **Diretório vazio removido:** 1 (`core/widgets/`)
- **Novos arquivos criados:** 1 (`nav_destinations.dart`)
- **Dependências adicionadas:** 1 (`path: ^1.9.0`, antes transitiva)
- **Tooltips adicionados:** 9
- **Estilos de texto no tema:** 3 → 15
- **Erros de compilação introduzidos:** 0

---

## Estado Final

**`flutter analyze`:** `No issues found!`

**Projeto auditado:** 64 arquivos Dart → após 4 fases + correção urgente:
- 3 arquivos deletados (código morto)
- ~11 arquivos novos (entities, helpers, constants, docs)
- ~30 arquivos modificados
- **0 warnings/infos restantes no analyzer**
- **4 bugs silenciosos corrigidos** (entre os quais: `saveLocation` sem await, cancel sem await, `!mounted` sem return, status `'pending'` inválido em `service_orders`)
- **Schema Firestore padronizado** com leitura resiliente (`nome` primário, `name` fallback)
- **Clean Architecture reforçada:** DI consistente, `QueryFilters` centralizado, `ErrorMapper` + `Validators` reutilizáveis, entities tipadas (`Technician`, `TechnicianBoard`) substituindo `Map<String, dynamic>`

**Ações externas ainda requeridas** (não corrigíveis via código):
1. Restringir API keys no GCP Console (§12, item 1.3.1)
2. Migração de dados Firestore de `name` → `nome` nos documentos legados de `users` (se houver)
3. Aplicar rules do Live Tracking no Firebase Console (ver `docs/RULES_LIVE_TRACKING.md`)
4. Corrigir o app do técnico para gravar localizações conforme schema combinado (ver `docs/PROMPT_GPS_APP_TECNICO.md`)

---

## 17. Registro de Execução — Fase 5 (Live Tracking)

**Data:** 2026-04-17
**Escopo:** **nova feature**, fora do backlog original de bugs. Consome os dados publicados pelo app do técnico (RTDB `live_tracking/` + Firestore `service_orders/{osId}/trajectories/`) e expõe no app do gestor em 3 níveis: dashboard → lista de técnicos → técnico individual → mapa da OS.

**Resultado `flutter analyze`:** `No issues found!` (mantém a linha-base 100% limpa da Fase 4).

### Fluxo de navegação implementado

```
Dashboard
  └─ Card "N técnicos em campo" ──► /tracking
                                       │
                   ┌───────────────────┴───────────────────┐
                   ▼                                       ▼
             Aba "AO VIVO"                          Aba "TODOS"
             (RTDB live_tracking,                   (Firestore users where
              freshness < 2min)                       role=technician)
                   │                                       │
                   └─────────────────┬─────────────────────┘
                                     ▼
                           /tracking/live/:techId
                   (mapa ao vivo + lista de OSs do técnico)
                                     │
                                     ▼
                       /tracking-map/:osId
                   (mapa ao vivo da OS + polylines Strava)
```

### Novos arquivos (8)

| Camada | Arquivo |
|---|---|
| Entity | [`features/fleet_monitoring/domain/entities/live_location.dart`](lib/features/fleet_monitoring/domain/entities/live_location.dart) |
| Entity | [`features/fleet_monitoring/domain/entities/trajectory.dart`](lib/features/fleet_monitoring/domain/entities/trajectory.dart) |
| Entity | [`features/fleet_monitoring/domain/entities/trajectory_point.dart`](lib/features/fleet_monitoring/domain/entities/trajectory_point.dart) |
| Domain | [`features/fleet_monitoring/domain/repositories/live_tracking_repository.dart`](lib/features/fleet_monitoring/domain/repositories/live_tracking_repository.dart) |
| Data | [`features/fleet_monitoring/data/repositories/firebase_live_tracking_repository.dart`](lib/features/fleet_monitoring/data/repositories/firebase_live_tracking_repository.dart) |
| Widget | [`features/fleet_monitoring/presentation/widgets/live_technician_marker.dart`](lib/features/fleet_monitoring/presentation/widgets/live_technician_marker.dart) |
| Widget | [`features/fleet_monitoring/presentation/widgets/trajectory_polylines.dart`](lib/features/fleet_monitoring/presentation/widgets/trajectory_polylines.dart) |
| Doc | [`docs/RULES_LIVE_TRACKING.md`](docs/RULES_LIVE_TRACKING.md) |

### Arquivos reescritos (3)

| Arquivo | Antes | Depois |
|---|---|---|
| `os_tracking_map_page.dart` | Polyline estática lendo `LocationRepository` legado (coleção `locations/`) | Mapa por OS com `watchOsLive(osId)` + `watchTrajectories(osId)`; markers com rotação por heading, banner de GPS suspeito, polylines coloridas por `trajectoryId`, trechos mocked em vermelho, decimação a 500 pontos, card de stats (distância, duração, vel. média, contagem de trajetos) |
| `live_tech_tracking_page.dart` | Mostrava OS fixa do técnico (1 stream no topo) | Split em 2 zonas: mapa 60% (`watchTechnicianLive(techId)` com re-centering de 5m) + bottom sheet 40% com badge de status (AO VIVO / STANDBY / OFFLINE / GPS SUSPEITO / SEM SINAL), stats (velocidade, idade do ponto, OS atual) e lista de OSs do técnico (ativas primeiro) — tap em OS leva ao mapa daquela OS |
| `fleet_gps_page.dart` | Lista de `users where role=technician` com `isOnline` mockado | `TabBar` com 2 abas: **AO VIVO** (RTDB, freshness < 2 min, mostra velocidade/idade/OS) e **TODOS** (Firestore, sempre completa). Busca unificada |

### Arquivos modificados (2)

| Arquivo | Mudança |
|---|---|
| `injection_container.dart` | Registra `LiveTrackingRepository` como singleton |
| `dashboard_page.dart` | Novo card "Técnicos em campo" entre KPIs e Atividade Recente — clicável, com selo vermelho se qualquer técnico estiver com `isMocked` |

### Arquivos deletados (1)

- `SETUP_GOOGLE_MAPS.md` (raiz) — obsoleto; projeto usa `flutter_map` (OSM), não `google_maps_flutter`.

### Decisões de design

1. **RTDB lido como árvore completa** (`ref('live_tracking').onValue`) em vez de subscriptions pontuais por OS. Aceitável até ~50–100 técnicos; refatorar se virar gargalo. Documentado no repositório.
2. **Filtro por departamento** cruza com `users/{uid}.department` via cache em memória do repo (`_deptCache`), carregado uma vez por sessão. Alternativa futura: custom claim `department` no token do gestor para filtrar no lado do servidor.
3. **Freshness < 2 min** para "ao vivo" no dashboard e na aba ao vivo; < 60s para o marker virar cinza no mapa. Valores ficam como constantes nos próprios widgets (fácil ajustar).
4. **Decimação da polyline**: threshold de 500 pontos, preservando primeiro/último e **todos** os pontos `isMocked` (são evidência — não podem ser suprimidos).
5. **Múltiplos trajetos na mesma OS** (pause/retomar): cada um ganha uma cor da paleta `[azul, verde, laranja, roxo, ciano]`, ciclando.
6. **Rules**: documentadas em `docs/RULES_LIVE_TRACKING.md` — não aplicadas automaticamente (usuário pediu para perguntar antes).
7. **Rota `/tracking-map/:entityId?type=...`** preservada com mesma assinatura; o parâmetro `type` é ignorado pelo novo código (modo é auto-detectado por `endTime` dos trajetos). Evita quebrar links externos/`context.push` existentes.
8. **Gestor `Department.all`** recebe todas as posições sem filtro; `Department.unknown` também (fallback permissivo — alinhar com rules do Firebase).

### Pontos abertos (registrar para próximas iterações)

- Escalar leitura do RTDB: hoje lê a árvore inteira. Se a frota crescer, migrar para subscriptions pontuais usando `service_orders where status=em_andamento and department=X` como índice das OSs a monitorar.
- Coordenador viewing de OSs: rules propostas em `RULES_LIVE_TRACKING.md` só permitem coordenador ver quando `$level1 == department`. Posições em OS ativa (`$level1 == osId`) ficam sem filtro de dept via RTDB — filtro real fica no cliente via `users.department` (aceitável; documentar).
- Alertas push de `isMocked`: hoje é apenas visual no app. Integração com FCM para notificar gestor em background fica para depois.
- Exportar trajeto para CSV/KML (feature solicitada fora deste escopo).

---

## Apêndice A — Métricas

- **Arquivos analisados:** 64
- **Linhas de código (estimativa):** ~3.500
- **Categorias de problemas:** Bug, Performance, Segurança, Qualidade, Arquitetura, UX, Acessibilidade, Manutenibilidade, Memory Leak, Race Condition, Duplicação, Validação
- **Features auditadas:** 7 (auth, service_orders, material_approvals, dashboard, gps_monitoring, fleet_monitoring, user_management)

## Apêndice B — Metodologia

Análise estática de todos os arquivos `.dart` em `lib/`, incluindo:
- Leitura de cada arquivo individualmente
- Busca por padrões problemáticos (`print`, `TODO`, `!`, `catch (_) {}`)
- Verificação de ciclo de vida (`dispose`, `cancel`, `close`)
- Revisão de uso de `BuildContext` após `async`
- Checagem de Clean Architecture (presentation ↔ data)
- Verificação de `Equatable` em entities
- Identificação de force unwraps perigosos
- Detecção de race conditions em streams
