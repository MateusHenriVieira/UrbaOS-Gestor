# UrbaOS Gestor

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?style=for-the-badge&logo=firebase)
![Architecture](https://img.shields.io/badge/Architecture-Clean-2E86AB?style=for-the-badge)
![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)

**Plataforma de gestão administrativa para UrbaOS - Gerenciamento de ordens de serviço, equipe técnica e aprovação de materiais**

[Documentação](#-documentação) • [Setup](#-setup-local) • [Arquitetura](#-arquitetura) • [Contribuindo](#-guia-de-contribuição)

</div>

---

## 📋 Visão Geral

**UrbaOS Gestor** é uma aplicação Flutter enterprise para gerenciamento de operações urbanas, desenvolvida seguindo princípios de **Clean Architecture** e **SOLID**. A plataforma permite que gerentes e coordenadores gerenciem:

- ✅ **Gestão de Equipe**: Criação, ativação e desativação de técnicos
- ✅ **Ordens de Serviço (OS)**: Criação, atualização e rastreamento de ordens
- ✅ **Aprovação de Materiais**: Fluxo de aprovação para solicitações de materiais
- ✅ **Monitoramento em Tempo Real**: Rastreamento GPS da frota e localização de técnicos
- ✅ **Dashboard Analítico**: Métricas e insights de operações
- ✅ **Suporte Offline**: Sincronização automática quando conectado

### 🎯 Casos de Uso Principais

| Módulo | Responsáveis | Funcionalidade |
|--------|-------------|-----------------|
| **User Management** | Gerentes | Criar/editar técnicos, gerenciar departamentos, controle de acesso |
| **Service Orders** | Coordenadores/Gerentes | Criar OS, atribuir técnicos, rastrear progresso |
| **Material Approvals** | Coordenadores | Aprovar/rejeitar solicitações de materiais |
| **Fleet Monitoring** | Gerentes | Rastrear GPS em tempo real, histórico de deslocamentos |
| **Dashboard** | Todos | Visualizar métricas, KPIs e status operacional |

---

## 🏗️ Arquitetura

A aplicação segue o padrão **Clean Architecture** com clara separação de responsabilidades:

### Camadas de Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (UI)                     │
│  Pages → Widgets → BLoCs → State Management (Riverpod)  │
├─────────────────────────────────────────────────────────┤
│           DOMAIN LAYER (Business Logic)                  │
│    Entities → Repositories (Abstract) → Use Cases        │
├─────────────────────────────────────────────────────────┤
│              DATA LAYER (External Data)                  │
│   Data Sources → Repository Impl → Models → Mappers     │
├─────────────────────────────────────────────────────────┤
│              INFRASTRUCTURE                              │
│  Firebase Core → Firestore → Auth → Storage → Location  │
└─────────────────────────────────────────────────────────┘
```

### Padrões de Design Utilizados

- **BLoC Pattern**: Gerenciamento de estado e lógica de apresentação
- **Repository Pattern**: Abstração de fontes de dados
- **Dependency Injection**: GetIt Service Locator
- **Factory Pattern**: Criação de instâncias de BLoCs
- **Mapper Pattern**: Conversão entre modelos

### Estrutura de Diretórios

```
lib/
├── main.dart                          # Entry point da aplicação
├── firebase_options.dart              # Configuração Firebase
├── injection_container.dart           # Setup de DI (GetIt + BLoCs)
│
├── core/                              # Compartilhado entre features
│   ├── constants/                     # Constantes globais
│   ├── errors/
│   │   ├── exceptions.dart           # Exceções customizadas
│   │   └── failures.dart             # Failures pattern
│   ├── layout/                        # Layouts reutilizáveis
│   ├── network/                       # Utilitários de rede
│   ├── routes/
│   │   └── app_router.dart           # GoRouter configuration
│   ├── theme/
│   │   └── app_theme.dart            # Material Theme
│   ├── utils/
│   │   ├── formatters.dart
│   │   ├── validators.dart
│   │   └── extensions.dart
│   └── widgets/                       # Widgets reutilizáveis
│
├── features/                          # Feature modules
│   │
│   ├── auth/                          # Autenticação
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/          # Firebase Auth impl
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── logged_user.dart  # LoggedUser entity
│   │   │   └── repositories/          # Auth abstract repository
│   │   └── presentation/
│   │       ├── bloc/                  # AuthBloc (Global state)
│   │       └── pages/                 # Login pages
│   │
│   ├── user_management/              # Gestão de Equipe
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/          # Firebase User impl
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart         # User entity
│   │   │   └── repositories/          # User abstract repository
│   │   └── presentation/
│   │       ├── bloc/                  # UserManagementBloc
│   │       ├── pages/
│   │       │   ├── create_technician_page.dart
│   │       │   └── settings_page.dart
│   │       └── widgets/               # Custom widgets
│   │
│   ├── service_orders/               # Ordens de Serviço
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/          # Firebase ServiceOrder impl
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── service_order.dart
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       │   ├── service_orders_page.dart
│   │       │   ├── os_details_page.dart
│   │       │   └── create_os_page.dart
│   │       └── widgets/
│   │
│   ├── material_approvals/           # Aprovação de Materiais
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── material_request.dart
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       │   ├── materials_page.dart
│   │       │   ├── quick_approval_page.dart
│   │       │   └── tech_history_page.dart
│   │       └── widgets/
│   │
│   ├── gps_monitoring/               # Rastreamento GPS
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── fleet_monitoring/             # Monitoramento de Frota
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── dashboard/                    # Dashboard Analítico
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── tracking/                     # Rastreamento em Tempo Real
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── utils/                             # Utilitários gerais
    ├── logger.dart
    └── extensions.dart
```

---

## 📦 Dependências Principais

### State Management & DI
```yaml
flutter_bloc: ^8.1.2          # State management
flutter_riverpod: ^2.5.1      # Reactive data
get_it: ^7.4.0                # Dependency injection
```

### Backend & Firebase
```yaml
firebase_core: ^4.6.0         # Firebase core
firebase_auth: ^6.3.0         # Authentication
cloud_firestore: ^6.2.0       # Database
firebase_storage: ^13.2.0     # File storage
firebase_database: ^12.2.0    # Realtime database
```

### Navigation & Routing
```yaml
go_router: ^14.0.0            # Advanced routing
```

### Location & Maps
```yaml
geolocator: ^12.0.0           # Location services
geocoding: ^3.0.0             # Geocoding
flutter_map: ^6.1.0           # Mapping
latlong2: ^0.9.1              # Coordinates
flutter_background_service: ^5.0.5  # Background location
```

### Utilities
```yaml
intl: ^0.20.0                 # Internationalization
```

---

## 🚀 Setup Local

### Pré-requisitos

- **Flutter**: 3.11.0 ou superior
- **Dart**: 3.11.4 ou superior
- **Xcode** (macOS): 14.0+ para desenvolvimento iOS
- **Android Studio**: 2022.1+ para desenvolvimento Android
- **Git**: Controle de versão

### Passos de Instalação

#### 1. **Clone o Repositório**
```bash
git clone https://github.com/mateushenrivieira/urbaos-gestor.git
cd urbaos_gestor
```

#### 2. **Configure o Ambiente Flutter**
```bash
# Verifique a instalação
flutter doctor

# Obtenha dependências
flutter pub get

# (Opcional) Gere código automático
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. **Configure Firebase**

**Para iOS:**
```bash
cd ios
pod install --repo-update
cd ..
```

**Para Android:**
- Atualize `android/app/build.gradle` se necessário
- Configure `google-services.json` (fornecido pela Firebase)

#### 4. **Configure Variáveis de Ambiente**

Crie um arquivo `.env` na raiz do projeto (não commitir):
```bash
# .env (NUNCA commitar para repositório)
FIREBASE_PROJECT_ID=urbaos-309a2
FIREBASE_API_KEY=AIzaSyC37L_6BaqtvLjV_XTqwq_o6-Z4M5OtYZ0
```

#### 5. **Execute a Aplicação**

**Modo Debug:**
```bash
flutter run
```

**Modo Release:**
```bash
flutter run --release
```

**Para plataforma específica:**
```bash
flutter run -d ios          # iOS
flutter run -d android      # Android
flutter run -d chrome       # Web
```

---

## 🔑 Configuração Firebase

### Projeto Firebase

| Propriedade | Valor |
|------------|-------|
| Project ID | `urbaos-309a2` |
| Auth Domain | `urbaos-309a2.firebaseapp.com` |
| Storage Bucket | `urbaos-309a2.firebasestorage.app` |

### Serviços Habilitados

1. **Firebase Authentication**
   - Email/Senha
   - Custom Claims (role, department)
   - Session persistence

2. **Cloud Firestore**
   - Collections: users, service_orders, material_requests, tracking
   - Modo offline com cache
   - Índices compostos para queries avançadas

3. **Firebase Storage**
   - Fotos de ordens de serviço
   - Documentos de localização

4. **Realtime Database**
   - Localização em tempo real
   - Mensagens instantâneas

### Estrutura Firestore

```
├── users/
│   └── {userId}
│       ├── name: String
│       ├── email: String
│       ├── role: String (manager|coordinator|technician)
│       ├── department: String (obras|hidricos|all)
│       ├── isActive: Boolean
│       ├── createdAt: Timestamp
│       └── lastLoginAt: Timestamp
│
├── service_orders/
│   └── {orderId}
│       ├── title: String
│       ├── description: String
│       ├── status: String (aberta|andamento|concluida)
│       ├── technicianId: String
│       ├── technicianName: String
│       ├── createdBy: String
│       ├── createdAt: Timestamp
│       └── materials: Array<String>
│
└── material_requests/
    └── {requestId}
        ├── serviceOrderId: String
        ├── technicianId: String
        ├── items: Array<String>
        ├── status: String (pending|approved|rejected)
        ├── createdAt: Timestamp
        └── approvedBy: String
```

---

## 🔐 Autenticação & Autorização

### Papéis de Usuário (Roles)

| Role | Permissões | Acesso |
|------|-----------|--------|
| **Manager** | Gerenciamento completo | Ambas secretarias (Obras + Hídricos) |
| **Coordinator** | Gerenciamento limitado | Apenas sua secretaria |
| **Technician** | Leitura/Execução | Suas próprias tarefas |

### Custom Claims

Os usuários têm `idToken.claims` com:
```json
{
  "role": "manager|coordinator|technician",
  "department": "obras|hidricos|all",
  "isManager": true/false,
  "isCoordinator": true/false
}
```

### Fluxo de Autenticação

```
1. Usuário faz login (email + senha)
2. Firebase autentica e retorna idToken
3. Custom claims extraídos do token
4. LoggedUser criado com role e department
5. State global (AuthBloc) atualizado
6. Rotas e widgets restritos por role
```

---

## 📊 Fluxo de Dados

### Exemplo: Criação de Ordem de Serviço

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. CreateOSPage (Widget) - UI                                    │
│    └─> UserAction: "Create Order"                                │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│ 2. CreateOrderBloc (State Management) - add(CreateOSEvent)      │
│    └─> emit(CreateOSLoading())                                   │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│ 3. Repository.createServiceOrder(serviceOrder)                  │
│    └─> Chama data layer                                          │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│ 4. FirebaseServiceOrdersRepository                              │
│    └─> Mapper: Entity → Model                                    │
│    └─> Firestore.collection('service_orders').add(model)        │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│ 5. Firebase Firestore (Backend)                                 │
│    └─> Persiste documento                                        │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│ 6. Resultado retorna para BLoC                                  │
│    └─> emit(CreateOSSuccess(orderId))                            │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│ 7. Widget Rebuild                                               │
│    └─> ShowSuccessSnackbar + Navigate                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧪 Testes

### Estrutura de Testes

```bash
test/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── user_management/
│   ├── service_orders/
│   └── material_approvals/
└── core/
```

### Executar Testes

```bash
# Todos os testes
flutter test

# Testes com coverage
flutter test --coverage

# Teste específico
flutter test test/features/auth/domain/usecases_test.dart

# Watch mode
flutter test --watch
```

---

## 🐛 Troubleshooting

### Problema: "Podspec not found"
```bash
cd ios
rm Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### Problema: "Target ... is configured with Pods-Runner platform :ios, '11.0'"
```bash
# Atualize ios/Podfile:
platform :ios, '12.0'  # ou superior

cd ios && pod repo update && pod install
```

### Problema: "Firebase initialization timeout"
```bash
# Verificar se está conectado
flutter pub get

# Limpar cache
flutter clean

# Rebuild
flutter run
```

### Problema: "Gold Master (GM) snapshot not available"
```bash
# Downgrade Xcode ou atualize Flutter
flutter channel stable
flutter upgrade
```

---

## 📚 Documentação

| Documento | Descrição |
|-----------|-----------|
| [ARQUITETURA_E_DIAGRAMAS.md](docs/ARQUITETURA_E_DIAGRAMAS.md) | Diagramas de fluxo e decisões arquiteturais |
| [DOCUMENTACAO_TECNICA_COMPLETA.md](docs/DOCUMENTACAO_TECNICA_COMPLETA.md) | Especificações técnicas detalhadas |
| [DEPLOYMENT_INSTRUCTIONS.md](docs/DEPLOYMENT_INSTRUCTIONS.md) | Instruções de CI/CD e deploy |
| [GUIA_SETUP_OPERACOES.md](docs/GUIA_SETUP_OPERACOES.md) | Setup de operações e configurações |
| [DIAGNOSTICO_LIVE_TRACKING.md](docs/DIAGNOSTICO_LIVE_TRACKING.md) | Troubleshooting do módulo de tracking |

### Links Úteis

- [Flutter Official Docs](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Clean Architecture em Flutter](https://resocoder.com/flutter-clean-architecture)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Riverpod Documentation](https://riverpod.dev/)

---

## 🤝 Guia de Contribuição

### Fluxo de Contribuição

1. **Crie uma branch**
   ```bash
   git checkout -b feature/nova-funcionalidade
   ```

2. **Faça suas alterações**
   - Siga o padrão de código estabelecido
   - Mantenha a separação de camadas (Clean Architecture)
   - Adicione testes para novas funcionalidades

3. **Commit com mensagens claras**
   ```bash
   git commit -m "feat(user_management): adiciona filtro por departamento"
   git commit -m "fix(service_orders): corrige cálculo de status"
   git commit -m "docs: atualiza README com instruções"
   ```

4. **Abra um Pull Request**
   - Descreva as mudanças
   - Referencia issues relacionadas
   - Aguarde revisão

### Padrões de Código

#### Nomenclatura

```dart
// Features
FeatureName/          # PascalCase
└── presentation/     # Apresentação (UI, BLoC)
    └── bloc/         # BLoCs - xyz_bloc.dart, xyz_event.dart, xyz_state.dart
    └── pages/        # Pages - xyz_page.dart
    └── widgets/      # Widgets - xyz_widget.dart
└── domain/           # Lógica de negócio
    └── entities/     # Modelos puros - xyz.dart
    └── repositories/ # Abstratos - xyz_repository.dart
└── data/             # Acesso a dados
    └── datasources/  # Fontes - xyz_datasource.dart
    └── models/       # Modelos Firebase - xyz_model.dart
    └── repositories/ # Implementação - firebase_xyz_repository.dart
```

#### Arquivo de Feature

```dart
// feature/xyz/presentation/bloc/xyz_bloc.dart

// 1. Events
abstract class XyzEvent extends Equatable {}
class LoadXyzEvent extends XyzEvent { ... }
class UpdateXyzEvent extends XyzEvent { ... }

// 2. States
abstract class XyzState extends Equatable {}
class XyzInitial extends XyzState {}
class XyzLoading extends XyzState {}
class XyzSuccess extends XyzState { final data; }
class XyzError extends XyzState { final message; }

// 3. BLoC
class XyzBloc extends Bloc<XyzEvent, XyzState> {
  XyzBloc(this.repository) : super(XyzInitial()) {
    on<LoadXyzEvent>(_onLoad);
    on<UpdateXyzEvent>(_onUpdate);
  }

  Future<void> _onLoad(LoadXyzEvent event, Emitter emit) async { ... }
  Future<void> _onUpdate(UpdateXyzEvent event, Emitter emit) async { ... }
}
```

#### Organização de Imports

```dart
// 1. Dart
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Packages
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Projeto
import 'package:urbaos_gestor/core/constants/constants.dart';
import 'package:urbaos_gestor/features/auth/presentation/bloc/auth_bloc.dart';
```

### Checklist de PR

- [ ] Testes unitários adicionados
- [ ] Testes de widget adicionados
- [ ] Code coverage > 80%
- [ ] Sem warnings de análise estática
- [ ] Documentação atualizada
- [ ] Commits com mensagens claras
- [ ] Sem código duplicado

---

## 📊 Métricas & Performance

### Monitoramento

- **Performance**: Flutter DevTools
- **Análise**: `flutter analyze`
- **Testes**: `flutter test --coverage`

### Otimizações Aplicadas

- ✅ Lazy loading de telas
- ✅ Offline-first com Firestore cache
- ✅ Streams eficientes com BLoC
- ✅ Widget rebuild otimizado
- ✅ Compressão de imagens

---

## 📞 Contato & Suporte

| Canal | Contato |
|-------|---------|
| **Email** | dev@urbaos.com.br |
| **Issues** | [GitHub Issues](https://github.com/mateushenrivieira/urbaos-gestor/issues) |
| **Slack** | #dev-urbaos |
| **Wiki** | [Team Wiki](https://wiki.internal.com/urbaos) |

---

## 📄 Licença

Este projeto é **Propriedade Privada**. Distribuição não autorizada é proibida.

© 2024 UrbaOS. Todos os direitos reservados.

---

## 🎯 Roadmap

- [ ] **v1.1.0** - Aprovação de materiais em lote
- [ ] **v1.2.0** - Relatórios PDF exportáveis
- [ ] **v1.3.0** - Integrações com WhatsApp/SMS
- [ ] **v2.0.0** - Suporte offline completo
- [ ] **v2.1.0** - Machine Learning para previsão de demanda

---

<div align="center">

**⭐ Se este projeto é útil, considere dar uma estrela!**

Desenvolvido com ❤️ pela equipe UrbaOS

</div>
