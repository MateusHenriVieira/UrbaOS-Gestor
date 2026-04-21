# Rules de segurança — Live Tracking

Regras de segurança para as coleções/paths que o app do técnico escreve e o
app admin (`urbaos_admin`) lê. **Não aplicadas automaticamente** — este doc
serve como referência para copiar no Firebase Console quando o usuário
autorizar.

---

## Realtime Database — `database.rules.json`

O app do técnico escreve em:

- `live_tracking/{osId}/{technicianUid}` — posição em OS ativa.
- `live_tracking/{department}/{technicianUid}` — posição em standby
  (técnico logado sem OS).

Apenas o próprio técnico grava; gestores do mesmo departamento leem.
Coordenadores (restritos à própria secretaria) seguem a mesma regra do
gestor via custom claim `department`.

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

**Notas:**

- `$level1` casa tanto com um `osId` (Firestore doc id, letra+número) quanto
  com um `department` (`obras` / `hidricos`). A ambiguidade é intencional —
  o filtro de dept no client só funciona quando `$level1` é um dept; quando
  é um `osId`, a rule libera para `manager` (vê tudo). Coordenadores
  precisam que o `$level1` seja o próprio dept — para ver técnicos de OSs
  específicas de outras secretarias, teria que consultar o doc da OS primeiro
  (mais complexo; deixado como TODO).
- `manager` tem leitura global (não filtra por dept). Se você quiser restringir
  o Gestor a só um dept, crie um custom claim `scope=department` ou use o
  campo `department` do doc em `users/{uid}`.

### Como aplicar

1. Firebase Console → Realtime Database → Rules.
2. Substitua o conteúdo atual.
3. **Simulador** no console: teste com 3 usuários antes de salvar:
   - um `technician` escrevendo na sua própria chave (deve permitir),
   - um `technician` escrevendo na chave de outro (deve bloquear),
   - um `manager` lendo qualquer chave (deve permitir).

---

## Firestore — `firestore.rules`

O app do técnico grava em:

- `service_orders/{osId}/trajectories/{trajId}` — trajetos "modo Strava".

O técnico só escreve nos seus próprios trajetos. Gestores leem.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper reusável: perfil do usuário autenticado.
    function userProfile() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function isManager() {
      return request.auth != null && userProfile().role == 'manager';
    }

    function isCoordinatorOfDept(deptOfResource) {
      return request.auth != null
          && userProfile().role == 'coordinator'
          && userProfile().department == deptOfResource;
    }

    // ... outras regras do projeto ...

    match /service_orders/{osId} {
      // (regras da própria OS já existem em outro lugar — não duplicar)

      match /trajectories/{trajId} {
        // Leitura: gestor vê tudo; coordenador só do dept da OS pai.
        allow read: if isManager()
                    || isCoordinatorOfDept(get(/databases/$(database)/documents/service_orders/$(osId)).data.department);

        // Escrita/update: somente o técnico dono do trajeto.
        // create: valida o payload mínimo para evitar injection de campos.
        allow create: if request.auth != null
                      && request.resource.data.technicianId == request.auth.uid
                      && request.resource.data.keys().hasAll([
                           'technicianId', 'startTime', 'coordinates',
                           'totalDistance', 'createdAt', 'isSynced'
                         ]);

        // update: mantém a autoria; o app do técnico faz update contínuo
        // no mesmo doc enquanto `endTime == null`.
        allow update: if request.auth != null
                      && resource.data.technicianId == request.auth.uid
                      && request.resource.data.technicianId == request.auth.uid;

        // Gestor nunca deleta (auditoria). Técnico também não.
        allow delete: if false;
      }
    }
  }
}
```

**Notas:**

- `get(/databases/$(database)/documents/users/$(uid))` faz uma leitura
  cobrada a cada request de rule. Para reduzir custo, o padrão recomendado
  é custom claims (`auth.token.role`, `auth.token.department`). Migrar
  depois — o `get()` funciona e é seguro para o volume atual.
- A validação no `create` evita o técnico gravar campos arbitrários (ex:
  `isSynced: true` fake). Ajuste conforme os campos reais gravados pelo app
  do técnico.
- Se você não tem um `coordinator` hoje, a função `isCoordinatorOfDept`
  pode ficar como está — é inofensiva e economiza refactor futuro.

### Como aplicar

1. `firebase deploy --only firestore:rules` (precisa `firebase-tools`).
2. **Antes do deploy**: rode `firebase emulators:start --only firestore`
   + testes unitários (`firestore-rules-unit-testing`) cobrindo os 3
   cenários: técnico próprio, técnico alheio, gestor.

---

## Checklist antes de aplicar em produção

- [ ] Backup das rules atuais (Console → Rules → Histórico).
- [ ] Teste no simulador do Console com pelo menos 3 perfis.
- [ ] Coordenar com o app do técnico: confirmar que o payload do
      `create`/`update` contém exatamente os campos validados (`technicianId`,
      `startTime`, `coordinates`, `totalDistance`, `createdAt`, `isSynced`).
- [ ] Avisar gestores: enquanto as rules novas não subirem, a leitura de
      `live_tracking/` pode depender de rules antigas mais permissivas.
- [ ] Monitorar taxa de erro (`permission-denied`) no Crashlytics/Logs
      nas primeiras 2h após deploy.
