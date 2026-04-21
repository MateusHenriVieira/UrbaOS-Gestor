# UrbaOS - Gestor | Arquitetura & Diagramas

**Referência Visual da Arquitetura da Aplicação**

---

## 1. Arquitetura de Camadas (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL (Firebase, APIs)                    │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Firebase Auth    │  │ Cloud Firestore  │  │ Cloud Storage│  │
│  │ Admin SDK        │  │ Real-time DB     │  │ (Fotos)      │  │
│  │ Custom Claims    │  │ + Offline Cache  │  │              │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
└────────────────────────────────┬──────────────────────────────────┘
                                 ↑
                         (Firestore SDK)
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER (Repositories)                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ FirebaseAuthRepository          │ FirebaseDashboardRepos   │ │
│  │ FirebaseServiceOrdersRepository │ FirebaseMaterialRepos    │ │
│  │ FirebaseUserManagementRepos     │ FirebaseLocationRepos    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  (Implement Domain Layer Abstractions)                           │
│  └─ AuthRepository                                              │
│  └─ ServiceOrdersRepository                                     │
│  └─ MaterialRequestsRepository                                  │
│  └─ etc.                                                        │
└────────────────────────────────┬────────────────────────────────┘
                                 ↑
                         (GetIt Injection)
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER (Business Logic)                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Entities:                                                  │ │
│  │  ├─ LoggedUser, ServiceOrder                              │ │
│  │  ├─ MaterialRequest, User, Location                       │ │
│  │  ├─ DashboardMetrics                                      │ │
│  │                                                            │ │
│  │  Repositories (Abstract):                                  │ │
│  │  ├─ AuthRepository                                        │ │
│  │  ├─ ServiceOrdersRepository                               │ │
│  │  ├─ MaterialRequestsRepository                            │ │
│  │  └─ etc.                                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  (No Use Cases - lógica está nos BLoCs)                         │
└────────────────────────────────┬────────────────────────────────┘
                                 ↑
                         (Repositories)
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (UI + State Management)          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ BLoCs (State Management):                                  │ │
│  │ ├─ AuthBloc (Singleton)      ← Global Auth State         │ │
│  │ ├─ DashboardBloc (Factory)   ← Route-scoped               │ │
│  │ ├─ ServiceOrdersBloc (Factory)                            │ │
│  │ ├─ MaterialsBloc (Factory)                                │ │
│  │ ├─ FleetMonitoringBloc (Factory)                          │ │
│  │ └─ etc.                                                   │ │
│  │                                                            │ │
│  │ Events, States                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Pages (Stateless Widgets):                                │ │
│  │ ├─ LoginPage                                              │ │
│  │ ├─ DashboardPage                                          │ │
│  │ ├─ ServiceOrdersPage                                      │ │
│  │ ├─ OSDetailsPage                                          │ │
│  │ ├─ CreateOSPage                                           │ │
│  │ ├─ MaterialsPage                                          │ │
│  │ ├─ etc.                                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Navigation:                                               │ │
│  │ └─ GoRouter (Declarative routing)                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                 ↑
                    (BlocBuilder, BlocListener)
                                 ↓
                         ┌────────────────┐
                         │  Device User   │
                         │  (Interations) │
                         └────────────────┘
```

---

## 2. Data Flow - Arquitetura de Dados

```
┌──────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                           │
│                          (Tap, Scroll)                            │
└────────────────────────────┬─────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────────────┐
│                      PAGE / WIDGET                                │
│                   (Stateless / Stateful)                         │
└────────────────────────────┬─────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────────────┐
│                    BLoC EVENT (Command)                           │
│             bloc.add(MyEvent(data))                              │
│              └─ Fired by user action                            │
└────────────────────────────┬─────────────────────────────────────┘
                             ↓
┌──────────────────────────────────────────────────────────────────┐
│                    BLoC EVENT HANDLER                             │
│             on<MyEvent>((event, emit) => {})                     │
│              └─ Process event                                    │
└────────────────────────────┬─────────────────────────────────────┘
                             ↓
         ┌───────────────────┴────────────────────┐
         ↓                                        ↓
   (1) Call Repository              (2) Emit State (immediately)
        (Async)                          (optimistic)
         ↓                                        ↓
    ┌─────────────┐                    ┌──────────────────┐
    │ Get Data    │──────────────────→ │ BLoC State       │
    │ from        │                    │ Updated          │
    │ Firestore   │                    └──────┬───────────┘
    │ or create   │                           ↓
    │ transaction │                    BlocBuilder Listens
    └─────────────┘                    Rebuilds UI
         ↓ (Response)
    ┌──────────────────┐
    │ Update State     │
    │ with new data    │
    └────┬─────────────┘
         ↓
    Emit Final State
         ↓
    UI Rebuilds with
    new data/status
```

---

## 3. Feature: Dashboard Real-Time

```
┌────────────────────────────────────────────────────┐
│        USER NAVIGATES TO /dashboard                │
└──────────────────┬─────────────────────────────────┘
                   ↓
        ┌─────────────────────────┐
        │ BlocProvider            │
        │ <DashboardBloc>         │
        │ (Factory - new instance)│
        └────┬────────────────────┘
             ↓
    ┌────────────────────────┐
    │ DashboardBloc created  │
    │ add:                   │
    │ LoadDashboardRequested │
    │ (with user data)       │
    └────┬───────────────────┘
         ↓
    ┌─────────────────────────────────────┐
    │ FirebaseDashboardRepository         │
    │ getMetricsStream(user)              │
    │ ├─ watchOrders(user)     (Stream)   │
    │ └─ watchMaterials(user)  (Stream)   │
    └────┬──────────────────────────────────┘
         ↓
    ┌───────────────────────────────────────┐
    │ Firestore Real-Time Listener          │
    │ service_orders.where(...)             │
    │        .orderBy('createdAt')          │
    │        .snapshots()                   │
    │           ↓                           │
    │ (Emits whenever data changes)         │
    └────┬────────────────────────────────────┘
         ↓
    ┌────────────────────────────┐
    │ Metrics Calculated         │
    │ ├─ openOs                  │
    │ ├─ inProgressOs            │
    │ ├─ pendingReviewOs         │
    │ └─ pendingMaterials        │
    │         ↓                  │
    │ DashboardMetrics created   │
    └────┬───────────────────────┘
         ↓
    ┌──────────────────────────┐
    │ BLoC Emits State:        │
    │ DashboardLoaded(metrics) │
    └────┬─────────────────────┘
         ↓
    ┌──────────────────────────────┐
    │ BlocBuilder Rebuilds         │
    │ DashboardPage receives       │
    │ new metrics                  │
    └────┬─────────────────────────┘
         ↓
    ┌──────────────────────────────┐
    │ UI Updates:                  │
    │ ├─ KPI Cards               │
    │ ├─ Recent Orders List       │
    │ └─ Loading indicators       │
    └──────────────────────────────┘

    ┌─────────────────┐
    │ STREAM CONTINUES        
    │ (Real-time updates)     
    │ Whenever someone        
    │ creates/updates OS:     
    │ └─ Firestore emits      
    │ └─ Metrics recalculated 
    │ └─ BLoC emits new state 
    │ └─ UI updates           
    └─────────────────┘
```

---

## 4. Fluxo Offline-First

```
┌─────────────────────────────────────────────────────────────┐
│                     APP STARTUP                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 1. Initialize                                           │ │
│ │    ├─ Firebase.initializeApp()                         │ │
│ │    ├─ FirebaseFirestore.settings (persistence: true)   │ │
│ │    └─ GetIt.init()                                     │ │
│ └─────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 2. Check Device Connectivity                            │ │
│ │    ├─ If HAS INTERNET                                  │ │
│ │    │  └─ Fetch data from server                       │ │
│ │    │  └─ Cache locally                                 │ │
│ │    └─ If NO INTERNET                                  │ │
│ │       └─ Read from local cache                        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 3. Stream Query                                          │ │
│ │    └─ firestore                                        │ │
│ │       .collection(...)                                │ │
│ │       .snapshots()  ← Firestore intelligently:       │ │
│ │         ├─ Returns cache immediately                 │ │
│ │         ├─ Syncs with server (if online)            │ │
│ │         └─ Emits new snapshots on changes           │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│           OFFLINE SCENARIO (No Internet)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌──────┐              ┌──────────────┐                      │
│ │ User │              │   Query      │                      │
│ │ Taps │─────────────→│ Firestore    │                      │
│ │ Button              │ Collection   │                      │
│ └──────┘              └──────┬───────┘                       │
│                              ↓                               │
│                   ┌──────────────────┐                       │
│                   │ NO INTERNET      │                       │
│                   │ Check cache      │                       │
│                   │ ✅ Cache exists  │                       │
│                   └──────┬───────────┘                       │
│                          ↓                                   │
│                   ┌──────────────────┐                       │
│                   │ Return cached    │                       │
│                   │ data immediately │                       │
│                   │ (No delay)       │                       │
│                   └──────┬───────────┘                       │
│                          ↓                                   │
│                   ┌──────────────────┐                       │
│                   │ User sees data   │                       │
│                   │ from App         │                       │
│                   │ (Works offline!) │                       │
│                   └──────────────────┘                       │
│                                                              │
│ ┌───────────────────────────────────┐                        │
│ │ User makes LOCAL CHANGES:         │                        │
│ │ ├─ Create new OS                 │                        │
│ │ ├─ Edit service order status     │                        │
│ │ └─ Approve material request      │                        │
│ │          ↓                        │                        │
│ │ ┌─────────────────────────────┐  │                        │
│ │ │ Save to Local Cache          │  │                        │
│ │ │ Mark as 'syncing'            │  │                        │
│ │ │ UI updates immediately       │  │                        │
│ │ │ (Optimistic update)          │  │                        │
│ │ └─────────────────────────────┘  │                        │
│ │          ↓                        │                        │
│ │ ┌─────────────────────────────┐  │                        │
│ │ │ Queue change for later sync │  │                        │
│ │ │ (pending_sync collection)   │  │                        │
│ │ └─────────────────────────────┘  │                        │
│ └───────────────────────────────────┘                        │
│                                                              │
│ ┌───────────────────────────────────┐                        │
│ │ INTERNET RETURNS                  │                        │
│ │ ├─ Device detects connection      │                        │
│ │ ├─ App listens to Connectivity    │                        │
│ │ │  changes                        │                        │
│ │ └─ Trigger sync job               │                        │
│ │                                   │                        │
│ │ ┌─────────────────────────────┐  │                        │
│ │ │ Sync pending_sync queue:    │  │                        │
│ │ │ ├─ For each pending change  │  │                        │
│ │ │ │  └─ POST to Firestore    │  │                        │
│ │ │ ├─ Wait for confirmation    │  │                        │
│ │ │ └─ Mark as 'synced'        │  │                        │
│ │ └─────────────────────────────┘  │                        │
│ │          ↓                        │                        │
│ │ ┌─────────────────────────────┐  │                        │
│ │ │ Firestore updates           │  │                        │
│ │ │ All subscribers notified     │  │                        │
│ │ │ UI updates with real IDs    │  │                        │
│ │ │ (from server)                │  │                        │
│ │ └─────────────────────────────┘  │                        │
│ └───────────────────────────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Fluxo de Autenticação

```
┌──────────────────────────────────────────────────────────────┐
│                    LOGIN FLOW                                 │
└────────────────────┬─────────────────────────────────────────┘
                     ↓
         ┌──────────────────────────┐
         │ LoginPage               │
         │ Email + Password Input   │
         │ [Sign In Button]         │
         └───────┬──────────────────┘
                 ↓
    ┌────────────────────────────────┐
    │ BLoC.add(                      │
    │  SignInRequested(              │
    │    email,                      │
    │    password                    │
    │  )                             │
    │ )                              │
    └────┬─────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ FirebaseAuthRepository.signIn()          │
    │  1. FirebaseAuth.signInWithEmailPassword │
    │  2. Get tokenResult (has Custom Claims)  │
    │  3. Read users/{uid} doc from Firestore  │
    │  4. Map to LoggedUser                    │
    └────┬──────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────┐
    │ IF SUCCESS:                         │
    │ AuthBloc emits                      │
    │ AuthAuthenticated(loggedUser)       │
    │      ↓                              │
    │ GoRouter.redirect()                 │
    │ Navigates to /dashboard             │
    └─────────────────────────────────────┘

    ┌─────────────────────────────────────┐
    │ IF FAILURE (e.g. wrong password):   │
    │ AuthBloc emits                      │
    │ AuthError("Password incorrect")     │
    │      ↓                              │
    │ UI shows error Snackbar             │
    │ Stays on /login                     │
    └─────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              SESSION PERSISTENCE                              │
│                                                              │
│ App Starts:                                                  │
│  ├─ AuthBloc.add(AuthCheckRequested())                      │
│  ├─ Repository.getCurrentUser()                             │
│  ├─ FirebaseAuth.currentUser exists?                        │
│  │   ├─ YES: Fetch users/{uid} doc                         │
│  │   │       Return LoggedUser                             │
│  │   └─ NO: return null                                     │
│  ├─ Emit AuthAuthenticated or Unauthenticated              │
│  └─ GoRouter.redirect() to appropriate page                │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              LOGOUT FLOW                                      │
│                                                              │
│ User taps Logout button:                                    │
│  ├─ BLoC.add(SignOutRequested())                           │
│  ├─ FirebaseAuthRepository.signOut()                        │
│  │  └─ FirebaseAuth.signOut()                              │
│  ├─ AuthBloc emits AuthUnauthenticated                     │
│  └─ GoRouter.redirect() to /login                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 6. Fluxo de Criação de Ordem de Serviço

```
┌────────────────────────────────────────────────────────────────┐
│        USER ON SERVICE ORDERS PAGE (/os)                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────┐                                                │
│  │ FAB Button │  "Nova OS"                                     │
│  │   [+]      │                                                │
│  └─────┬──────┘                                                │
│        │ tap                                                   │
│        ↓                                                       │
│  ┌───────────────────────────────────────────┐                │
│  │ context.push('/create-os')                │                │
│  │ GoRouter routes to CreateOSPage           │                │
│  └───────────────────────────────────────────┘                │
│        ↓                                                       │
│  ┌───────────────────────────────────────────┐                │
│  │ BlocProvider<CreateOrderBloc>             │                │
│  │ (Factory - new instance)                  │                │
│  └───────────────────────────────────────────┘                │
│        ↓                                                       │
│  ┌───────────────────────────────────────────┐                │
│  │ CreateOSPage Renders Form:                │                │
│  │ ├─ Title TextField                        │                │
│  │ ├─ Description TextField                  │                │
│  │ ├─ Department Dropdown                    │                │
│  │ │  └─ Fetch users with role='technician' │                │
│  │ │     Real-time stream                    │                │
│  │ ├─ Technician Dropdown                    │                │
│  │ │  (Populated dynamically)                │                │
│  │ └─ [Criar OS] Button                      │                │
│  └───────────────────────────────────────────┘                │
│        ↓                                                       │
│  ┌───────────────────────────────────────────┐                │
│  │ USER INPUT:                               │                │
│  │ ├─ Title: "Conserto de Vazamento"        │                │
│  │ ├─ Dept: "Hidricos"                       │                │
│  │ ├─ Tech: "João Silva"                     │                │
│  │ └─ Desc: "Vazamento no cano da rua..."   │                │
│  └───────────────────────────────────────────┘                │
│        ↓                                                       │
│  ┌───────────────────────────────────────────┐                │
│  │ User taps [Criar OS]                      │                │
│  └───────────────────────────────────────────┘                │
│        ↓                                                       │
│  ┌───────────────────────────────────────────┐                │
│  │ Form Validation:                          │                │
│  │ ├─ Title not empty? ✅                   │                │
│  │ ├─ Description not empty? ✅            │                │
│  │ ├─ Technician selected? ✅              │                │
│  │ └─ All ok, proceed ✅                    │                │
│  └───────────────────────────────────────────┘                │
│        ↓                                                       │
│  ┌────────────────────────────────────────────┐               │
│  │ BLoC.add(CreateOSRequested(               │               │
│  │   title,                                   │               │
│  │   description,                             │               │
│  │   department,                              │               │
│  │   technicianId,                            │               │
│  │   currentUser                              │               │
│  │ ))                                         │               │
│  └────┬─────────────────────────────────────────┘              │
│       ↓                                                        │
│  ┌────────────────────────────────────────────┐               │
│  │ CreateOrderBloc Handler:                   │               │
│  │ on<CreateOSRequested>((event, emit) {      │               │
│  │   emit(CreateOSLoading());                │               │
│  │                                            │               │
│  │   try {                                    │               │
│  │     final os = ServiceOrder(               │               │
│  │       title: event.title,                 │               │
│  │       ...                                  │               │
│  │       status: 'aberta',   ← Default        │               │
│  │       createdBy: event.user.uid,          │               │
│  │       createdAt: DateTime.now(),          │               │
│  │     );                                     │               │
│  │                                            │               │
│  │     await repository.createServiceOrder()  │               │
│  │     emit(CreateOSSuccess());              │               │
│  │   } catch (e) {                            │               │
│  │     emit(CreateOSError(e.message));       │               │
│  │   }                                        │               │
│  │ })                                         │               │
│  └────┬─────────────────────────────────────────┘              │
│       ↓                                                        │
│  ┌────────────────────────────────────────────┐               │
│  │ Repository.createServiceOrder():           │               │
│  │ ├─ os.toMap()  ← Serializa SD            │               │
│  │ ├─ firestore                              │               │
│  │ │  .collection('service_orders')          │               │
│  │ │  .add(osMap)  ← Auto-gen ID             │               │
│  │ └─ Return (Firebase saves)                │               │
│  └────┬─────────────────────────────────────────┘              │
│       ↓                                                        │
│  ┌────────────────────────────────────────────┐               │
│  │ FIREBASE WRITES TO REALTIME:               │               │
│  │ ├─ Saves document to collection           │               │
│  │ ├─ Generates unique ID                    │               │
│  │ ├─ Notifies all subscribers of /os        │               │
│  │ │  (ServiceOrdersBloc listening)          │               │
│  │ └─ Real-time stream emits new list        │               │
│  └────┬─────────────────────────────────────────┘              │
│       ↓                                                        │
│  ┌────────────────────────────────────────────┐               │
│  │ BLocEmits CreateOSSuccess()                │               │
│  │      ↓                                     │               │
│  │ UI Renders:                                │               │
│  │ ├─ SnackBar: "OS Criada com sucesso!" │               │
│  │ └─ pop() → Returns to /os              │               │
│  └────┬────────────────────────────────────────┘              │
│       ↓                                                        │
│  ┌────────────────────────────────────────────┐               │
│  │ ServiceOrdersPage Rebuilds:                │               │
│  │ ├─ Stream emits new full list             │               │
│  │ ├─ New OS appears in top of list          │               │
│  │ ├─ Status: 'aberta' (badge color)        │               │
│  │ └─ Technician preview visible            │               │
│  └────────────────────────────────────────────┘               │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## 7. Firestore Collections Diagram

```
DATABASE: urbaos_admin (Firestore)

├─ 📁 users {Collection}
│  ├─ {uid_manager_1}
│  │  ├─ id: "uid_manager_1"
│  │  ├─ name: "João Manager"
│  │  ├─ email: "joao@urbaos.com"
│  │  ├─ role: "manager"
│  │  ├─ department: "all"
│  │  ├─ isActive: true
│  │  ├─ createdAt: {timestamp}
│  │  └─ lastLoginAt: {timestamp}
│  │
│  ├─ {uid_coord_1}
│  │  ├─ id: "uid_coord_1"
│  │  ├─ name: "Maria Coordenadora"
│  │  ├─ email: "maria@urbaos.com"
│  │  ├─ role: "coordinator"
│  │  ├─ department: "obras"
│  │  ├─ isActive: true
│  │  ├─ createdAt: {timestamp}
│  │  └─ lastLoginAt: {timestamp}
│  │
│  └─ {uid_tech_1}
│     ├─ id: "uid_tech_1"
│     ├─ name: "Paulo Técnico"
│     ├─ email: "paulo@urbaos.com"
│     ├─ role: "technician"
│     ├─ department: "hidricos"
│     ├─ isActive: true
│     ├─ createdAt: {timestamp}
│     └─ lastLoginAt: {timestamp}
│
├─ 📁 service_orders {Collection}
│  ├─ {osId_1}
│  │  ├─ id: "osId_1"
│  │  ├─ title: "Reparação de Asfalto"
│  │  ├─ description: "Buraco na Av. Principal..."
│  │  ├─ status: "aberta"
│  │  ├─ department: "obras"
│  │  ├─ technicianId: "uid_tech_1"
│  │  ├─ technicianName: "Paulo Técnico"
│  │  ├─ createdBy: "uid_coord_1"
│  │  ├─ createdByName: "Maria Coordenadora"
│  │  ├─ createdAt: {timestamp}
│  │  ├─ photoUrl: "gs://bucket/photos/os_1.jpg"
│  │  └─ locationUrl: "https://maps.google.com/..."
│  │
│  └─ {osId_2}
│     ├─ id: "osId_2"
│     ├─ title: "Conserto de Vazamento"
│     ├─ description: "Tubo rompido na R. das Flores..."
│     ├─ status: "em_andamento"
│     ├─ department: "hidricos"
│     ├─ technicianId: "uid_tech_2"
│     ├─ technicianName: "Carlos Técnico"
│     ├─ createdBy: "uid_coord_1"
│     ├─ createdByName: "Maria Coordenadora"
│     ├─ createdAt: {timestamp}
│     ├─ photoUrl: null
│     └─ locationUrl: null
│
├─ 📁 material_requests {Collection}
│  ├─ {requestId_1}
│  │  ├─ id: "requestId_1"
│  │  ├─ technicianId: "uid_tech_1"
│  │  ├─ technicianName: "Paulo Técnico"
│  │  ├─ department: "obras"
│  │  ├─ serviceOrderId: "osId_1"
│  │  ├─ serviceOrderTitle: "Reparação de Asfalto"
│  │  ├─ items: ["Asfalto (20kg)", "Aditivo", "Compactador"]
│  │  ├─ status: "pending"
│  │  ├─ createdAt: {timestamp}
│  │  ├─ updatedAt: null
│  │  ├─ approvedBy: null
│  │  └─ notes: null
│  │
│  └─ {requestId_2}
│     ├─ id: "requestId_2"
│     ├─ technicianId: "uid_tech_2"
│     ├─ technicianName: "Carlos Técnico"
│     ├─ department: "hidricos"
│     ├─ serviceOrderId: "osId_2"
│     ├─ serviceOrderTitle: "Conserto de Vazamento"
│     ├─ items: ["Tubo PVC 50mm", "Cola PVC", "Abraçadeira"]
│     ├─ status: "approved"
│     ├─ createdAt: {timestamp}
│     ├─ updatedAt: {timestamp}
│     ├─ approvedBy: "uid_coord_1"
│     └─ notes: "Aprovar com urgência"
│
├─ 📁 locations {Collection}
│  ├─ {userId_tech_1}
│  │  └─ 📁 history {Subcollection}
│  │     ├─ {locationId_1}
│  │     │  ├─ id: "locationId_1"
│  │     │  ├─ userId: "uid_tech_1"
│  │     │  ├─ latitude: -23.5505
│  │     │  ├─ longitude: -46.6333
│  │     │  ├─ accuracy: 15.5
│  │     │  ├─ speed: 52.3
│  │     │  ├─ heading: 180.0
│  │     │  ├─ timestamp: {timestamp}
│  │     │  └─ serviceOrderId: "osId_1"
│  │     │
│  │     └─ {locationId_2}
│  │        ├─ id: "locationId_2"
│  │        ├─ userId: "uid_tech_1"
│  │        ├─ latitude: -23.5510
│  │        ├─ longitude: -46.6340
│  │        ├─ accuracy: 12.0
│  │        ├─ speed: 48.5
│  │        ├─ heading: 175.5
│  │        ├─ timestamp: {timestamp}
│  │        └─ serviceOrderId: "osId_1"
│  │
│  └─ {userId_tech_2}
│     └─ 📁 history {Subcollection}
│        └─ {...locations...}
│
└─ 📁 logs {Collection} [RESERVED FOR AUDITING]
   └─ (To be implemented)
```

---

## 8. Role-Based Access Matrix

```
RESOURCE ACCESS BY ROLE

                    Manager    Coordinator    Technician    Unauthenticated
────────────────────────────────────────────────────────────────────────────
LOGIN                  ❌        ❌            ❌            ✅ (Full Access)
DASHBOARD              ✅        ✅            ❌            
SERVICE ORDERS
  └─ View All          ✅        ✅*           ❌            
  └─ Create            ✅        ✅*           ❌            
  └─ Edit              ✅        ✅*           ❌            
  └─ Delete            ✅        ❌            ❌            

MATERIAL REQUESTS
  └─ View All          ✅        ✅*           ❌            
  └─ Create            ✅        ✅*           ❌            
  └─ Approve/Reject    ✅        ✅*           ❌            

FLEET MONITORING
  └─ View Technicians  ✅        ✅*           ❌            
  └─ Real-time Tracking✅        ✅*           ❌            

USER MANAGEMENT
  └─ View Users        ✅        ❌            ❌            
  └─ Create User       ✅        ❌            ❌            
  └─ Edit User         ✅        ❌            ❌            
  └─ Delete User       ✅        ❌            ❌            

GPS MONITORING
  └─ View Location     ✅        ✅*           ❌            
  └─ Send Location     ✅        ✅*           ✅ (own only)  

────────────────────────────────────────────────────────────────────────────
Legend:
✅ = Full Access
✅* = Access to own department only
❌ = No Access
```

---

## 9. Technologies Used - Versioning

```
┌──────────────────────────────────────────────────────────┐
│ CORE FRAMEWORK                                           │
├──────────────────────────────────────────────────────────┤
│ Flutter                           3.11.4+                │
│ Dart                              3.11.4+                │
│ Material Design                   3 (MDC3)               │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ FIREBASE SERVICES                                        │
├──────────────────────────────────────────────────────────┤
│ firebase_core                     4.6.0                  │
│ firebase_auth                     6.3.0                  │
│ cloud_firestore                   6.2.0                  │
│ firebase_storage                  13.2.0                 │
│ firebase_messaging                (future)               │
│ firebase_crashlytics              (future)               │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ STATE MANAGEMENT & ARCHITECTURE                         │
├──────────────────────────────────────────────────────────┤
│ flutter_bloc                      8.1.2  (ACTIVE)        │
│ flutter_riverpod                  2.5.1  (INACTIVE)      │
│ get_it                            7.4.0  (DI Container)  │
│ equatable                         2.0.6  (Value Equality)│
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ NAVIGATION & ROUTING                                   │
├──────────────────────────────────────────────────────────┤
│ go_router                         14.0.0                 │
│ (Declarative routing + deep linking)                    │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ LOCATION & MAPS                                          │
├──────────────────────────────────────────────────────────┤
│ google_maps_flutter               2.6.0                  │
│ geolocator                        12.0.0                 │
│ geocoding                         3.0.0                  │
│ flutter_background_service        5.0.5                  │
│   (Background GPS tracking)                              │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ UTILITIES & LOCALIZATION                                 │
├──────────────────────────────────────────────────────────┤
│ intl                              0.20.0 (Dates/Numbers) │
│ image_picker                      1.0.0  (Photo upload)  │
│ connectivity_plus                 (future - network check)
│ logger                            (future - logging)     │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ DEVELOPMENT & TESTING                                    │
├──────────────────────────────────────────────────────────┤
│ flutter_test                      SDK                    │
│ flutter_lints                     6.0.0                  │
│ mockito                           (future - unit tests)  │
│ build_runner                      (code generation)      │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ CI/CD & DEPLOYMENT                                       │
├──────────────────────────────────────────────────────────┤
│ GitHub Actions                    (future setup)         │
│ Firebase Hosting                  (web deployment)       │
│ Google Play Store                 (Android)              │
│ Apple App Store                   (iOS)                  │
└──────────────────────────────────────────────────────────┘
```

---

## 10. Quick Reference - Commands Cheat Sheet

```bash
# ========== DEVELOPMENT ==========
flutter pub get                      # Install dependencies
flutter pub upgrade                  # Upgrade to latest versions
flutter analyze                      # Run linter
flutter pub run build_runner build   # Generate code (if needed)
flutter clean && flutter pub get     # Deep clean

# ========== RUNNING ==========
flutter run                          # Debug on default device
flutter run -d chrome                # Run on web
flutter run -d ios                   # Run on iOS simulator
flutter run -d <device-id>           # Run on specific device
flutter devices                      # List connected devices

# ========== TESTING ==========
flutter test                         # Run all unit tests
flutter test test/auth_bloc_test.dart # Specific test
flutter test --coverage              # Coverage report

# ========== BUILDING ==========
flutter build apk                    # Android APK (debug)
flutter build apk --release          # Android APK (release)
flutter build appbundle              # Android App Bundle (Play Store)
flutter build ios                    # iOS (requires Xcode)
flutter build web --release          # Web build

# ========== FIREBASE ==========
firebase login                       # Authenticate Firebase CLI
flutterfire configure                # Configure Firebase for Flutter
firebase deploy                      # Deploy Cloud Functions
firebase hosting:deploy              # Deploy web version

# ========== DIAGNOSTICS ==========
flutter doctor                       # Check setup health
flutter doctor -v                    # Verbose diagnostics
flutter pub outdated                 # Check for updates
flutter pub cache repair             # Fix pub cache issues
```

---

**End of Quick Reference**

Para mais informações, consulte:
- Documentação Técnica Completa: [DOCUMENTACAO_TECNICA_COMPLETA.md](DOCUMENTACAO_TECNICA_COMPLETA.md)
- Firebase Documentation: https://firebase.google.com/docs
- Flutter Documentation: https://flutter.dev/docs

