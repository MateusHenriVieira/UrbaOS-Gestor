# Contrato Live Tracking — v2 (2026-04-20)

**Status**: ✅ Implementado no app do técnico | ✅ Admin atualizado

## Estrutura Consolidada

### Path: `live_tracking/{technicianUid}`

Um nó por técnico, com todos os dados em um único documento.

### Payload

```json
{
  "lat": -23.5505,
  "lng": -46.6333,
  "timestamp": 1713625200000,
  "speed": 4.2,
  "heading": 187.5,
  "osId": "abc123",
  "department": "limpeza_urbana",
  "status": "active",
  "isMocked": false,
  "technicianId": "1xp8V19R6yZEI9qqzITt46ElSMT2",
  "technicianName": "Fulano Silva"
}
```

### Campos

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `lat` | double | Latitude |
| `lng` | double | Longitude |
| `timestamp` | int | Milliseconds desde epoch (server timestamp) |
| `speed` | double | Velocidade em m/s |
| `heading` | double | Direção em graus (0-360) |
| `osId` | string \| null | ID da OS em andamento, ou `null` se em standby |
| `department` | string | Departamento do técnico (ex.: "limpeza_urbana") |
| `status` | string | `"active"` se em OS, `"standby"` se aguardando |
| `isMocked` | boolean | `true` se GPS foi falsificado (detecção de spoofing) |
| `technicianId` | string | Firebase Auth UID do técnico |
| `technicianName` | string | Nome do técnico |

---

## Como o Admin Consulta

### 1. Todos os técnicos online

```dart
_rtdb.ref('live_tracking').onValue.listen((event) {
  // Retorna Map<uid, dados>
  // Filtro freshness: timestamp > now - 60_000
});
```

### 2. Por departamento (query ordenada)

```dart
_rtdb
  .ref('live_tracking')
  .orderByChild('department')
  .equalTo('limpeza_urbana')
  .onValue
  .listen((event) { ... });
```

### 3. Por OS específica

```dart
_rtdb
  .ref('live_tracking')
  .orderByChild('osId')
  .equalTo('abc123')
  .onValue
  .listen((event) { ... });
```

### 4. Técnico individual

```dart
_rtdb.ref('live_tracking/$technicianId').onValue.listen((event) {
  // Retorna dados diretos do técnico, ou null se offline
});
```

---

## Regras de Segurança (database.rules.json)

```json
{
  "rules": {
    "live_tracking": {
      ".read": "auth != null",
      ".indexOn": ["department", "osId", "status"],
      "$uid": {
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

**Interpretação:**
- `.read`: qualquer usuário autenticado lê tudo
- `.indexOn`: cria índices para queries por department, osId, status (performance)
- `$uid/.write`: apenas o próprio técnico escreve seus dados

### Como aplicar

```bash
# Terminal com gcloud CLI
firebase deploy --only database

# Ou manualmente:
# 1. Firebase Console
# 2. Realtime Database → Rules
# 3. Copiar/colar o conteúdo de database.rules.json
# 4. Publish
```

---

## Implementação no Admin (`urbaos_admin`)

### Arquivos Atualizados

| Arquivo | Mudança |
|---------|---------|
| [firebase_live_tracking_repository.dart](lib/features/fleet_monitoring/data/repositories/firebase_live_tracking_repository.dart) | Lê novo path `live_tracking/{uid}` em vez de estrutura 2 níveis |
| [live_location.dart](lib/features/fleet_monitoring/domain/entities/live_location.dart) | Adicionados campos `department` e `status`, `osId` agora é nullable |
| [database.rules.json](database.rules.json) | ✨ Novo arquivo com regras RTDB |

### Mudanças Técnicas

1. **`watchTechnicianLive(uid)`** agora lê direto de `live_tracking/{uid}` (mais eficiente)
2. **`watchFleetLive(user)`** filtra por `department` do payload (não precisa cache externo)
3. **`watchOsLive(osId)`** filtra client-side por `osId` (poucos técnicos por OS)
4. **`_parseLiveTrackingTree()`** simplificado para estrutura plana
5. **Removido** cache de departamentos (`_deptCache`, `_loadDeptCache()`)

---

## Freshness & Heartbeat

- **Heartbeat app do técnico**: a cada ~15 segundos (em foreground) ou ~60s (background)
- **Detecção offline admin**: timestamp > now - 60_000 ms
- **Visual**: "AO VIVO" (fresco), "OFFLINE" (stale > 60s), "SEM SINAL" (null)

---

## Histórico de Versões

### v1 (antes de 2026-04-20)
```
live_tracking/{osId}/{uid}    — OS ativa
live_tracking/{department}/{uid}  — Standby
```
❌ **Problema**: estrutura confusa, admin não sabia qual nó olhar

### v2 (2026-04-20 em diante) ✅
```
live_tracking/{uid}  — sempre, com `osId` nulo se standby
```
✅ **Benefício**: caminho canônico, queries mais simples, `onDisconnect()` automático

---

## Validação Ponta-a-Ponta

Após deploy do app do técnico e regras RTDB:

```bash
# 1. Técnico faz login no app
# 2. Confirmar no Firebase Console:
firebase database:get live_tracking

# Output esperado:
{
  "1xp8V19R6yZEI9qqzITt46ElSMT2": {
    "lat": -23.5505,
    "lng": -46.6333,
    "timestamp": 1713625200000,
    ...
  }
}

# 3. Admin — abrir tela de rastreamento
# Console deve mostrar: ✅ Técnico encontrado (não "sem sinal")
```

---

## FAQ

**P: E se dois técnicos tiverem o mesmo Firebase UID?**  
R: Não podem. UID é único por autenticação Firebase. Se houver conflito é bug na criação do usuário.

**P: Como ler histórico persistente?**  
R: RTDB limpa automaticamente (transiente). Para histórico durável, implementar escrita em Firestore `service_orders/{osId}/locations/` (backlog).

**P: Por que `osId` é nullable em vez de usar string vazia?**  
R: Tipo mais explícito, Dart null-safety, queries `orderByChild('osId').equalTo(null)` funcionam melhor.

**P: Pode atualizar queries para usar índices compostos?**  
R: Não precisa neste design. `orderByChild` simples + índice `.indexOn` já é eficiente pois RTDB não tem join custoso.

**P: E se a rede cair?**  
R: App do técnico: stream pausa; RTDB `onDisconnect().remove()` dispara após ~60s. Admin: para de ver o técnico (offline).

---

## Links de Referência

- 📖 [Documentação RTDB Security Rules](https://firebase.google.com/docs/rules)
- 📖 [Queries em RTDB](https://firebase.google.com/docs/database/admin/start#read_data)
- 📝 [Issue original: Admin mostrando "SEM SINAL"](docs/DIAGNOSTICO_LIVE_TRACKING.md)
- 📝 [Prompt app técnico](docs/PROMPT_GPS_APP_TECNICO_ATUALIZADO.md)
