# Prompt Corrigido — GPS App Técnico (VERSÃO ATUALIZADA)

Este arquivo contém o **prompt corrigido** para o app do técnico, incorporando os caminhos REAIS que o admin espera ler (baseado no código atual do `urbaos_admin`).

**⚠️ IMPORTANTE**: Use este prompt em vez do arquivo `PROMPT_GPS_APP_TECNICO.md` que está desatualizado.

---

## Como usar

1. Abra uma sessão do Claude Code no repositório do app do técnico
2. Cole **tudo abaixo da linha `---`** e deixe o agente investigar
3. Siga as instruções de investigação antes de editar qualquer código

---

Você é um engenheiro Flutter/Firebase sênior. Preciso que você investigue e implemente a gravação de GPS no **app do técnico** para sincronizar com o **app admin** (`urbaos_admin`) em tempo real.

## Contexto

Dois apps Flutter em repositórios separados compartilham o mesmo projeto Firebase (region `southamerica-east1`):

- **`urbaos_admin`** (gestão): lê as localizações dos técnicos em tempo real
- **Este app (app do técnico)**: deve GRAVAR as localizações enquanto está em campo com uma OS em andamento

**Status atual**: O admin não está recebendo dados. Investigação do admin mostrou que o Realtime Database em `live_tracking/` está **completamente vazio** — não há nenhum técnico gravando dados lá.

## 1. Investigação Preliminar

Antes de editar qualquer código, execute os passos abaixo nesta ordem e reporte os achados:

1. **Procure pelo código de localização** no app usando as palavras-chave:
   - `Geolocator` (package de GPS)
   - `LocationService`, `location_service`
   - `saveLocation`, `updateLocation`, `publishLocation`
   - `FirebaseDatabase`, `FirebaseFirestore`
   - `getPositionStream`, `getCurrentPosition`
   - `background_service`, `flutter_background_service`

   Liste todos os arquivos encontrados com números de linha.

2. **Verifique a estrutura de dados sendo gravada** — procure por `.set(`, `.update(`, `.push(` e copie o primeiro exemplo de código que escreve para o Firebase (RTDB ou Firestore).

3. **Identifique os caminhos (paths) onde está tentando gravar**:
   - Exemplo: `FirebaseDatabase.instance.ref('locations/$userId/current').set(...)`
   - Copie EXATAMENTE como aparece no código

4. **Verifique se há `await` em volta das chamadas de escrita**:
   - ❌ Ruim: `.listen((pos) { repo.saveLocation(pos); })` (sem await)
   - ✅ Bom: `.listen((pos) async { await repo.saveLocation(pos); })`

5. **Cole aqui os primeiros ~50 linhas do arquivo principal de GPS** (aquele que contém a lógica de rastreamento).

6. **Rode o app em modo debug** (`flutter run --verbose` em um dispositivo real, não emulador) e colete 30-60 segundos de logs. Cole aqui qualquer mensagem relacionada a GPS, Firebase, ou exceções.

---

## 2. Arquitetura Esperada (Corrigida)

O **app admin está preparado para ler deste caminho específico**:

### 🎯 Realtime Database — Posição em Tempo Real

```
live_tracking/{osId}/{technicianUid}
```

**Ou quando o técnico está sem OS (standby)**:

```
live_tracking/{department}/{technicianUid}
```

Onde:
- `{osId}` = ID da ordem de serviço (do campo `technicianId` em `service_orders`)
- `{department}` = departamento do técnico (ex.: "obras", "hidricos")
- `{technicianUid}` = Firebase Auth UID do técnico

### 📋 Payload Esperado

```json
{
  "lat": 10.123456,
  "lng": -45.654321,
  "timestamp": 1700000000000,
  "speed": 5.2,
  "heading": 180.0,
  "osId": "OS_ID_ou_standby",
  "isMocked": false,
  "technicianId": "uid_do_firebase",
  "technicianName": "João Silva"
}
```

**Campos obrigatórios**: `lat`, `lng`, `timestamp`, `osId`, `technicianId`, `technicianName`

### 🔄 Frequência de Atualização

- Mínimo: a cada 60 segundos
- Ideal: a cada 15-30 segundos (quando em foreground service)
- Em background: a cada 60-120 segundos (depende do SO)

---

## 3. Estrutura Esperada (Dart)

Se o app ainda não tem, esta é a estrutura recomendada:

```dart
// location_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationService {
  final FirebaseDatabase _database;
  
  // Chamado quando técnico inicia uma OS
  Future<void> startTracking({
    required String technicianId,
    required String technicianName,
    required String osId,
    required String department,
  }) async {
    // 1. Solicita permissão
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Permissão de GPS negada');
    }

    // 2. Inicia stream de GPS
    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,  // metro (não atualiza a cada 1cm)
      ),
    );

    // 3. Assina e publica cada posição
    positionStream.listen((Position position) async {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Determina o primeiro nível do path (osId ativo ou department em standby)
        final level1Key = osId == 'standby' ? department : osId;
        
        // Prepara o payload
        final payload = {
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': timestamp,
          'speed': position.speed,
          'heading': position.heading,
          'osId': osId,
          'isMocked': false,  // Implementar detecção se necessário
          'technicianId': technicianId,
          'technicianName': technicianName,
        };

        // Escreve em RTDB — posição ao vivo
        await _database
            .ref('live_tracking/$level1Key/$technicianId')
            .set(payload);
            
        debugPrint('✅ Localização publicada: $technicianName em $level1Key');
      } catch (e) {
        debugPrint('❌ Erro ao publicar localização: $e');
      }
    });
  }

  // Chamado quando técnico termina a OS ou vai para standby
  Future<void> stopTracking() async {
    await _subscription?.cancel();
    debugPrint('⏹️ Rastreamento parado');
  }
}
```

---

## 4. Security Rules — O que o admin espera

O admin precisa que o Realtime Database esteja com estas regras (ou mais permissivas durante testes):

```json
{
  "rules": {
    "live_tracking": {
      "$level1": {
        "$uid": {
          ".write": "auth != null && auth.uid == $uid",
          ".read": "auth != null && (root.child('users').child(auth.uid).child('role').val() == 'manager' || (root.child('users').child(auth.uid).child('role').val() == 'coordinator' && root.child('users').child(auth.uid).child('department').val() == $level1))"
        }
      }
    }
  }
}
```

Isto significa:
- **Escrita**: somente o próprio técnico (auth.uid == $uid)
- **Leitura**: managers leem tudo; coordenadores leem sua secretaria

---

## 5. Critério de Aceitação

Após a implementação, o log do app admin deve mostrar:

```
✅ ANTES (errado):
flutter: ⚠️ [LiveTracking] Técnico não encontrado
flutter:    Buscado: 1xp8V19R6yZEI9qqzITt46ElSMT2
flutter:    Disponíveis (0):

✅ DEPOIS (correto):
flutter: Técnico encontrado
flutter:    Nome: João Silva
flutter:    Status: AO VIVO
flutter:    Velocidade: 5.2 km/h
```

E no Firebase Console → Realtime Database:
```
live_tracking/
  ├── obras/                    (department em standby)
  │   └── 1xp8V19R6yZEI9qqzITt46ElSMT2/ (uid do técnico)
  │       ├── lat: -8.123456
  │       ├── lng: -35.654321
  │       ├── timestamp: 1700000000000
  │       ├── ...
  │
  └── OS_ABC123/               (osId quando em OS ativa)
      └── 1xp8V19R6yZEI9qqzITt46ElSMT2/
          └── (mesmo payload)
```

---

## 6. Checklist de Implementação

- [ ] Identifiquei onde o código de GPS está localizado
- [ ] Encontrei os caminhos RTDB que estão sendo usados
- [ ] Verificar se há `await` em todas as escritas
- [ ] Implementar o `LiveLocationService` (ou adaptar ao código existente)
- [ ] Conectar ao evento "técnico inicia OS" → chamar `startTracking()`
- [ ] Conectar ao evento "técnico termina/pausa OS" → chamar `stopTracking()`
- [ ] Validar permissões no AndroidManifest.xml (Android 14+ exige `FOREGROUND_SERVICE_LOCATION`)
- [ ] Testar em dispositivo real com:
  - [ ] Técnico faz login
  - [ ] Técnico inicia OS
  - [ ] Verificar Firebase Console → apareceu em `live_tracking/`?
  - [ ] Abrir app admin → técnico aparece "AO VIVO" no mapa?

---

## Referência: Código Admin que Consome

Se precisar entender como o admin lê, veja:

- **Arquivo**: `/lib/features/fleet_monitoring/data/repositories/firebase_live_tracking_repository.dart`
- **Método**: `watchTechnicianLive(String technicianId)` (linhas 52-70)
- **O que faz**: lê `live_tracking/` inteira, filtra por `technicianId`, retorna mais recente

---

## ❓ Dúvidas Frequentes

**P: Por que não usar Firestore em vez de RTDB?**  
R: Admin usa RTDB porque é instantâneo (WebSocket nativo). Firestore tem latência maior.

**P: E se o técnico estiver offline?**  
R: RTDB limpa automaticamente. Para histórico durável, impl implementou no Firestore (future work).

**P: Posso gravar menos frequentemente (ex.: a cada 2 min)?**  
R: Sim, mas o mapa ao vivo ficará "travado" entre atualizações. O ideal é 15-30s.

**P: O que é `isMocked`?**  
R: Flag para detectar GPS falsificado (joystick de loca, spoofing). Implementar depois se necessário.
