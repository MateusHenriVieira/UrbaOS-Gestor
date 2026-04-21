# Prompt — Corrigir gravação de GPS no app do técnico

Este arquivo contém um prompt **autocontido** para colar em uma nova sessão do Claude Code (ou qualquer assistente) rodando dentro do repositório do **app do técnico** (projeto separado do `urbaos_admin`).

O prompt já traz:
- o schema real do Firestore em produção,
- os caminhos que o app admin (`urbaos_admin`) **espera ler**,
- decisões de arquitetura já tomadas (subcoleção na OS + Realtime Database),
- causas prováveis do bug de "não está salvando",
- critérios de aceitação para validar a correção.

---

## Como usar

1. Abra a sessão de chat no diretório do app do técnico.
2. Copie **tudo abaixo da linha `---` a seguir** e cole como sua primeira mensagem.
3. Deixe o agente investigar antes de editar qualquer arquivo — o prompt pede isso explicitamente.

---

Você é um engenheiro Flutter/Firebase sênior. Preciso que você investigue e corrija o bug de gravação de GPS no **app do técnico** (este repositório). O app admin que consome esses dados já foi auditado e está correto — os caminhos que ele espera estão documentados abaixo. **Não inicie edições antes de concluir a investigação da seção "1. O que investigar primeiro"**.

## 0. Contexto do produto

Existem dois apps Flutter em repositórios separados:

- **`urbaos_admin`** (gestão): usado por gestores e coordenadores. Já foi refatorado e está com `flutter analyze` limpo. Ele **lê** as localizações dos técnicos para exibir no mapa ao vivo e no histórico por OS.
- **Este app (app do técnico)**: usado pelos técnicos em campo. Deve **gravar** as localizações enquanto a OS está em andamento. Atualmente está bugado — não está persistindo nada.

Ambos apps usam o mesmo projeto Firebase (região **`southamerica-east1`**) com Authentication, Firestore e Realtime Database.

## 1. O que investigar primeiro (antes de editar)

Faça, nesta ordem, e me reporte o que encontrar em cada passo:

1. **Encontre o código que tenta salvar a localização.** Procure por `Geolocator.getPositionStream`, `Geolocator.getCurrentPosition`, `FirebaseDatabase`, `FirebaseFirestore`, `saveLocation`, `LocationService`, `background_service`.
2. **Liste todos os caminhos (path/ref) onde o app está tentando gravar** (ex.: `FirebaseFirestore.instance.collection('...').doc(...)`, `FirebaseDatabase.instance.ref('...')`). Compare com os caminhos esperados pelo admin na seção 3 abaixo.
3. **Verifique se há `await` em todas as chamadas de escrita.** Um bug comum é chamar `repository.saveLocation(...)` dentro de um `StreamSubscription.listen((pos) { ... })` sem `await` — o `Future` é criado mas nunca aguardado, então se ocorrer um erro você não fica sabendo (esse mesmo bug existia no app admin e foi corrigido).
4. **Verifique se há `try/catch` vazio ou sem `debugPrint`** em volta das escritas. Outro motivo comum pra "não salvar" é a exceção ser engolida.
5. **Verifique as permissões de plataforma:**
   - **AndroidManifest.xml** deve ter `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (se rastreia em background), `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_LOCATION` (Android 14+).
   - **iOS Info.plist** deve ter `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` e, se for rastreio em background, `UIBackgroundModes` com `location`.
6. **Verifique se o usuário está autenticado** no momento da gravação. `FirebaseAuth.instance.currentUser` não pode ser `null`. Se o app grava em background, confirme que o token de auth foi renovado antes.
7. **Rode o app em modo debug e colete os logs** (`flutter run --verbose` em um dispositivo real, não emulador). Emoji não importa — o que importa é ver se os `listen((position) => ...)` realmente disparam. Cole aqui os primeiros ~30 segundos de logs.

**Só depois de entregar o resultado dos 7 itens acima, prossiga para a correção.** Não presuma qual é o bug.

## 2. Schema real do Firestore (confirmado em produção)

Não crie novos campos com nomes diferentes. Se precisar alterar o schema, me avise antes.

### Coleção `users`

```
department: string      (ex.: "obras", "hidricos")
email: string
nome: string            (← em português; NÃO é "name")
role: string            (ex.: "technician", "coordinator", "manager")
uid: string             (igual ao doc.id)
```

### Coleção `service_orders`

```
createdAt: timestamp
createdBy: string                       (uid do criador)
createdByName: string
department: string
description: string
locationUrl: string | null              (URL de mapa estático, opcional)
photoUrl: string                        (URL da imagem no Storage)
status: string                          (um de: "aberta", "em_andamento", "aguardando_conferencia", "concluida")
technicianId: string                    (uid do técnico atribuído)
technicianName: string
title: string
updatedAt: timestamp
```

### Coleção `material_requests`

```
approvedBy: string | null
createdAt: timestamp
department: string
items: array<string>
notes: string
serviceOrderId: string
serviceOrderTitle: string
status: string                          ("pending", "approved", "rejected")
technicianId: string
updatedAt: timestamp
```

## 3. Onde a localização DEVE ser gravada

Decisão de arquitetura do dono do produto. O app admin já está preparado para ler destes locais.

### 3.1 Firestore — subcoleção dentro da OS (fonte de verdade, histórico)

```
service_orders/{osId}/locations/{locationId}
```

**Shape do documento:**

```dart
{
  'id': String,              // mesmo que o doc id
  'userId': String,          // uid do técnico (= technicianId da OS)
  'serviceOrderId': String,  // = osId
  'latitude': double,
  'longitude': double,
  'accuracy': double?,       // metros
  'speed': double?,          // m/s
  'heading': double?,        // graus (0-360)
  'timestamp': Timestamp,    // server timestamp ou Timestamp.fromDate(DateTime.now())
}
```

Convenção de `locationId`: `"${userId}_${DateTime.now().millisecondsSinceEpoch}"` (mesmo padrão do admin).

### 3.2 Realtime Database — posição ao vivo e histórico rápido

O admin usa o Realtime DB para o rastreamento "ao vivo" (leitura instantânea) e faz fallback no Firestore para histórico consolidado. **Escreva nos DOIS lugares abaixo**, em paralelo, a cada nova leitura de GPS:

```
locations/{userId}/current              ← sobrescreve a cada nova posição
locations/{userId}/history/{locationId} ← append-only
```

**Shape (mesmo do Firestore, porém `timestamp` vira `int` em millisecondsSinceEpoch):**

```dart
{
  'id': String,
  'userId': String,
  'serviceOrderId': String?,
  'latitude': double,
  'longitude': double,
  'accuracy': double?,
  'speed': double?,
  'heading': double?,
  'timestamp': int,          // ms desde a epoch (NÃO Timestamp)
}
```

### 3.3 Por que gravar em 3 lugares?

| Lugar | Uso pelo admin |
|-------|----------------|
| Firestore `service_orders/{osId}/locations/` | Histórico por OS (mapa detalhado quando o gestor abre a OS) |
| Realtime DB `locations/{userId}/current` | "Onde o técnico está AGORA" — leitura instantânea no mapa ao vivo |
| Realtime DB `locations/{userId}/history/{locationId}` | Trajeto recente do dia (rota ao vivo desenhada por cima do mapa) |

> **Importante:** o repositório atual do admin (`firebase_location_repository.dart`) ainda lê do caminho **legado** `collection('locations')` (coleção raiz) no Firestore para o histórico — não da subcoleção da OS. Isso está no backlog de migração do admin. Enquanto essa migração não acontece, escreva **também** em `locations/{locationId}` na raiz (com o campo `serviceOrderId` preenchido) para o admin continuar funcionando. Se isso ficar pesado, me avise e decidimos se atualizamos o admin primeiro.

**Resumo dos writes por ponto de GPS:**

1. `service_orders/{osId}/locations/{locationId}` (Firestore)
2. `locations/{locationId}` (Firestore — compatibilidade com admin atual)
3. `locations/{userId}/current` (Realtime DB)
4. `locations/{userId}/history/{locationId}` (Realtime DB)

Envolva os 4 em `Future.wait([...])` para não bloquear o stream de GPS.

## 4. Causas prováveis do bug "não está salvando"

Baseado em experiência prévia (esses mesmos bugs foram encontrados no app admin e corrigidos). Verifique cada um:

1. **`saveLocation(...)` sem `await`** dentro do `.listen((pos) { ... })` do `Geolocator.getPositionStream`. Sem `await`, a exceção (permissão negada, offline, rule do Firestore bloqueando, etc.) é engolida silenciosamente. Solução: tornar o callback `async` e aguardar o `Future`.
2. **`try/catch` silencioso** — `catch (_) {}` sem log. Sempre logar com `debugPrint('...: $e')` em dev.
3. **Permissões Android 14+** — se o target SDK é 34+, é obrigatório `FOREGROUND_SERVICE_LOCATION`. Sem isso, o sistema mata o serviço em background e os writes param.
4. **`flutter_background_service` sem `setAsForegroundService()`** — em Android, o serviço precisa virar foreground com notificação persistente; do contrário o SO suspende após alguns minutos.
5. **Stream de posição nunca assinado** — algum refactor pode ter deixado `Geolocator.getPositionStream(...)` criado mas sem `.listen(...)`. Um stream em Dart **não emite nada** sem um subscriber.
6. **`currentUser` nulo em background** — se o técnico não relogou desde uma atualização do app, `FirebaseAuth.instance.currentUser` pode vir nulo na primeira execução do background handler. Chame `await FirebaseAuth.instance.authStateChanges().first` antes de tentar escrever.
7. **Firestore Security Rules bloqueando** — se as rules exigem `request.auth.uid == resource.data.userId`, confirme que o write está usando o uid certo. Teste liberando temporariamente em `rules_playground` no console.
8. **`DartPluginRegistrant.ensureInitialized()` ausente** no entrypoint do background service — sem isso, plugins (inclusive `cloud_firestore` e `firebase_database`) falham silenciosamente dentro do isolate do background.
9. **`Firebase.initializeApp(...)` não chamado no isolate do background** — background isolate é independente do main isolate; precisa re-inicializar o Firebase lá também.

## 5. Implementação de referência (depois do diagnóstico)

Esta é a estrutura esperada do `LocationService` do app do técnico. Ajuste ao código existente — não reescreva do zero se já houver algo funcional.

```dart
// Chamado quando o técnico aceita/inicia uma OS (status = "em_andamento")
Future<void> startTrackingFor({
  required String userId,
  required String serviceOrderId,
}) async {
  // 1. Valida permissão
  final granted = await _ensureLocationPermission();
  if (!granted) throw Exception('Permissão de localização negada');

  // 2. Inicia background service (Android precisa de notificação persistente)
  await FlutterBackgroundService().startService();

  // 3. Assina o stream de GPS
  _subscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // metros — evita flood
    ),
  ).listen((position) async {
    try {
      await _persist(
        userId: userId,
        serviceOrderId: serviceOrderId,
        position: position,
      );
    } catch (e, s) {
      debugPrint('Erro ao persistir GPS: $e\n$s');
    }
  });
}

Future<void> _persist({
  required String userId,
  required String serviceOrderId,
  required Position position,
}) async {
  final id = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
  final now = DateTime.now();

  final firestorePayload = {
    'id': id,
    'userId': userId,
    'serviceOrderId': serviceOrderId,
    'latitude': position.latitude,
    'longitude': position.longitude,
    'accuracy': position.accuracy,
    'speed': position.speed,
    'heading': position.heading,
    'timestamp': Timestamp.fromDate(now),
  };

  final realtimePayload = {
    ...firestorePayload,
    'timestamp': now.millisecondsSinceEpoch, // Realtime DB não tem Timestamp
  };

  // Os 4 writes em paralelo — se um falhar, não trava os outros
  await Future.wait([
    _firestore
        .collection('service_orders')
        .doc(serviceOrderId)
        .collection('locations')
        .doc(id)
        .set(firestorePayload),
    _firestore.collection('locations').doc(id).set(firestorePayload), // compat com admin atual
    _realtimeDb.ref('locations/$userId/current').set(realtimePayload),
    _realtimeDb.ref('locations/$userId/history/$id').set(realtimePayload),
  ]);
}

Future<void> stopTracking() async {
  await _subscription?.cancel();
  _subscription = null;
  FlutterBackgroundService().invoke('stopService');
}
```

Pontos críticos:
- `.listen(...)` com callback `async` e `await` na chamada de `_persist`.
- `try/catch` com `debugPrint` — nunca vazio.
- `distanceFilter: 10` para não espammar writes (ajuste conforme perfil de bateria desejado).
- Permissão `LocationPermission.always` é necessária para funcionar com o app em background no iOS. Se só tiver `whileInUse`, o iOS pausa após sair do foreground.

## 6. Como testar ponta a ponta

1. **Logue como um técnico** real no app do técnico (use um UID que existe em `users` com `role == "technician"`).
2. **Abra uma OS em andamento** (status `em_andamento`) atribuída a esse técnico.
3. **Inicie o tracking**. Confirme nos logs (`flutter run --verbose`) que cada novo ponto imprime sem erro.
4. **Abra o Firebase Console** e confira em tempo real:
   - `service_orders/{osId}/locations/` deve ter novos docs sendo criados.
   - `locations/{userId}/current` no Realtime DB deve estar atualizando.
   - `locations/{userId}/history/{locationId}` deve crescer.
5. **Abra o app admin** em outro dispositivo/conta (gestor ou coordenador da mesma secretaria) e confira que:
   - A página "Live Tech Tracking" do técnico mostra o ponto ao vivo se movendo.
   - A página de detalhes da OS mostra a rota desenhada.
6. **Teste em background**: minimize o app do técnico por 5 minutos andando com o celular. Os pontos devem continuar chegando (a notificação persistente do foreground service deve estar visível).
7. **Teste offline**: coloque o celular em modo avião por 2 minutos. Ao voltar online, o Firestore deve fazer flush dos writes em fila (SDK faz isso automaticamente). Confirme que nenhum ponto foi perdido.

## 7. Critérios de aceitação

A correção só está pronta quando **TODOS** os itens abaixo forem verdadeiros. Cite cada um no seu relatório final, indicando como testou.

- [ ] `flutter analyze` retorna 0 erros.
- [ ] Abrir uma OS em andamento no app do técnico inicia o tracking automaticamente (ou após um toque em "Iniciar", conforme UX definida).
- [ ] A cada ~10 metros de deslocamento, 4 writes são confirmados nos 4 caminhos listados na seção 3.
- [ ] Logs mostram `debugPrint` em caso de falha (não mais silenciosos).
- [ ] App funciona em background por pelo menos 10 minutos sem ser morto pelo SO (Android).
- [ ] Ao parar a OS (status muda para `aguardando_conferencia` ou `concluida`), o `StreamSubscription` é cancelado e o background service encerrado.
- [ ] `AndroidManifest.xml` e `Info.plist` têm todas as permissões necessárias.
- [ ] O app admin exibe o técnico se movendo no mapa ao vivo.

## 8. O que NÃO fazer

- Não mudar nomes de campos do schema sem alinhamento (especialmente `nome` vs `name`).
- Não criar coleções novas na raiz do Firestore. A organização correta é **subcoleção dentro da OS**.
- Não remover a escrita em `locations/{locationId}` (raiz) até confirmar que o admin migrou a leitura para a subcoleção.
- Não usar `Geolocator.getLastKnownPosition()` como fonte primária — só como fallback em primeira abertura.
- Não gravar a cada segundo — `distanceFilter: 10` metros é o mínimo aceitável.
- Não fazer `print(...)` — use `debugPrint(...)`.

## 9. Relatório final esperado

Ao terminar, me entregue:

1. **Diagnóstico**: qual(is) dos 9 problemas listados na seção 4 eram reais.
2. **Arquivos alterados** com caminho e 1 frase de resumo cada.
3. **Evidência de funcionamento**: screenshots do Firebase Console com os writes + logs do `flutter run` por 60 segundos.
4. **Itens dos critérios de aceitação** marcados com ✅ ou ❌ + justificativa de qualquer ❌.
5. **Riscos/pontos em aberto** — inclusive se o admin precisa migrar a leitura para a subcoleção da OS antes de você remover o write em `locations/` raiz.

Comece agora pela seção 1 (investigação). Não edite código sem antes me entregar o diagnóstico.
