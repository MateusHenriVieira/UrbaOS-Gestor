# Diagnóstico: Status do Live Tracking

**Data**: 20 de abril de 2026  
**Status**: ⚠️ CRÍTICO - Sem dados de localização

---

## O Problema

A tela de Rastreamento em Tempo Real (`LiveTechTrackingPage`) está mostrando "SEM SINAL" mesmo com técnicos online.

### Raiz do Problema Identificada

O admin (`urbaos_admin`) está lendo de um caminho **que o app do técnico nunca preencheu**:

```
live_tracking/{osId ou department}/{technicianUid}
```

**Status no Firebase RTDB**: ❌ **VAZIO** (0 técnicos)

---

## Arquitetura Atual vs Esperada

### ❌ O que o app do técnico DEVERIA estar fazendo (segundo prompt desatualizado)

```
locations/{userId}/current                              ← RTDB (posição atual)
locations/{userId}/history/{locationId}                 ← RTDB (histórico rápido)
locations/{locationId}                                  ← Firestore (compatibilidade)
service_orders/{osId}/locations/{locationId}            ← Firestore (subcoleção)
```

Referência: `/docs/PROMPT_GPS_APP_TECNICO.md` (linhas 99-157)

### ✅ O que o admin (`urbaos_admin`) espera ler

```
live_tracking/{osId}/{technicianUid}                    ← RTDB (OS ativa)
live_tracking/{department}/{technicianUid}              ← RTDB (standby/sem OS)
```

Referência: 
- `/lib/features/fleet_monitoring/data/repositories/firebase_live_tracking_repository.dart` (linhas 52-70)
- `/docs/RULES_LIVE_TRACKING.md` (linhas 14-15)

---

## O Mismatch: Por que não funciona?

| Componente | Escreve em | Lê de |
|-----------|-----------|-------|
| **App do técnico** (desconhecido) | ❓ `locations/...` (?) | — |
| **Admin (`urbaos_admin`)** | — | `live_tracking/...` ✗ |

**Resultado**: Admin lê de um lugar vazio.

---

## Solução Necessária

Escolha uma das opções abaixo:

### Opção A: Atualizar app do técnico para usar `live_tracking/` ⚡ (RECOMENDADO)

Garante sincronização em tempo real e evita duplicação de dados.

**Ação**:
1. Localizar o código de GPS no app do técnico (buscar por `Geolocator`, `LocationService`, `saveLocation`)
2. Alterar os caminhos RTDB para:
   ```dart
   // Quando técnico está em OS ativa:
   FirebaseDatabase.instance.ref('live_tracking/$osId/$uid').set({...})
   
   // Quando técnico está em standby (sem OS):
   FirebaseDatabase.instance.ref('live_tracking/$department/$uid').set({...})
   ```
3. Validar que o payload inclui os campos esperados:
   ```dart
   {
     'lat': double,
     'lng': double,
     'timestamp': int,  // milliseconds
     'speed': double,
     'heading': double,
     'osId': string,
     'isMocked': bool,
     'technicianId': string,
     'technicianName': string,
   }
   ```

### Opção B: Atualizar admin para ler de `locations/` (complexo)

Reverteria o admin para usar caminhos legados. **NÃO recomendado** a menos que haja motivo.

---

## Como Verificar Após Correção

Depois que o app do técnico for atualizado:

1. **Técnico faz login e inicia OS**
2. **Log esperado no admin** (console do Flutter):
   ```
   ⚠️ [LiveTracking] Técnico encontrado
      Buscado: 1xp8V19R6yZEI9qqzITt46ElSMT2
      Disponíveis (1): [1xp8V19R6yZEI9qqzITt46ElSMT2]
   ```
   Agora mostrará "AO VIVO" no badge em vez de "SEM SINAL"

3. **Firebase Console** → Realtime Database:
   - Navegue para `live_tracking/`
   - Deve haver estrutura: `live_tracking/{osId ou dept}/{uid}/` com payload atualizado

---

## Referência Técnica

### Campos obrigatórios no payload

```dart
LiveLocation.fromRealtime({
  required String uid,              // Firebase Auth UID (chave do RTDB)
  required Map<String, dynamic> json // payload
})
```

**Mapeamento do JSON**:
- `json['lat']` → `latitude`
- `json['lng']` → `longitude`
- `json['timestamp']` → convertido de ms para DateTime
- `json['speed']` → velocidade em m/s
- `json['heading']` → direção em graus (0-360)
- `json['osId']` → "standby" se sem OS ativa
- `json['isMocked']` → detecção de GPS falsificado
- `json['technicianId']` → uid do técnico (fallback: `uid`)
- `json['technicianName']` → nome do técnico

Fonte: `/lib/features/fleet_monitoring/domain/entities/live_location.dart` (linhas 44-65)

---

## Status das Correções

- [x] Admin: adicionado logging detalhado quando técnico não encontrado
- [ ] Admin: eventualmente migrar para suportar caminhos legados como fallback
- [ ] **App do técnico: URGENTE - atualizar para gravar em `live_tracking/`**

---

## Próximos Passos

1. ✅ Este diagnóstico foi gerado
2. ⏳ Aguardando confirmação de qual opção será implementada
3. 📝 Será criado prompt atualizado para app do técnico se a Opção A for escolhida
