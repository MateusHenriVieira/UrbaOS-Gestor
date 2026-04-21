# UrbaOS - Gestor | Documentação Técnica Completa

**Data de Atualização:** 14 de abril de 2026  
**Versão:** 1.0.0+1  
**Nível:** Enterprise | Production-Ready  
**Audiência:** Equipe de Manutenção, DevOps, Backend Engineers

---

## Índice

1. [Resumo Executivo](#resumo-executivo)
2. [Características Técnicas](#características-técnicas)
3. [Stack Tecnológico](#stack-tecnológico)
4. [Arquitetura da Aplicação](#arquitetura-da-aplicação)
5. [Estrutura de Diretórios](#estrutura-de-diretórios)
6. [Modelo de Dados Firebase](#modelo-de-dados-firebase)
7. [Features Detalhadas](#features-detalhadas)
8. [Rotas e Navegação](#rotas-e-navegação)
9. [Fluxo de Dados Completo](#fluxo-de-dados-completo)
10. [Segurança e Controle de Acesso](#segurança-e-controle-de-acesso)
11. [Padrões de Design Implementados](#padrões-de-design-implementados)
12. [Estratégia Offline-First](#estratégia-offline-first)
13. [Gerenciamento de Estado](#gerenciamento-de-estado)
14. [Instruções de Manutenção](#instruções-de-manutenção)
15. [Troubleshooting](#troubleshooting)

---

## Resumo Executivo

**UrbaOS - Gestor** é uma aplicação mobile e web (Flutter) para gestão operacional de serviços urbanos, desenvolvida com princípios enterprise-grade e arquitetura limpa. A aplicação permite que **Gerentes e Coordenadores** supervisionem ordens de serviço, aprovem requisições de materiais, rastreiem técnicos em tempo real via GPS, e gerenciem usuários e suas alocações.

### Objetivos Principais

- **Gestão Centralizada**: Dashboard unificado com métricas em tempo real
- **Rastreamento de Campo**: Monitoramento GPS de técnicos e ordens de serviço
- **Aprovação de Materiais**: Fluxo de aprovação inteligente para requisições
- **Controle de Acesso**: Separação de responsabilidades (Manager vs Coordinator)
- **Offline-First**: Funcionamento parcial sem internet (cache persistente)
- **Escalabilidade**: Arquitetura preparada para crescimento

---

## Características Técnicas

### Plataformas Suportadas

| Plataforma | Status | Versão Mínima | Notas |
|-----------|--------|---------------|-------|
| iOS | ✅ Produção | 12.0+ | Testado em iPhone 13+ |
| Android | ✅ Produção | API 21+ | Testado em Android 10+ |
| Web | ✅ Suporte Experimental | Chrome 90+ | Dashboard responsivo |
| macOS | ⚠️ Em Desenvolvimento | 10.15+ | Build disponível, não testado |
| Windows | ⚠️ Em Desenvolvimento | 10+ | Build disponível, não testado |
| Linux | ⚠️ Em Desenvolvimento | Ubuntu 20.04+ | Build disponível, não testado |

### Características-Chave

- ✅ **Real-Time Streaming**: WebSocket via Firestore para dados sincronizados
- ✅ **Offline Support**: Cache persistente com sincronização automática
- ✅ **GPS Tracking**: Localização em tempo real com histórico
- ✅ **Role-Based Access**: Controle granular por função de usuário
- ✅ **Multi-Department**: Segregação de dados por departamento
- ✅ **Photo Capture**: Captura e upload automático de imagens
- ✅ **Responsive Design**: Adaptável a diferentes tamanhos de tela
- ✅ **Dark Mode**: Suporte a tema claro/escuro
- ✅ **Internationalização**: Suporte para pt_BR com `intl` package

---

## Stack Tecnológico

### Core Framework

```yaml
Framework: Flutter v3.11.4+
Language: Dart v3.11.4+
Backend: Firebase (Multi-Service)
```

### Dependências Críticas

#### Backend & Data

| Package | Versão | Uso | Crítico |
|---------|--------|-----|---------|
| `firebase_core` | 4.6.0 | Inicialização Firebase | 🔴 SIM |
| `firebase_auth` | 6.3.0 | Autenticação & Custom Claims | 🔴 SIM |
| `cloud_firestore` | 6.2.0 | Database NoSQL (Realtime) | 🔴 SIM |
| `firebase_storage` | 13.2.0 | Armazenamento de arquivos | 🟡 NÃO |

#### State Management & Architecture

| Package | Versão | Padrão | Escopo |
|---------|--------|--------|--------|
| `flutter_riverpod` | 2.5.1 | Provider/Riverpod | Considerado (não implementado) |
| `flutter_bloc` | 8.1.2 | BLoC Pattern | **IMPLEMENTADO** |
| `get_it` | 7.4.0 | Service Locator/DI | **Injeção de Dependências** |

#### Navigation

| Package | Versão | Propósito |
|---------|--------|-----------|
| `go_router` | 14.0.0 | Roteamento declarativo & deep linking |

#### Maps & Location

| Package | Versão | Funcionalidade | Nota |
|---------|--------|----------------|------|
| `google_maps_flutter` | 2.6.0 | Integração Google Maps | Requer API Key |
| `geolocator` | 12.0.0 | Acesso ao GPS do dispositivo | Requer permissões |
| `geocoding` | 3.0.0 | Reverse geocoding (coordenadas → endereço) | Opcional |
| `flutter_background_service` | 5.0.5 | Serviço background para tracking | Requer setup nativo |

#### UI & UX

| Package | Versão | Propósito |
|---------|--------|-----------|
| `equatable` | 2.0.6 | Igualdade de valores em BLoCs |
| `intl` | 0.20.0 | Formatação de datas/números em pt_BR |
| `image_picker` | 1.0.0 | Seleção de fotos da galeria/câmera |

#### Linting & Code Quality

| Package | Versão | Propósito |
|---------|--------|-----------|
| `flutter_lints` | 6.0.0 | Análise estática & lint rules |

---

## Arquitetura da Aplicação

### Padrão: Clean Architecture + BLoC

```
┌─────────────────────────────────────────────────┐
│         UI Layer (Presentation)                  │
│  ┌───────────────────────────────────────────┐  │
│  │  Pages (Stateless/Stateful)               │  │
│  │  - DashboardPage, ServiceOrdersPage, etc. │  │
│  └───────────────────────────────────────────┘  │
│         ↓ (Consome Estados & Eventos)            │
│  ┌───────────────────────────────────────────┐  │
│  │  BLoCs (State Management)                 │  │
│  │  - DashboardBloc, ServiceOrdersBloc, etc. │  │
│  └───────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│  Domain Layer (Business Logic)                   │
│  ┌───────────────────────────────────────────┐  │
│  │  Use Cases (não implementados explicitamente) │
│  │  - Repositories (Abstrações)              │  │
│  │    * AuthRepository                       │  │
│  │    * ServiceOrdersRepository              │  │
│  │    * MaterialRequestsRepository           │  │
│  │    * UserManagementRepository             │  │
│  │    * LocationRepository                   │  │
│  └───────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│  Data Layer (Data Access)                        │
│  ┌───────────────────────────────────────────┐  │
│  │  Repositories Implementation (Firebase)    │  │
│  │  - FirebaseAuthRepository                 │  │
│  │  - FirebaseServiceOrdersRepository        │  │
│  │  - Etc.                                   │  │
│  └───────────────────────────────────────────┘  │
│         ↓ (Consome APIs)                         │
│  ┌───────────────────────────────────────────┐  │
│  │  External Services                         │  │
│  │  - Firebase Auth, Firestore, Storage      │  │
│  │  - Google Maps API, Geolocator            │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Injeção de Dependências (GetIt)

O padrão **Service Locator** via `get_it` centraliza todas as dependências em `lib/injection_container.dart`:

#### Singletons (Instância Única - Persistem)
- `FirebaseAuth` - Gerenciador de autenticação
- `FirebaseFirestore` - Database
- `FirebaseStorage` - Armazenamento
- `AuthRepository` - Repositório de autenticação
- `AuthBloc` - Estado global de autenticação

#### Factories (Instância Nova por Requisição)
- `DashboardBloc` - Novo ao acessar `/dashboard`
- `ServiceOrdersBloc` - Novo ao acessar `/os`
- `MaterialsBloc` - Novo ao acessar `/materials`
- `FleetMonitoringBloc` - Novo ao acessar `/tracking`
- `CreateOrderBloc` - Novo ao acessar `/create-os`
- `CreateTechnicianBloc` - Novo ao acessar `/create-technician`

**Benefício**: Libera memória quando usuário sai da tela (Factory) vs mantém estado global (Singleton).

---

## Estrutura de Diretórios

```
urbaos_admin/
├── lib/
│   ├── main.dart                          # Ponto de entrada da app
│   ├── firebase_options.dart              # Configurações Firebase (auto-gerado)
│   ├── injection_container.dart           # Injeção de dependências (GetIt)
│   │
│   ├── core/                              # Camada compartilhada
│   │   ├── constants/                     # Constantes globais
│   │   ├── errors/                        # Exceções customizadas
│   │   ├── layout/                        # Widgets de layout reutilizáveis
│   │   │   └── scaffold_with_nav_bar.dart # Bottom navigation compartilhada
│   │   ├── network/                       # Configurações de rede (remoto)
│   │   ├── routes/                        # Roteamento central
│   │   │   └── app_router.dart            # Definição de todas as rotas (GoRouter)
│   │   ├── theme/                         # Design System & Tema
│   │   │   └── app_theme.dart             # Cores, tipografia, componentes
│   │   ├── utils/                         # Funções utilitárias
│   │   └── widgets/                       # Componentes reutilizáveis
│   │
│   └── features/                          # Features isoladas (Clean Architecture)
│       │
│       ├── auth/                          # 🔐 Autenticação
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── logged_user.dart   # User autenticado + Role + Department
│       │   │   └── repositories/
│       │   │       └── auth_repository.dart # Interface abstrata
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── firebase_auth_repository.dart # Impl. Firebase
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── auth_bloc.dart
│       │       │   ├── auth_event.dart
│       │       │   └── auth_state.dart
│       │       └── pages/
│       │           └── login_page.dart
│       │
│       ├── dashboard/                    # 📊 Dashboard com Métricas
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── dashboard_metrics.dart
│       │   │   └── repositories/
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── firebase_dashboard_repository.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── dashboard_bloc.dart
│       │       │   ├── dashboard_event.dart
│       │       │   └── dashboard_state.dart
│       │       └── pages/
│       │           └── dashboard_page.dart
│       │
│       ├── service_orders/               # 🔧 Ordens de Serviço
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── service_order.dart
│       │   │   └── repositories/
│       │   │       └── service_orders_repository.dart
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── firebase_service_orders_repository.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── service_orders_bloc.dart
│       │       │   ├── service_orders_event.dart
│       │       │   ├── service_orders_state.dart
│       │       │   ├── create_order_bloc.dart
│       │       │   ├── create_order_event.dart
│       │       │   └── create_order_state.dart
│       │       └── pages/
│       │           ├── service_orders_page.dart  # Lista de OS
│       │           ├── os_details_page.dart      # Detalhes da OS
│       │           └── create_os_page.dart       # Criar nova OS
│       │
│       ├── material_approvals/           # 📦 Aprovação de Materiais
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── material_request.dart
│       │   │   └── repositories/
│       │   │       └── material_requests_repository.dart
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── firebase_material_requests_repository.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── materials_bloc.dart
│       │       │   ├── materials_event.dart
│       │       │   └── materials_state.dart
│       │       └── pages/
│       │           ├── materials_page.dart         # Lista de requisições pendentes
│       │           ├── quick_approval_page.dart    # Aprovação rápida
│       │           └── tech_history_page.dart      # Histórico de técnico
│       │
│       ├── fleet_monitoring/            # 🚗 Rastreamento de Frota
│       │   ├── presentation/
│       │   │   ├── bloc/
│       │   │   │   ├── fleet_monitoring_bloc.dart
│       │   │   │   ├── fleet_monitoring_event.dart
│       │   │   │   └── fleet_monitoring_state.dart
│       │   │   └── pages/
│       │   │       ├── fleet_gps_page.dart         # Lista de técnicos
│       │   │       ├── live_tech_tracking_page.dart # Rastreamento ao vivo
│       │   │       └── os_tracking_map_page.dart   # Mapa de rastreamento
│       │   └── data/
│       │       └── repositories/
│       │           └── (usa diretamente FirebaseFirestore)
│       │
│       ├── user_management/             # 👥 Gestão de Usuários
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── user.dart         # Usuário do sistema
│       │   │   └── repositories/
│       │   │       └── user_management_repository.dart
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── firebase_user_management_repository.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── create_technician_bloc.dart
│       │       │   ├── create_technician_event.dart
│       │       │   └── create_technician_state.dart
│       │       └── pages/
│       │           ├── settings_page.dart           # Tela de configurações
│       │           └── create_technician_page.dart  # Criar técnico
│       │
│       ├── gps_monitoring/              # 📍 Monitoramento GPS
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── location.dart
│       │   │   └── repositories/
│       │   │       └── location_repository.dart
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── firebase_location_repository.dart
│       │   └── (sem presentation, gerenciado por fleet_monitoring)
│       │
│       ├── tracking/                    # 🗺️ (Stub - Reservado para futuro)
│       └── users/                       # (Stub - Reservado para futuro)
│
├── android/                              # Código nativo Android
├── ios/                                  # Código nativo iOS
├── web/                                  # Código web
├── macos/                                # Código macOS
├── windows/                              # Código Windows
├── linux/                                # Código Linux
│
├── test/                                 # Testes
├── docs/                                 # Documentação
├── analysis_options.yaml                 # Lint rules
├── pubspec.yaml                          # Dependências do projeto
├── firebase.json                         # Configuração Firebase CLI
└── README.md                             # Overview do projeto
```

---

## Modelo de Dados Firebase

### Estrutura de Collections

```
Firebase Database (Firestore)
│
├── 📁 users/
│   ├── {uid}
│   │   ├── id: string (UID do Firebase Auth)
│   │   ├── name: string
│   │   ├── email: string
│   │   ├── role: enum ('manager', 'coordinator', 'technician')
│   │   ├── department: string ('obras', 'hidricos')
│   │   ├── isActive: boolean
│   │   ├── createdAt: timestamp
│   │   ├── lastLoginAt: timestamp (nullable)
│   │   ├── isOnline: boolean (sync status)
│   │   ├── currentOs: string (ID da OS atual, se houver)
│   │   └── lastSync: string (timestamp do última sincronização)
│   │
│   ├── {uid} (Gerente)
│   └── {uid} (Coordenador)
│
├── 📁 service_orders/
│   ├── {osId}
│   │   ├── id: string (Document ID)
│   │   ├── title: string
│   │   ├── description: string
│   │   ├── status: enum ('aberta', 'em_andamento', 'aguardando_conferencia', 'concluida')
│   │   ├── department: string ('obras', 'hidricos')
│   │   ├── technicianId: string (referência para users/{technicianId})
│   │   ├── technicianName: string (denormalizado para performance)
│   │   ├── createdBy: string (UID do gerente que criou)
│   │   ├── createdByName: string (denormalizado)
│   │   ├── createdAt: timestamp
│   │   ├── photoUrl: string (URL do Firebase Storage, nullable)
│   │   └── locationUrl: string (URL do mapa com localização, nullable)
│   │
│   ├── {osId}
│   └── {osId}
│
├── 📁 material_requests/
│   ├── {requestId}
│   │   ├── id: string (Document ID)
│   │   ├── technicianId: string (quem solicitou)
│   │   ├── technicianName: string (denormalizado)
│   │   ├── department: string
│   │   ├── serviceOrderId: string (OS associada)
│   │   ├── serviceOrderTitle: string (denormalizado)
│   │   ├── items: array<string> (lista de materiais solicitados)
│   │   ├── status: enum ('pending', 'approved', 'rejected')
│   │   ├── createdAt: timestamp
│   │   ├── updatedAt: timestamp (nullable)
│   │   ├── approvedBy: string (UID de quem aprovou, nullable)
│   │   └── notes: string (observações da aprovação, nullable)
│   │
│   ├── {requestId}
│   └── {requestId}
│
├── 📁 locations/
│   ├── {userId}
│   │   └── 📁 history/  (subcollection com histórico de localizações)
│   │       ├── {locationId}
│   │       │   ├── id: string
│   │       │   ├── userId: string (referência para users/{userId})
│   │       │   ├── latitude: double
│   │       │   ├── longitude: double
│   │       │   ├── accuracy: double (metros, nullable)
│   │       │   ├── speed: double (km/h, nullable)
│   │       │   ├── heading: double (graus, nullable)
│   │       │   ├── timestamp: timestamp
│   │       │   └── serviceOrderId: string (OS em andamento, nullable)
│   │       │
│   │       ├── {locationId}
│   │       └── {locationId}
│   │
│   ├── {userId}
│   └── {userId}
│
└── 📁 logs/ (reservado para auditoria futura)
    └── (não implementado ainda)
```

### Índices Firestore Recomendados

Para otimizar queries (necessários em produção):

```yaml
# Collection: service_orders
Índices Compostos:
- (department, createdAt) [descending]
- (status, department) [status ascending, department ascending]

Índices Simples:
- status [descending]
- department [ascending]
- createdAt [descending]
- technicianId [ascending]

# Collection: material_requests
Índices Compostos:
- (status, createdAt) [status ascending, createdAt descending]
- (department, status) [department ascending, status ascending]

Índices Simples:
- technicianId [ascending]
- status [ascending]
- createdAt [descending]

# Collection: users
Índices Simples:
- role [ascending]
- department [ascending]
- name [ascending]
- isActive [ascending]

# Collection: locations/{userId}/history
Índices Simples:
- timestamp [descending]

# Collection: locations/{userId}/history (com serviço)
Índices Compostos:
- (serviceOrderId, timestamp) [both descending]
```

### Custom Claims (Firebase Auth)

Armazenados no token JWT de autenticação:

```json
{
  "role": "manager",        // ou "coordinator" ou "technician"
  "department": "all",      // ou "obras" ou "hidricos"
  "iat": 1702000000,
  "exp": 1702003600,
  "auth_time": 1702000000,
  "uid": "user123456"
}
```

**Nota Importante**: Custom Claims devem ser atualizados via Firebase Admin SDK (Backend) e nunca no cliente.

---

## Features Detalhadas

### 1️⃣ Feature: Authentication (`features/auth/`)

#### Responsabilidade
Gerenciar login, logout e verificação de sessão do usuário.

#### Dados Consumidos
- **Source**: Firebase Auth + Firestore `users/{uid}`
- **Collections**: `users`
- **Campos**: `role`, `department`, `name`, `email`

#### Entidades

```dart
enum UserRole { manager, coordinator, unknown }
enum Department { obras, hidricos, all, unknown }

class LoggedUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final Department department;
  
  bool get isManager => role == UserRole.manager;
  bool get isCoordinator => role == UserRole.coordinator;
}
```

#### Fluxo de Dados

1. **Login** → `FirebaseAuthRepository.signIn(email, password)`
   - Autentica via Firebase Auth
   - Busca Custom Claims do token JWT
   - Lê documento `users/{uid}` (cache primeiro, depois servidor)
   - Retorna `LoggedUser` com role e departamento

2. **Verificação de Sessão** → `AuthCheckRequested()` event
   - Executado ao iniciar app
   - Verifica se usuário já está logado
   - Restaura sessão do cache se disponível

3. **Logout** → `AuthSignOutRequested()` event
   - Limpa Firebase Auth
   - Limpa cache local
   - Redireciona para `/login`

#### BLoC States
- `AuthInitial` - Estado inicial
- `AuthLoading` - Processando login
- `AuthAuthenticated` - Usuário logado (emite `LoggedUser`)
- `AuthUnauthenticated` - Usuário não logado
- `AuthError` - Erro na autenticação

#### Eventos
- `AuthCheckRequested` - Checar se há sessão ativa
- `AuthSignInRequested` - Fazer login
- `AuthSignOutRequested` - Fazer logout

#### Páginas/Telas
- **LoginPage** - Formulário de autenticação

#### Implementações Técnicas

**Estratégia Offline-First para usuários logados:**
- Mantém documento do usuário em cache local
- Tenta ler do cache antes de fazer requisição ao servidor
- Sincroniza dados quando há conexão disponível

**Segurança:**
- Senhas nunca são armazenadas localmente
- Custom Claims validados no servidor (Backend responsibility)
- Session tokens renovados automaticamente

---

### 2️⃣ Feature: Dashboard (`features/dashboard/`)

#### Responsabilidade
Exibir métricas operacionais em tempo real e ordens de serviço recentes.

#### Dados Consumidos
- **Source**: Firestore `service_orders` e `material_requests`
- **Real-Time**: Streams com atualização automática
- **Segurança**: Filtra por departamento se usuário não é gestor

#### Entidades

```dart
class DashboardMetrics {
  final int openOs;              // Status: 'aberta'
  final int inProgressOs;        // Status: 'em_andamento'
  final int pendingReviewOs;     // Status: 'aguardando_conferencia'
  final int pendingMaterials;    // `material_requests` com status 'pending'
}
```

#### Fluxo de Dados

1. **Ao Acessar Dashboard**
   - `LoadDashboardRequested(user)` event disparado
   - Inicia stream de métricas em tempo real

2. **Real-Time Streaming**
   ```dart
   getMetricsStream(LoggedUser user)
     .where('department', isEqualTo: user.department) // Se non-manager
     .snapshots()  // Atualiza em tempo real
   ```

3. **Cálculo de Métricas**
   - Itera sobre `service_orders` e conta por status
   - Conta `material_requests` com status 'pending'
   - Retorna `DashboardMetrics` calculada

4. **Atualização em Tempo Real**
   - Sempre que alguém cria/atualiza uma OS → Dashboard atualiza
   - Sempre que material é aprovado/rejeitado → contador muda

#### BLoC States
- `DashboardInitial`
- `DashboardLoading`
- `DashboardLoaded` - Emite `DashboardMetrics` + lista de `ServiceOrder` recentes
- `DashboardError`

#### Eventos
- `LoadDashboardRequested(LoggedUser user)`

#### Páginas/Telas
- **DashboardPage**
  - 4 KPIs em grid (Open, In Progress, Pending Review, Pending Materials)
  - Lista de últimas 5 ordens de serviço (com navegação para detalhes)
  - Header com dados do usuário logado
  - Botão de logout

#### Queries Firebase

```firestore
// Obter métricas (tempo real)
service_orders
  .where('department', isEqualTo: user.department)  // Se não é gerente
  .snapshots()

// Obter materiais pendentes
material_requests
  .where('status', isEqualTo: 'pending')
  .where('department', isEqualTo: user.department)  // Se não é gerente
```

#### Performance Notes

- **Query Volume**: 2 queries de leitura por carregamento (1 OS + 1 materiais)
- **Streaming**: Reduz custos significativamente após primeira carga (usa cache)
- **Cache**: Dados armazenados localmente persistem offline

---

### 3️⃣ Feature: Service Orders (`features/service_orders/`)

#### Responsabilidade
Gerenciar ciclo de vida completo de ordens de serviço (criar, listar, visualizar, atualizar).

#### Dados Consumidos
- **Source**: Firestore `service_orders`
- **Real-Time**: Sim, via streams
- **Upload**: Fotos para Firebase Storage

#### Entidades

```dart
class ServiceOrder {
  final String id;
  final String title;
  final String description;
  final String status;  // 'aberta', 'em_andamento', 'aguardando_conferencia', 'concluida'
  final String department;  // 'obras' ou 'hidricos'
  final String technicianId;
  final String technicianName;
  final String createdBy;       // UID de quem criou
  final String createdByName;
  final DateTime? createdAt;
  final String? photoUrl;       // URL no Firebase Storage
  final String? locationUrl;    // URL do mapa
}
```

#### Fluxo de Dados

##### 3.1. Listar Ordens de Serviço

1. **Ao Acessar `/os`**
   - `LoadServiceOrdersRequested(user)` event
   - Inicia stream: `watchOrders(LoggedUser user)`

2. **Query Firestore**
   ```firestore
   service_orders
     .where('department', isEqualTo: user.department)  // Se non-manager
     .orderBy('createdAt', descending: true)
     .snapshots()
   ```

3. **BLoC Processa**
   - Converte `DocumentSnapshot` em `ServiceOrder`
   - Emite `ServiceOrdersLoaded(List<ServiceOrder>)`

4. **UI Renderiza**
   - Lista scrollável com cards de OS
   - Tap em card → Navega para `/os/{osId}` (detalhes)
   - Botão FAB → Navega para `/create-os`

##### 3.2. Visualizar Detalhes (OS Details Page)

1. **Ao Acessar `/os/{osId}`**
   - Inicia stream: `watchOrderById(String osId)`
   - Tempo real updates

2. **Renderização**
   - Título, descrição, status
   - Nome do técnico (com opção de atalhado)
   - Criador da OS (auditoria)
   - Data de criação
   - Foto (se houver)
   - Mapa da localização (se houver URL)

3. **Ações Disponíveis**
   - Atualizar status (dropdown: aberta → em_andamento → aguardando_conferencia → concluida)
   - Adicionar foto (ImagePicker → Firebase Storage upload)
   - Adicionar localização (Google Maps)
   - Voltar para lista

##### 3.3. Criar Nova Ordem de Serviço

1. **Ao Acessar `/create-os`**
   - `CreateOrderBloc` é criado como Factory
   - Carrega lista de técnicos disponíveis em tempo real

2. **User Input**
   - Título (TextFormField)
   - Descrição (TextFormField multiline)
   - Departamento (DropdownButton: obras/hidricos)
   - Técnico (DropdownButton, populado dinamicamente)

3. **Validação**
   - Título não vazio
   - Descrição não vazia
   - Técnico selecionado

4. **Salvar para Firebase**
   - Cria `ServiceOrder` com status `aberta`
   - Define `createdBy = user.uid` e `createdByName = user.name`
   - Chama `createServiceOrder(order)` repository
   - Repository gera documento no Firestore

5. **Resposta ao Usuário**
   - SnackBar confirmando criação
   - Volta automaticamente para lista (`/os`)

#### BLoC States (ServiceOrdersBloc)

```dart
class ServiceOrdersState {}

class ServiceOrdersInitial extends ServiceOrdersState {}
class ServiceOrdersLoading extends ServiceOrdersState {}
class ServiceOrdersLoaded extends ServiceOrdersState {
  final List<ServiceOrder> orders;
}
class ServiceOrdersError extends ServiceOrdersState {
  final String message;
}
```

#### Eventos (ServiceOrdersBloc)

```dart
class LoadServiceOrdersRequested extends Event {
  final LoggedUser user;
}

class ServiceOrderUpdated extends Event {
  final List<ServiceOrder> orders;
}
```

#### Páginas/Telas
- **ServiceOrdersPage** - Lista com search/filter
- **OSDetailsPage** - Detalhes e edição
- **CreateOSPage** - Formulário de criação

#### Queries Firebase

```firestore
// Listar ordens (com filtro por departamento se não é gerente)
service_orders
  .where('department', isEqualTo: user.department)
  .orderBy('createdAt', descending: true)
  .snapshots()

// Obter ordem específica
service_orders
  .doc(osId)
  .snapshots()

// Salvar nova ordem
service_orders
  .add(serviceOrder.toMap())

// Atualizar status
service_orders
  .doc(osId)
  .update({ 'status': newStatus })
```

#### Performance

- **Primeira Carga**: 1 read per service order (~1 read per 100 docs paginated)
- **Real-Time Updates**: Gratuito (usa cache, sem charges adicionais após primeira carga)
- **Upload de Fotos**: 1 escreve para OS document + 1 write para Storage

---

### 4️⃣ Feature: Material Approvals (`features/material_approvals/`)

#### Responsabilidade
Fluxo de aprovação de requisições de materiais solicitadas por técnicos.

#### Dados Consumidos
- **Source**: Firestore `material_requests`
- **Real-Time**: Sim, só requisições pendentes
- **Write**: Atualizar status para 'approved' ou 'rejected'

#### Entidades

```dart
class MaterialRequest {
  final String id;
  final String technicianId;         // Quem solicitou
  final String technicianName;
  final String department;
  final String serviceOrderId;       // OS associada
  final String serviceOrderTitle;
  final List<String> items;          // Materiais solicitados
  final String status;               // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? approvedBy;          // UID de quem aprovou
  final String? notes;               // Observações (se rejeitado)
}
```

#### Fluxo de Dados

##### 4.1. Listar Requisições Pendentes (Materials Page)

1. **Ao Acessar `/materials`**
   - `LoadMaterialsRequested(user)` event
   - Inicia stream: `watchPendingRequests(LoggedUser user)`

2. **Query Firestore**
   ```firestore
   material_requests
     .where('status', isEqualTo: 'pending')
     .where('department', isEqualTo: user.department)  // Se non-manager
     .orderBy('createdAt', descending: true)
     .snapshots()
   ```

3. **UI Renderiza**
   - Lista de requisições pendentes
   - Card com: técnico, OS, materiais, data
   - Buttons: Approve, Reject, View Details

##### 4.2. Quick Approval (Pop-Up Fast Lane)

**Rota**: `/quick-approve` (modal com slide transition)

1. **User Taps Card**
   - Abre modal `QuickApprovalPage`

2. **Mini Formulário**
   - Exibe: Técnico, OS, Materiais, Data
   - Input: Notes (opcional)
   - Buttons: Approve, Reject

3. **Approve Action**
   - Valida (nada para validar, notas opcionais)
   - Chama `updateRequestStatus(requestId, 'approved', user.uid, notes: '')`
   - Firestore update:
     ```firestore
     material_requests.doc(requestId).update({
       'status': 'approved',
       'approvedBy': currentUser.uid,
       'updatedAt': Timestamp.now(),
       'notes': notes
     })
     ```
   - Volta para lista (`/materials`)

4. **Reject Action**
   - **Obrigatório** coletar notes
   - Chama `updateRequestStatus(requestId, 'rejected', user.uid, notes: userNotes)`
   - Mesma lógica do approve

##### 4.3. Histórico de Técnico (Tech History Page)

**Rota**: `/materials/:techId/history`

1. **Ao Acessar**
   - Inicia stream: `watchRequestsByTechnician(techId)`

2. **Query Firestore**
   ```firestore
   material_requests
     .where('technicianId', isEqualTo: techId)
     .orderBy('createdAt', descending: true)
     .snapshots()
   ```

3. **Visualização**
   - Todas as requisições do técnico (pending, approved, rejected)
   - Status com cores: 🟡 pending, 🟢 approved, 🔴 rejected
   - Detalhes da aprovação/rejeição

#### BLoC States (MaterialsBloc)

```dart
class MaterialsState {}
class MaterialsInitial extends MaterialsState {}
class MaterialsLoading extends MaterialsState {}
class MaterialsLoaded extends MaterialsState {
  final List<MaterialRequest> pendingRequests;
}
class MaterialsError extends MaterialsState {
  final String message;
}
```

#### Eventos

```dart
class LoadMaterialsRequested extends Event {
  final LoggedUser user;
}

class UpdateMaterialRequestStatus extends Event {
  final String requestId;
  final String status;
  final String approvedBy;
  final String? notes;
}
```

#### Páginas/Telas
- **MaterialsPage** - Lista de requisições pendentes
- **QuickApprovalPage** - Modal de aprovação rápida
- **TechHistoryPage** - Histórico de um técnico

#### Queries Firebase

```firestore
// Obter requisições pendentes
material_requests
  .where('status', isEqualTo: 'pending')
  .where('department', isEqualTo: user.department)
  .orderBy('createdAt', descending: true)
  .snapshots()

// Histórico de um técnico
material_requests
  .where('technicianId', isEqualTo: techId)
  .orderBy('createdAt', descending: true)
  .snapshots()

// Atualizar status
material_requests
  .doc(requestId)
  .update({
    'status': status,
    'approvedBy': userId,
    'updatedAt': Timestamp.now()
  })
```

#### Segurança

- Apenas `manager` ou `coordinator` do departamento pode aprovar materiais
- Campo `approvedBy` rastreia quem aprovou (auditoria)

---

### 5️⃣ Feature: Fleet Monitoring (`features/fleet_monitoring/`)

#### Responsabilidade
Rastrear técnicos em tempo real na frota, visualizar localização ao vivo e histórico de percurso.

#### Dados Consumidos
- **Source**: Firestore `users` + `locations/{userId}/history`
- **Real-Time**: Sim, localizações em tempo real
- **API**: Google Maps Flutter para visualização

#### Fluxo de Dados

##### 5.1. Lista de Técnicos (Fleet GPS Page)

**Rota**: `/tracking`

1. **Ao Acessar**
   - `LoadFleetMonitoringRequested(user)` event
   - Query: Todos os `users` com `role = 'technician'` do departamento

2. **Query Firestore**
   ```firestore
   users
     .where('role', isEqualTo: 'technician')
     .where('department', isEqualTo: user.department)  // Se non-manager
     .orderBy('name')
     .snapshots()
   ```

3. **Renderização**
   - Card por técnico com:
     - Nome
     - Status online/offline
     - OS atual (se houver)
     - Última sincronização
     - Botão: "Rastrear" → `/tracking/live/{techId}`

#### BLoC States (FleetMonitoringBloc)

```dart
class FleetMonitoringState {}
class FleetMonitoringInitial extends FleetMonitoringState {}
class FleetMonitoringLoading extends FleetMonitoringState {}
class FleetMonitoringLoaded extends FleetMonitoringState {
  final List<Map> fleet;  // Lista de técnicos
}
class FleetMonitoringError extends FleetMonitoringState {
  final String message;
}
```

##### 5.2. Rastreamento ao Vivo (Live Tech Tracking Page)

**Rota**: `/tracking/live/:techId`

1. **Ao Acessar**
   - Obtém `techId` do path parameter
   - Inicia stream de localização em tempo real

2. **Query Firestore**
   ```firestore
   locations
     .doc(techId)
     .collection('history')
     .orderBy('timestamp', descending: true)
     .limit(1)
     .snapshots()
   ```

3. **Renderização (Google Maps)**
   - Mapa mostrando:
     - Marcador do técnico (localização atual)
     - Polyline do percurso (últimas N localizações)
     - Info box com: lat, long, speed, accuracy
     - Marker de localização da OS (se houver `serviceOrderId`)

4. **Real-Time Updates**
   - Stream de `locations/{techId}/history` atualiza mapa em tempo real
   - Útil para: coordenador acompanhar técnico em chamado urgente

##### 5.3. Mapa de Rastreamento (OS Tracking Map Page)

**Rota**: `/tracking-map/:entityId`

1. **Similar ao Live Tracking**
   - Mas foco na OS (não no técnico)
   - Polyline do percurso completo da OS

#### Páginas/Telas
- **FleetGpsPage** - Lista de técnicos
- **LiveTechTrackingPage** - Rastreamento ao vivo com mapa
- **OSTrackingMapPage** - Mapa com recurso da OS

#### Queries Firebase

```firestore
// Lista de técnicos
users
  .where('role', isEqualTo: 'technician')
  .where('department', isEqualTo: department)
  .orderBy('name')
  .snapshots()

// Localização atual de um técnico
locations
  .doc(techId)
  .collection('history')
  .orderBy('timestamp', descending: true)
  .limit(1)
  .snapshots()

// Histórico de localizações (últimas N)
locations
  .doc(techId)
  .collection('history')
  .orderBy('timestamp', descending: true)
  .limit(50)
  .snapshots()
```

#### Segurança & Privacidade

- Apenas `manager` ou `coordinator` pode visualizar localizações
- Técnico não vê sua própria localização via app (implementado no backend)
- Histórico é salvo com `serviceOrderId` para auditoria

---

### 6️⃣ Feature: User Management (`features/user_management/`)

#### Responsabilidade
Gerenciar usuários do sistema: listar, criar, editar, ativar/desativar.

#### Dados Consumidos
- **Source**: Firestore `users`
- **Real-Time**: Sim, lista de usuários
- **Write**: Criar novo técnico, atualizar informações

#### Entidades

```dart
enum UserRole { manager, coordinator, technician }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;     // manager, coordinator, technician
  final String department;  // obras, hidricos
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}
```

#### Fluxo de Dados

##### 6.1. Listar Usuários (Settings Page)

**Rota**: `/users`

1. **Ao Acessar**
   - `LoadUsersRequested()` event
   - Query: Todos os usuários (apenas gerentes podem ver todos)

2. **Query Firestore**
   ```firestore
   users
     .orderBy('name')
     .snapshots()
   ```

3. **Renderização**
   - Tabela/Lista com:
     - Nome, Email, Role, Departamento, Status
     - Botões: Edit, Delete, Activate/Deactivate

##### 6.2. Criar Novo Técnico (Create Technician Page)

**Rota**: `/create-technician`

1. **Formulário**
   - Nome (obrigatório)
   - Email (obrigatório, único)
   - Role (dropdown: manager, coordinator, technician)
   - Departamento (dropdown: obras, hidricos)

2. **Validação**
   - Email válido
   - Campos não vazios

3. **Criar User no Firebase Auth**
   - Backend responsibility (não pode se fazer do cliente)
   - **Alternativa no Cliente** (menos seguro):
     - Gera senha temporária
     - Chama `FirebaseAuth.createUserWithEmailAndPassword()`
     - **⚠️ Não Recomendado**: Requer permissões especiais

4. **Salvar em Firestore**
   - Cria documento em `users/{uid}` com campos:
     ```firestore
     {
       "name": "...",
       "email": "...",
       "role": "technician",
       "department": "obras",
       "isActive": true,
       "createdAt": Timestamp.now(),
       "lastLoginAt": null
     }
     ```

5. **Backend Setup**
   - Admin SDK: Seta custom claims:
     ```json
     { "role": "technician", "department": "obras" }
     ```

#### Pages/Telas
- **SettingsPage** - Gestão de usuários
- **CreateTechnicianPage** - Criar novo usuário

#### Queries Firebase

```firestore
// Listar todos os usuários
users
  .orderBy('name')
  .snapshots()

// Obter usuários por role
users
  .where('role', isEqualTo: 'technician')
  .orderBy('name')
  .snapshots()

// Atualizar usuário
users
  .doc(userId)
  .update(user.toMap())

// Desativar usuário
users
  .doc(userId)
  .update({ 'isActive': false })
```

---

### 7️⃣ Feature: GPS Monitoring (`features/gps_monitoring/`)

#### Responsabilidade
Rastrear posição GPS de técnicos e armazenar histórico de localizações.

#### Dados Consumidos
- **Source**: Device GPS (via `geolocator` package)
- **Storage**: Firestore `locations/{userId}/history`
- **Real-Time**: Streams de localização

#### Entidades

```dart
class Location {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;    // em metros
  final double? speed;       // km/h
  final double? heading;     // graus (0-360)
  final DateTime timestamp;
  final String? serviceOrderId;  // Se estiver em uma OS
}
```

#### Fluxo de Dados

1. **Background Service**
   - `flutter_background_service` roda em background (mesmo quando app fechado)
   - A cada N segundos (configurável): lê GPS
   - Envia para Firestore `locations/{userId}/history`

2. **Salvamento em Firestore**
   ```firestore
   locations
     .doc(userId)
     .collection('history')
     .add({
       "latitude": ...,
       "longitude": ...,
       "accuracy": ...,
       "speed": ...,
       "heading": ...,
       "timestamp": Timestamp.now(),
       "serviceOrderId": currentOsId  // Se aplicável
     })
   ```

3. **Leitura para Rastreamento**
   - Feature `fleet_monitoring` lê este dados para exibir ao coordenador

#### Repository Methods

```dart
class LocationRepository {
  Stream<Location> watchUserLocation(String userId);
  Stream<List<Location>> watchLocationHistory(String userId);
  Future<void> saveLocation(Location location);
}
```

#### ⚠️ Considerações Importantes

**Background Service Setup:**
- iOS: Requer `UIBackgroundModes` na `Info.plist` (location)
- Android: Requer service foreground com notificação
- Usuário precisa conceder permissão `Always Allow` para background

**Battery Impact:**
- GPS contínuo drena bateria (~15-30% por hora)
- Recomendado: Ajustar intervalo de rastreamento conforme necessário
- Parar rastreamento quando não houver OS ativa

**Privacy:**
- Dados de localização são sensíveis
- Implementar log de auditoria (quem acessou que dados)
- Retenção: deletar histórico após 30/60 dias

---

## Rotas e Navegação

### GoRouter Configuration

**Arquivo**: `lib/core/routes/app_router.dart`

#### Estrutura de Rotas

```dart
GoRouter(
  initialLocation: '/login',
  redirect: _redirect,
  routes: [
    // ==========================================
    // 1. ROTA NÃO-AUTENTICADA
    // ==========================================
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // ==========================================
    // 2. MODAL OVERLAY (fora da navegação principal)
    // ==========================================
    GoRoute(
      path: '/quick-approve',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: const QuickApprovalPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(begin: Offset(0, 1), end: Offset.zero)
                .animate(animation),
              child: child,
            );
          },
        );
      },
    ),

    // ==========================================
    // 3. ROTAS AUTENTICADAS COM BOTTOM NAVIGATION
    // ==========================================
    ShellRoute(
      builder: (context, state, navigationShell) =>
        ScaffoldWithNavBar(child: navigationShell),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            return BlocProvider<DashboardBloc>(
              create: (context) {
                final bloc = sl<DashboardBloc>();
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  bloc.add(LoadDashboardRequested(authState.user));
                }
                return bloc;
              },
              child: const DashboardPage(),
            );
          },
        ),

        GoRoute(
          path: '/os',
          builder: (context, state) {
            return BlocProvider<ServiceOrdersBloc>(
              create: (context) {
                final bloc = sl<ServiceOrdersBloc>();
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  bloc.add(LoadServiceOrdersRequested(authState.user));
                }
                return bloc;
              },
              child: ServiceOrdersPage(),
            );
          },
        ),

        GoRoute(
          path: '/materials',
          builder: (context, state) {
            return BlocProvider<MaterialsBloc>(
              create: (context) {
                final bloc = sl<MaterialsBloc>();
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  bloc.add(LoadMaterialsRequested(authState.user));
                }
                return bloc;
              },
              child: const MaterialsPage(),
            );
          },
        ),

        GoRoute(
          path: '/tracking',
          builder: (context, state) {
            return BlocProvider<FleetMonitoringBloc>(
              create: (context) {
                final bloc = sl<FleetMonitoringBloc>();
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  bloc.add(LoadFleetMonitoringRequested(authState.user));
                }
                return bloc;
              },
              child: FleetGpsPage(),
            );
          },
        ),

        GoRoute(
          path: '/users',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),

    // ==========================================
    // 4. ROTAS DINÂMICAS (com path parameters)
    // ==========================================
    GoRoute(
      path: '/tracking/live/:techId',
      pageBuilder: (context, state) {
        final techId = state.pathParameters['techId']!;
        return CustomTransitionPage(
          child: LiveTechTrackingPage(techId: techId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(begin: Offset(1, 0), end: Offset.zero)
                .animate(animation),
              child: child,
            );
          },
        );
      },
    ),

    GoRoute(
      path: '/tracking-map/:entityId',
      pageBuilder: (context, state) {
        final entityId = state.pathParameters['entityId']!;
        return CustomTransitionPage(
          child: OSTrackingMapPage(entityId: entityId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(begin: Offset(1, 0), end: Offset.zero)
                .animate(animation),
              child: child,
            );
          },
        );
      },
    ),

    GoRoute(
      path: '/os/:osId',
      pageBuilder: (context, state) {
        final osId = state.pathParameters['osId']!;
        return CustomTransitionPage(
          child: OSDetailsPage(osId: osId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(begin: Offset(1, 0), end: Offset.zero)
                .animate(animation),
              child: child,
            );
          },
        );
      },
    ),

    GoRoute(
      path: '/create-os',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: BlocProvider<CreateOrderBloc>(
            create: (_) => sl<CreateOrderBloc>(),
            child: const CreateOSPage(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(begin: Offset(1, 0), end: Offset.zero)
                .animate(animation),
              child: child,
            );
          },
        );
      },
    ),

    GoRoute(
      path: '/create-technician',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: BlocProvider<CreateTechnicianBloc>(
            create: (_) => sl<CreateTechnicianBloc>(),
            child: const CreateTechnicianPage(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(begin: Offset(1, 0), end: Offset.zero)
                .animate(animation),
              child: child,
            );
          },
        );
      },
    ),
  ],

  redirect: _redirect,  // Lógica de proteção de rotas
);
```

#### Função de Redirect (_redirect)

```dart
FutureOr<String?> _redirect(BuildContext context, GoRouterState state) {
  final isLoggedIn = authBloc?.state is AuthAuthenticated;
  final isGoingToLogin = state.uri.path == '/login';

  if (!isLoggedIn && !isGoingToLogin) {
    return '/login';  // Redireciona para login se não autenticado
  }

  if (isLoggedIn && isGoingToLogin) {
    return '/dashboard';  // Redireciona para dashboard se já logado
  }

  return null;  // Permite navegação normal
}
```

### Mapa de Rotas Completo

```
LOGIN (Pública)
├── /login                    → LoginPage

AUTHENTICATED (Protegidas)
├── ShellRoute (Bottom Navigator)
│   ├── /dashboard           → DashboardPage
│   ├── /os                  → ServiceOrdersPage
│   ├── /materials           → MaterialsPage
│   ├── /tracking            → FleetGpsPage
│   └── /users               → SettingsPage
│
├── OVERLAYS (Modais)
│   └── /quick-approve       → QuickApprovalPage (Slide from bottom)
│
├── DYNAMIC ROUTES
│   ├── /os/:osId            → OSDetailsPage (Slide from right)
│   ├── /create-os           → CreateOSPage (Slide from right)
│   ├── /tracking/live/:techId    → LiveTechTrackingPage (Slide from right)
│   ├── /tracking-map/:entityId   → OSTrackingMapPage (Slide from right)
│   ├── /create-technician   → CreateTechnicianPage (Slide from right)
│   └── /materials/:techId/history → TechHistoryPage (Slide from right)
```

### Navegação Programática

```dart
// Navegar para rota simples
context.push('/dashboard');

// Navegar com path parameter
context.push('/os/$osId');

// Navegar e remover toda a stack
context.go('/login');

// Substituir rota atual
context.replace('/dashboard');

// Voltar
context.pop();

// Com dados
context.pushExtra({
  'techId': technicianId,
  'data': someData,
});
```

---

## Fluxo de Dados Completo

### Diagrama: Do Usuário ao Firebase e de Volta

```
┌─────────────────────────────────────────────────────────────────┐
│                      APP FLOWCHART                              │
└─────────────────────────────────────────────────────────────────┘

1️⃣ STARTUP
   ┌──────────────────┐
   │ main.dart starts │
   └────────┬─────────┘
            ↓
   ┌──────────────────────────┐
   │ Initialize Firebase      │
   │ Initialize GetIt         │
   │ Initialize Localizations │
   └────────┬─────────────────┘
            ↓
   ┌──────────────────────────┐
   │ AuthBloc (Singleton)     │
   │ add: AuthCheckRequested  │
   └────────┬─────────────────┘
            ↓
   ┌──────────────────────────────────────────────┐
   │ FirebaseAuthRepository                       │
   │ getCurrentUser()                             │
   │   → check FirebaseAuth.currentUser           │
   │   → fetch users/{uid} from Firestore (cache) │
   │   → return LoggedUser                        │
   └────────┬─────────────────────────────────────┘
            ↓
   ┌──────────────────────────┐
   │ AuthBloc State Changes   │
   │ → AuthAuthenticated      │
   │   (or Unauthenticated)   │
   └────────┬─────────────────┘
            ↓
   ┌──────────────────────────┐
   │ GoRouter redirect()      │
   │ → /dashboard (if logged) │
   │ → /login (if not)        │
   └──────────────────────────┘

2️⃣ LOGIN FLOW
   ┌─────────────────────────────┐
   │ LoginPage                   │
   │ User enters email + password│
   └────────┬────────────────────┘
            ↓
   ┌────────────────────────────────────┐
   │ AuthBloc.add(AuthSignInRequested)  │
   └────────┬──────────────────────────┘
            ↓
   ┌────────────────────────────────────────────┐
   │ FirebaseAuthRepository.signIn()            │
   │   1. FirebaseAuth.signInWithEmailPassword()│
   │   2. get CustomClaims from JWT             │
   │   3. fetch users/{uid} doc                 │
   │   4. map to LoggedUser                     │
   └────────┬──────────────────────────────────┘
            ↓
   ┌────────────────────────────────────────────┐
   │ AuthBloc emits AuthAuthenticated(user)     │
   │ GoRouter redirects to /dashboard           │
   └────────────────────────────────────────────┘

3️⃣ DASHBOARD FLOW
   ┌──────────────────┐
   │ /dashboard route │
   └────────┬─────────┘
            ↓
   ┌───────────────────────────────┐
   │ BlocProvider<DashboardBloc>   │
   │ create: sl<DashboardBloc>     │
   │ add: LoadDashboardRequested() │
   └────────┬─────────────────────┘
            ↓
   ┌──────────────────────────────────────────────┐
   │ DashboardBloc._onLoadDashboardRequested()    │
   │ Calls: FirebaseDashboardRepository.getMetrics│
   └────────┬──────────────────────────────────────┘
            ↓
   ┌─────────────────────────────────────────┐
   │ Firestore Query (Real-Time Stream)      │
   │ service_orders.snapshots()              │
   │   ├─ filter by department (if needed)   │
   │   ├─ count by status                    │
   │   ├─ material_requests count            │
   │   └─ emit DashboardMetrics              │
   └────────┬────────────────────────────────┘
            ↓
   ┌─────────────────────────────────┐
   │ DashboardBloc emits:            │
   │ DashboardLoaded(metrics, orders)│
   └────────┬────────────────────────┘
            ↓
   ┌─────────────────────────────────┐
   │ DashboardPage.build()           │
   │ Renders KPI cards + order list  │
   │ + logout button                 │
   └─────────────────────────────────┘

4️⃣ CREATE SERVICE ORDER FLOW
   ┌──────────────────┐
   │ User clicks FAB  │
   │ "+ Nova OS"      │
   └────────┬─────────┘
            ↓
   ┌───────────────────────────┐
   │ Navigation to /create-os  │
   └────────┬──────────────────┘
            ↓
   ┌──────────────────────────────────────┐
   │ CreateOSPage                         │
   │ BlocProvider<CreateOrderBloc>        │
   └────────┬──────────────────────────────┘
            ↓
   ┌────────────────────────────────────┐
   │ Query technicians in real-time:    │
   │ users.where(role='technician')..   │
   │ .snapshots()                       │
   │ → Populate dropdown                │
   └────────┬─────────────────────────┘
            ↓
   ┌────────────────────────────────┐
   │ User fills form:               │
   │ - title, description           │
   │ - selects department           │
   │ - selects technician           │
   │ - taps "Criar"                 │
   └────────┬────────────────────────┘
            ↓
   ┌──────────────────────────────────┐
   │ Form validation                  │
   │ (title, desc, tech not empty)    │
   └────────┬─────────────────────────┘
            ↓
   ┌──────────────────────────────────────────┐
   │ CreateOrderBloc.add(CreateOSRequested)   │
   └────────┬──────────────────────────────────┘
            ↓
   ┌──────────────────────────────────────┐
   │FirebaseServiceOrdersRepository.create│
   │  1. ServiceOrder.toMap()             │
   │  2. Firestore.service_orders.add()   │
   │  3. Document auto-generated ID      │
   └────────┬───────────────────────────┘
            ↓
   ┌──────────────────────────────┐
   │ BLoC emits: CreateOSSuccess  │
   │ SnackBar: "OS criada!"       │
   │ context.pop() → back to /os  │
   └──────────────────────────────┘
            ↓
   ┌──────────────────────────────┐
   │ ServiceOrdersPage updates    │
   │  (Real-time via stream)      │
   │  New OS appears in list      │
   └──────────────────────────────┘

5️⃣ APPROVE MATERIAL REQUEST FLOW
   ┌──────────────────────────────────┐
   │ /materials route                 │
   │ MaterialsBloc watches pending     │
   │ material_requests.snapshots()    │
   └────────┬─────────────────────────┘
            ↓
   ┌────────────────────────────────────────┐
   │ User sees list of pending requests    │
   │ Each card: technician, O,items, date  │
   │ Taps "Approve" button                │
   └────────┬────────────────────────────────┘
            ↓
   ┌───────────────────────────────────┐
   │ Navigation to /quick-approve      │
   │ (modal with slide transition)     │
   └────────┬───────────────────────────┘
            ↓
   ┌──────────────────────────────┐
   │ QuickApprovalPage shown      │
   │ User can add notes (optional)│
   │ Taps "Aprove"               │
   └────────┬─────────────────────┘
            ↓
   ┌────────────────────────────────────────┐
   │ FirebaseMaterialRequestsRepository.    │
   │ updateRequestStatus()                 │
   │   material_requests.doc(id).update({  │
   │     'status': 'approved',             │
   │     'approvedBy': currentUserId,      │
   │     'updatedAt': Timestamp.now()      │
   │   })                                  │
   └────────┬──────────────────────────────┘
            ↓
   ┌──────────────────────────────────┐
   │ Real-time stream updates        │
   │ Material status changes in UI   │
   │ Request removed from "Pending"  │
   └──────────────────────────────────┘

6️⃣ LOGOUT FLOW
   ┌─────────────────────────┐
   │ User taps logout button  │
   │ (in DashboardPage)       │
   └────────┬────────────────┘
            ↓
   ┌──────────────────────────────────┐
   │ AuthBloc.add(AuthSignOutRequested)│
   └────────┬──────────────────────────┘
            ↓
   ┌────────────────────────────────┐
   │ FirebaseAuthRepository.signOut()│
   │ FirebaseAuth.signOut()          │
   └────────┬───────────────────────┘
            ↓
   ┌─────────────────────────────────┐
   │ AuthBloc emits:                 │
   │ AuthUnauthenticated             │
   └────────┬────────────────────────┘
            ↓
   ┌────────────────────────────────────┐
   │ GoRouter redirect()                │
   │ Checks: authBloc.state is not      │
   │ AuthAuthenticated                  │
   │ → Redirects to /login              │
   └────────────────────────────────────┘
```

---

## Segurança e Controle de Acesso

### Modelo de Utilizadores

```
┌─────────────────────────────────┐
│         Perfis de Acesso         │
├─────────────────────────────────┤
│ 1. MANAGER (Gerente)            │
│    - Acesso total à plataforma  │
│    - Vê dados de todos os depto.│
│    - Pode criar/editar tudo     │
│    - Department: "all"          │
│    - Custom Claims: {           │
│        "role": "manager",       │
│        "department": "all"      │
│      }                          │
├─────────────────────────────────┤
│ 2. COORDINATOR (Coordenador)    │
│    - Acesso limitado            │
│    - Vê apenas seu departamento │
│    - Pode criar/editar em seu   │
│      departamento               │
│    - Department: "obras" ou     │
│      "hidricos"                 │
│    - Custom Claims: {           │
│        "role": "coordinator",   │
│        "department": "obras"    │
│      }                          │
├─────────────────────────────────┤
│ 3. TECHNICIAN (Técnico)         │
│    - Acesso não implementado    │
│    - Reservado para futuro      │
│    - Roles diferentes           │
│    - Department: "obras" ou     │
│      "hidricos"                 │
└─────────────────────────────────┘
```

### Data Access Control

```
Feature                  Manager  Coordinator  Technician
────────────────────────────────────────────────────────
Dashboard               ✅ All     ✅ Dept Only  ❌ N/A
  └─ View Metrics       ✅         ✅ Own Dept   ❌
  └─ View All OS        ✅         ✅ Own Dept   ❌

Service Orders          ✅ All     ✅ Dept Only  ❌
  └─ List               ✅         ✅ Own Dept   ❌
  └─ Create             ✅         ✅ Own Dept   ❌
  └─ Edit Status        ✅         ✅ Own Dept   ❌
  └─ Delete             ✅         ❌            ❌

Material Requests       ✅ All     ✅ Dept Only  ❌
  └─ View Pending       ✅         ✅ Own Dept   ❌
  └─ Approve/Reject     ✅         ✅ Own Dept   ❌

Fleet Monitoring        ✅ All     ✅ Dept Only  ❌
  └─ View Techs         ✅         ✅ Own Dept   ❌
  └─ Live Tracking      ✅         ✅ Own Dept   ❌

User Management         ✅ All     ❌            ❌
  └─ Create User        ✅         ❌            ❌
  └─ Edit User          ✅         ❌            ❌
```

### Firestore Security Rules (Recomendado)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Função helper: verificar role
    function hasRole(role) {
      return request.auth.token.role == role;
    }

    function isManager() {
      return hasRole('manager');
    }

    function isCoordinator() {
      return hasRole('coordinator');
    }

    function sameOrAllDept(dept) {
      return request.auth.token.department == 'all' || 
             request.auth.token.department == dept;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // ==========================================
    // COLLECTION: users
    // ==========================================
    match /users/{userId} {
      // Read: próprio perfil sempre; manager vê todos
      allow read: if isManager() || isOwner(userId);
      
      // Write: apenas manager ou update próprio lastLoginAt
      allow write: if isManager() || (isOwner(userId) && 
        request.resource.data.lastLoginAt != null &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['lastLoginAt'])
      );
    }

    // ==========================================
    // COLLECTION: service_orders
    // ==========================================
    match /service_orders/{osId} {
      // Read: manager todos; coordinator seu dept
      allow read: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      
      // Create: manager todos; coordinator seu dept
      allow create: if isManager() || (isCoordinator() && 
        sameOrAllDept(request.resource.data.department));
      
      // Update: manager todos; coordinator seu dept
      allow update: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      
      // Delete: apenas manager
      allow delete: if isManager();
    }

    // ==========================================
    // COLLECTION: material_requests
    // ==========================================
    match /material_requests/{requestId} {
      allow read: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      
      allow create: if isManager() || (isCoordinator() && 
        sameOrAllDept(request.resource.data.department));
      
      allow update: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department) &&
        request.resource.data.approvedBy != null &&
        request.resource.data.updatedAt != null);
      
      allow delete: if isManager();
    }

    // ==========================================
    // COLLECTION: locations (GPS)
    // ==========================================
    match /locations/{userId}/history/{locationId} {
      // Read: manager todos; coordinator seu dept
      allow read: if isManager() || (isCoordinator() && 
        exists(/databases/$(database)/documents/users/
          get(/databases/$(database)/documents/locations/$(userId)).department));
      
      // Write: próprio usuário ou sistema backend
      allow write: if isOwner(userId);
    }

    // ==========================================
    // Deny tudo que não foi explicitamente permitido
    // ==========================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Custom Claims Setup (Backend)

```dart
// Exemplo usando Firebase Admin SDK (Node.js)
import admin from 'firebase-admin';

app.post('/api/set-custom-claims', authenticateAdmin, async (req, res) => {
  const { uid, role, department } = req.body;

  try {
    await admin.auth().setCustomUserClaims(uid, {
      role,        // 'manager', 'coordinator', 'technician'
      department,  // 'works', 'hidricos', 'all'
    });
    
    // Também atualizar documento do usuário em Firestore
    await admin.firestore()
      .collection('users')
      .doc(uid)
      .update({
        role,
        department,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

---

## Padrões de Design Implementados

### 1. Clean Architecture (3 Layers)

**Objetivo**: Separação clara de responsabilidades e fácil teste.

```
┌─────────────────────────────────────────────────┐
│ PRESENTATION LAYER (UI)                         │
├─────────────────────────────────────────────────┤
│ - Pages (Stateless/Stateful widgets)            │
│ - BLoCs (State managers using flutter_bloc)     │
│ - Events (User actions)                         │
│ - States (UI states)                            │
└─────────────────────────┬───────────────────────┘
                          ↓
                    (Depends on)
                          ↓
┌─────────────────────────────────────────────────┐
│ DOMAIN LAYER (Business Logic)                   │
├─────────────────────────────────────────────────┤
│ - Entities (Business models - immutable)        │
│ - Repositories (Abstract interfaces)            │
│ - (Use Cases - não explicitamente implementados)│
└─────────────────────────┬───────────────────────┘
                          ↓
                    (Depends on)
                          ↓
┌─────────────────────────────────────────────────┐
│ DATA LAYER (Data Access)                        │
├─────────────────────────────────────────────────┤
│ - Repositories Implementation (Firebase)        │
│ - Models (Firebase-specific mappers)            │
│ - Data Sources (Firebase APIs)                  │
└─────────────────────────────────────────────────┘
```

**Benefícios:**
- Altamente testável (mock repositories)
- Independente de framework (Firebase pode ser substituído)
- Regras de negócio isoladas em Domain
- UI separada de lógica

### 2. BLoC Pattern (Business Logic Component)

**Objetivo**: Gerenciar estado e lógica da aplicação de forma reativa.

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;

  UserBloc({required this.repository}) : super(UserInitial()) {
    // Registrar event handlers
    on<UserCreatedEvent>(_onUserCreated);
    on<UserUpdatedEvent>(_onUserUpdated);
    on<UserDeletedEvent>(_onUserDeleted);
  }

  Future<void> _onUserCreated(
    UserCreatedEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      await repository.createUser(event.user);
      emit(UserCreatedSuccess());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
```

**Ciclo de Vida:**

```
Event → BLoC Handler → Repository → Firebase → State Change → UI Update
```

**Benefícios:**
- Reatividade naturali
- Testável (event → state)
- Separação clara de responsabilidades
- Fácil debug com DevTools

### 3. Repository Pattern (Data Abstraction)

**Objetivo**: Abstrair detalhes de acesso a dados.

```dart
// Domain layer (abstration)
abstract class UserRepository {
  Future<User> getUser(String userId);
  Future<void> createUser(User user);
  Stream<List<User>> watchAllUsers();
}

// Data layer (implementation)
class FirebaseUserRepository implements UserRepository {
  @override
  Stream<List<User>> watchAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(User.fromFirestore).toList());
  }
}
```

**Benefícios:**
- Firebase pode ser substituído sem afetar BLoCs
- Múltiplas implementações possíveis (fake, mock)
- Contrato claro de operações

### 4. Service Locator (Dependency Injection via GetIt)

**Objetivo**: Registrar e recuperar dependências globalmente.

```dart
final sl = GetIt.instance;

Future<void> init() async {
  // ===== Firebase =====
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // ===== Repositories =====
  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(sl<FirebaseAuth>(), sl<FirebaseFirestore>()),
  );

  // ===== BLoCs =====
  sl.registerSingleton<AuthBloc>(
    AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(sl<FirebaseDashboardRepository>()),
  );
}

// Uso na aplicação
final authBloc = sl<AuthBloc>();
```

**Tipos de Registro:**
- `registerSingleton`: Instância única (criada imediatamente)
- `registerLazySingleton`: Instância única (criada à primeira requisição)
- `registerFactory`: Instância nova a cada requisição

**Benefícios:**
- Injeção sem boilerplate
- Fácil substituir implementações
- Mock fácil para testes

### 5. Real-Time Streams (Reactive Data)

**Objetivo**: Dados sempre atualizados sem polling.

```dart
// Repository
Stream<List<ServiceOrder>> watchOrders(LoggedUser user) {
  return _firestore
      .collection('service_orders')
      .where('department', isEqualTo: user.department)
      .orderBy('createdAt', descending: true)
      .snapshots()  // ← Firestore retorna stream atualizado
      .map((snapshot) => snapshot.docs.map(ServiceOrder.fromFirestore).toList());
}

// BLoC
on<LoadOrdersRequested>((event, emit) {
  _subscription = repository.watchOrders(event.user).listen(
    (orders) => add(OrdersUpdated(orders)),  // Emite novo event a cada mudança
  );
});

// UI
StreamBuilder<List<ServiceOrder>>(
  stream: repository.watchOrders(user),
  builder: (context, snapshot) {
    // Renderiza lista sempre atualizada
    return ListView(children: snapshot.data ?? []);
  },
);
```

**Benefícios:**
- Zero latência de atualização
- Dados sempre sincronizados
- Escalável (Firestore gerencia sub.)

### 6. Offline-First Caching

**Objetivo**: Funcionamento parcial sem internet usando cache local.

```dart
// Firestore habilitado para persistência
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Queries automaticamente tentam cache primeiro
final docs = await firestore
    .collection('users')
    .doc(userId)
    .get();  // Tenta cache antes de fazer requisição

// Para forçar servidor:
final docs = await firestore
    .collection('users')
    .doc(userId)
    .get(GetOptions(source: Source.server));
```

### 7. Equatable for Value Equality

**Objetivo**: Comparação de objetos por valor, não por referência.

```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;

  const User({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];  // Define igualdade
}

// Uso
final user1 = User(id: '1', name: 'João');
final user2 = User(id: '1', name: 'João');

print(user1 == user2);  // true (por valor)
print(identical(user1, user2));  // false (objetos diferentes)
```

**Benefícios:**
- BLoCs podem comparar `state == newState`
- Evita rebuilds desnecessários

---

## Estratégia Offline-First

### Arquitetura de Cache

```
┌─────────────────────────────────────────────────┐
│            DEVICE (Local)                        │
├──────────────────────┬──────────────────────────┤
│  Firestore Cache     │  Shared Preferences      │
│  (Persistent)        │  (Key-Value Storage)     │
│  ├─ All collections  │  ├─ Auth token           │
│  ├─ Indices          │  ├─ User preferences     │
│  └─ Query results    │  └─ Session state        │
└──────────────────────┴──────────────────────────┘
            ↑                    ↑
            └────────┬───────────┘
                     │
            (Sincronização automática)
                     ↓
┌─────────────────────────────────────────────────┐
│          FIRESTORE (Remote)                      │
├─────────────────────────────────────────────────┤
│  Cloud Database                                  │
│  ├─ users                                       │
│  ├─ service_orders                              │
│  ├─ material_requests                           │
│  └─ locations                                   │
└─────────────────────────────────────────────────┘
```

### Ciclo de Cache

**1. Primeira Requisição (sem cache)**
```
App starts 
  → Firestore offline-first tenta ler collection
  → Caché vazio, sem internet: falha (erro)
  → Se com internet: busca do servidor, salva em cache local
```

**2. Próximas Requisições (com cache)**
```
User navega para Dashboard
  → Firestore tenta ler collection
  → (Mesmo com internet) → tenta cache primeiro (sucesso)
  → Se tiver connexão → sincroniza alterações com servidor (em background)
  → Ao renovar (pull-to-refresh) → força leitura do servidor
```

**3. Sem Internet**
```
User abre app, sem internet
  → Firestore retorna dados do cache local
  → Offline indicator mostrado na UI
  → User pode navegar e visualizar dados do cache
  → Criação/edição: salva localmente, sincroniza quando online
```

### Implementação Prática

```dart
// Habilitar cache no main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Repository - Estratégia Cache-First
Stream<List<ServiceOrder>> watchOrders(LoggedUser user) {
  return _firestore
      .collection('service_orders')
      .where('department', isEqualTo: user.department)
      .orderBy('createdAt', descending: true)
      .snapshots();  // Firestore automaticamente usa cache
}

// Forçar refresh do servidor
Future<void> refreshOrders() async {
  await FirebaseFirestore.instance
      .collection('service_orders')
      .get(GetOptions(source: Source.server));
}

// Network state listener
import 'package:connectivity_plus/connectivity_plus.dart';

Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
  if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
    // Voltou online: sincronizar dados
    syncPendingChanges();
  } else {
    // Perdeu conexão: mostrar offline mode UI
    showOfflineIndicator();
  }
});
```

### Estratégia de Sincronização

```
┌──────────────────────────────────────────────┐
│      LOCAL CHANGES (User Edits)              │
├──────────────────────────────────────────────┤
│ 1. Save to Local Cache immediately          │
│    └─ updateUI immediately (optimistic)     │
│                                              │
│ 2. Queue change for sync                    │  
│    └─ Store in "pendingSync" collection     │
│                                              │
│ 3. When online:                             │
│    └─ Send all pending changes to server    │
│    └─ Resolve conflicts if necessary        │
│    └─ Confirm sync in local DB              │
└──────────────────────────────────────────────┘
```

### Conflitos e Sincronização

**Cenário 1: Criar OS offline**
```
1. User cria OS sem internet
   → Salva localmente com status 'syncing'
2. User voltar online
   → App detecta connexão
   → Envia OS para Firestore
   → Firestore gera ID único
   → App atualiza documento local com novo ID
   → Status muda para 'synced'
```

**Cenário 2: Editar OS sem internet**
```
1. User abre OS (dados in cache)
2. Muda status sem internet
   → Salva localmente (optimistic)
3. Volta online
   → App sincroniza mudança
   → Se sem conflito: sucesso
   → Se conflito (alterado no servidor):
     → Firestore "ganha" (server-first policy)
     → UI atualiza com versão do servidor
```

**implementação:**
```dart
Future<void> syncPendingChanges() async {
  final pendingSync = await sl<LocalDatabase>().getPending();
  
  for (var change in pendingSync) {
    try {
      await FirebaseFirestore.instance
          .collection(change.collection)
          .doc(change.docId)
          .set(change.data, SetOptions(merge: true));
      
      // Marcar como sincronizado
      await sl<LocalDatabase>().markSynced(change.id);
    } catch (e) {
      // Erro: continuar, tentar de novo depois
      print('Sync error: $e');
    }
  }
}
```

### Limitações e Boas Práticas

| Aspecto | Recomendação |
|---------|--------------|
| **Cache Size** | Unlimited no dev; ~50MB em prod |
| **Retenção** | Firestore limpa cache automático se necessário |
| **TTL** | Não configurável (usa padrão do Firestore) |
| **Conflitos** | Server-first policy (dados do server sobrescrevem local) |
| **Uploads** | Fotos/binários não são cached; falham offline |
| **Integridade** | Indexes devem ser criados no console Firebase |

---

## Gerenciamento de Estado

### BLoC Lifecycle

```
┌──────────────────────────────────────────┐
│     BLOC LIFECYCLE                       │
├──────────────────────────────────────────┤
│                                          │
│ 1. CREATE                                │
│    bloc = MyBloc(repository);            │
│    ↓                                     │
│ 2. INITIAL STATE                         │
│    state = MyState.initial()             │
│    ↓                                     │
│ 3. EVENT ADD                             │
│    bloc.add(MyEvent());                  │
│    ↓                                     │
│ 4. HANDLER EXECUTION                     │
│    on<MyEvent>(_onMyEvent);              │
│    ↓                                     │
│ 5. STATE EMIT                            │
│    emit(NewState());                     │
│    ↓                                     │
│ 6. UI REBUILD                            │
│    BlocBuilder recognizes state change  │
│    Widget rebuilds                       │
│    ↓                                     │
│ 7. CLOSE                                 │
│    bloc.close();  // cleanup             │
│                                          │
└──────────────────────────────────────────┘
```

### State Immutability

```dart
// ❌ NÃO FAZER (mutável)
class UserState {
  List<User> users;
  UserState({required this.users});
  
  void addUser(User user) {
    users.add(user);  // Mutação direta
  }
}

// ✅ FAZER (imutável)
class UserState extends Equatable {
  final List<User> users;
  
  const UserState({required this.users});
  
  UserState copyWith({List<User>? users}) {
    return UserState(users: users ?? this.users);
  }
}

// Uso
emit(state.copyWith(users: [...state.users, newUser]));
```

### Testing BLoCs

```dart
void main() {
  group('UserBloc Tests', () {
    late UserBloc userBloc;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      userBloc = UserBloc(repository: mockRepository);
    });

    tearDown(() => userBloc.close());

    test('emits [UserLoading, UserLoaded] on successful fetch', () async {
      // Arrange
      final users = [User(id: '1', name: 'John')];
      when(mockRepository.getUsers())
          .thenAnswer((_) async => users);

      // Assert later
      expectLater(
        userBloc.stream,
        emitsInOrder([
          isA<UserLoading>(),
          isA<UserLoaded>().having((state) => state.users, 'users', users),
        ]),
      );

      // Act
      userBloc.add(UserFetchRequested());
    });
  });
}
```

### Performance Optimization

**1. Avoid Rebuilds**
```dart
// ❌ Rebuilds toda vez que state muda
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) {
    return Text(state.user.name);  // Até mesmo se mudou outro field
  },
);

// ✅ Rebuilds apenas se specific field mudou
BlocBuilder<MyBloc, MyState>(
  buildWhen: (previous, current) =>
      previous.user.name != current.user.name,
  builder: (context, state) {
    return Text(state.user.name);
  },
);
```

**2. Use BlocListener para Side Effects**
```dart
// ❌ Chamar função a cada rebuild
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) {
    if (state is UserCreated) {
      Navigator.pop(context);  // Chamado a cada rebuild!
    }
    return Container();
  },
);

// ✅ Chamar apenas uma vez
BlocListener<MyBloc, MyState>(
  listener: (context, state) {
    if (state is UserCreated) {
      Navigator.pop(context);  // Uma vez só
    }
  },
  child: BlocBuilder<MyBloc, MyState>(
    builder: (context, state) => Container(),
  ),
);
```

---

## Instruções de Manutenção

### Setup Local para Desenvolvimento

#### Pré-requisitos

```bash
# Ferramentas requeridas
- Flutter 3.11.4+
- Dart 3.11.4+
- Xcode 14+ (macOS/iOS development)
- Android Studio Arctic Fox+ (Android development)
- CocoaPods (iOS dependencies)
- Firebase CLI
```

#### Instalação

```bash
# 1. Clonar repositório
git clone <repository-url>
cd urbaos_admin

# 2. Instalar dependências Flutter
flutter pub get

# 3. Configurar Firebase (se necessário)
flutterfire configure

# 4. Gerar arquivos gerados
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Verificar lints
flutter analyze

# 6. Rodar app
flutter run -d <device-id>
```

### Firebase Setup

#### 1. Console Firebase Configuration

```
1. Ir para https://console.firebase.google.com
2. Criar novo projeto "urbaos_admin"
3. Habilitar Authentication:
   - Email/Password
   - Custom Claims via Admin SDK
4. Criar Firestore database:
   - Production mode (rules restritivas)
   - Região: us-central1
5. Configurar Cloud Storage (fotos/uploads)
6. Download google-services.json (Android)
7. Download GoogleService-Info.plist (iOS)
```

#### 2. Firestore Collections Setup

```firestore
// users collection
- Criar collection "users"
- Set initial document (admin) com:
  {
    "name": "Admin",
    "email": "admin@urbaos.com",
    "role": "manager",
    "department": "all",
    "isActive": true,
    "createdAt": <timestamp>,
    "lastLoginAt": null
  }

// service_orders collection (vazio inicialmente)
// material_requests collection (vazio inicialmente)
// locations collection (vazio inicialmente)
```

#### 3. Custom Claims (Backend)

```javascript
// Firebase Cloud Functions (Node.js)
// Deploy via: firebase deploy --only functions

import admin from 'firebase-admin';
import functions from 'firebase-functions';

export const setUserRole = functions.https.onCall(async (data, context) => {
  const { uid, role, department } = data;
  
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can set custom claims'
    );
  }
  
  await admin.auth().setCustomUserClaims(uid, { role, department });
  
  return { success: true };
});
```

### Build & Deployment

#### Android Build

```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle (Google Play Store)
flutter build appbundle

# Sign release
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure in android/key.properties:
storeFile=/Users/<username>/upload-keystore.jks
storePassword=<password>
keyPassword=<password>
keyAlias=upload

flutter build appbundle --release
```

#### iOS Build

```bash
# Resolver Pods
cd ios && pod repo update && cd ..

# Build release
flutter build ios --release

# Archive para App Store
open ios/Runner.xcworkspace

# No Xcode:
# 1. Select "Runner" target
# 2. Product → Archive
# 3. Distribute App
# 4. App Store Connect
```

#### Web Build

```bash
# Build web
flutter build web --release

# Deploy (exemplo: Firebase Hosting)
firebase hosting:channel:deploy pr-123 --app=urbaos-web
```

### Monitoring & Logs

#### Firebase Console

```
1. Firestore → Usage
   - Ver reads/writes/deletes por dia
   - Alertas de limite
   
2. Authentication → Users
   - Monitorar logins
   - Gerenciar usuários
   
3. Performance Monitoring
   - Trace de operações lentas
   - Crashes
```

#### Client-Side Logging

```dart
// Adicionar logger (exemplo: logger package)
final logger = Logger();

logger.i('Service order created: $osId');
logger.e('Firebase sync failed', error: e);

// Enviar logs para Cloud Logging (via Backend)
Future<void> uploadLogs(List<LogEntry> logs) async {
  await _firestore
      .collection('app_logs')
      .add({
        'timestamp': Timestamp.now(),
        'userId': currentUser.uid,
        'entries': logs.map((e) => e.toMap()).toList(),
      });
}
```

### Database Migrations

#### Exemplo: Adicionar novo field

```dart
// 1. Criar migration job (Cloud Function)
export const migrateUsersAddDepartment = functions
  .pubsub.schedule('every 24 hours')
  .onRun(async (context) => {
    const users = await admin.firestore().collection('users').get();
    
    const batch = admin.firestore().batch();
    users.docs.forEach(doc => {
      if (!doc.data().department) {
        batch.update(doc.ref, {
          'department': 'all',  // Default
        });
      }
    });
    
    return batch.commit();
  });

// 2. Deploy
firebase deploy --only functions:migrateUsersAddDepartment

// 3. No app, atualizar modelo:
class User {
  final String department;  // Novo field (sempre com default)
}
```

---

## Troubleshooting

###1. **Erro: "FirebaseAuth not initialized"**

**Causa**: `Firebase.initializeApp()` não chamado antes de usar Firebase

**Solução**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // ← Adicionar
  runApp(MyApp());
}
```

---

### 2. **Erro: "Firestore permission denied (permission_denied)"**

**Causa**: Security Rules restritivas ou usuário não autenticado

**Solução**:
```firestore
# Verificar rules no Firebase Console
# Ou temporariamente permitir para debug:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;  # Apenas autenticado
    }
  }
}
```

---

### 3. **Erro: "FlutterError (Looking for Dialog widget in the widget tree, but none was found)"**

**Causa**: Tentando usar `context.pop()` sem estar em Navigator

**Solução**:
```dart
# Usar GoRouter em lugar de Navigator
context.pop();  # GoRouter

# Ou envolver em Scaffold:
Scaffold(
  body: MyWidget(),
)
```

---

### 4. **App Lento no Primeiro Load**

**Causa**: Firestore download de muitos documents  / Network lenta

**Solução**:
```dart
# 1. Usar paginação
.limit(20)  // Carregar 20 de uma vez
.orderBy('createdAt', descending: true)

# 2. Lazy load
.snapshots()
.skip(1)  // Skip initial value
.debounceTime(Duration(milliseconds: 500))

# 3. Índices no Firebase (melhor performance)
firestore createIndex service_orders (department, createdAt)
```

---

### 5. **BLoC Não Atualiza UI**

**Causa**: BLoC emitindo mesmo state; Equatable não configurado

**Solução**:
```dart
# Usar copyWith para novo estado sempre
emit(state.copyWith(users: newUserList));  # Novo objeto

# Verificar Equatable props:
class MyState extends Equatable {
  @override
  List<Object?> get props => [users, timestamp];  # Adicionar todos fields
}
```

---

### 6. **Erro: "MissingPluginException" em Android/iOS**

**Causa**: Plugin não registrado ou nativo code não compilado

**Solução**:
```bash
# Limpar build
flutter clean

# Reconstruir
flutter pub get
flutter run

# iOS específico
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter pub get
```

---

### 7. **Fotosupload Falha em Cloud Storage**

**Causa**: Sem permissão de escrita; arquivo muito grande

**Solução**:
```firestore
# Cloud Storage rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /photos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.resource.size < 10 * 1024 * 1024;  # 10MB max
    }
  }
}
```

---

### 8. **Real-Time update não funciona**

**Causa**: Stream não inicializado; subscription cancelada

**Solução**:
```dart
# Verificar subscription
if (_subscription != null) {
  _subscription!.cancel();
}

_subscription = repository.watchOrders(user).listen(
  (orders) {
    add(OrdersUpdated(orders));
  },
  onError: (error) {
    add(OrdersError(error.toString()));
  },
);

# No close():
@override
Future<void> close() {
  _subscription?.cancel();
  return super.close();
}
```

---

### 9. **Permissões GPS não Concedidas (Android/iOS)**

**Causa**: usuário recusou permissão; não solicitado na primeira execução

**Solução**:
```dart
# Usar geolocator com permission handling
import 'package:geolocator/geolocator.dart';

Future<void> requestLocationPermission() async {
  final permission = await Geolocator.requestPermission();
  
  if (permission == LocationPermission.deniedForever) {
    // Abrir settings
    await Geolocator.openLocationSettings();
  }
}

# Android - AndroidManifest.xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

# iOS - Info.plist
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track your position during service orders</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to track your position during service orders</string>
```

---

### 10. **Offline Mode Não Funciona**

**Causa**: Persistence não habilitado; ou dados nunca foram sincronizados

**Solução**:
```dart
# No main.dart, habilitar persistence
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

# iOS - Info.plist
<key>NSLocalNetworkUsageDescription</key>
<string>Allow for local network access</string>
```

---

## Conclusão & Next Steps

### Estado Atual da Aplicação

✅ **Implementado:**
- Autenticação com Firebase Auth + Custom Claims
- Gestão de Ordens de Serviço (CRUD completo)
- Aprovação de Materiais com workflow
- Rastreamento GPS em tempo real
- Dashboard com métricas em tempo real
- Gestão de usuários e departamentos
- Offline-first com cache persistente

⚠️ **Em Andamento:**
- Testes unitários abrangentes
- Testes de integração
- Performance tuning

❌ **Não Implementado (Backlog):**
- Relatórios/analytics
- Notificações push
- Sincronização bidirecional offline
- App signing & release channels
- A/B testing
- Monitoring/alerting

---

### Recomendações para Manutenção

1. **Monitorar Firestore Usage** (Dashboard Firebase)
2. **Testar Offline** regularmente
3. **Revisar Security Rules** mensalmente
4. **Atualizar dependências** (check `pub outdated`)
5. **Realizar backup de dados** (Firestore export)
6. **Implementar error tracking** (Sentry/Firebase Crashlytics)
7. **Performance monitoring** (Firebase Performance Monitoring)

---

**Documento Preparado Para:** Equipe de Manutenção & DevOps  
**Versão:** 1.0 - Baseline  
**Última Atualização:** 14 de abril de 2026

