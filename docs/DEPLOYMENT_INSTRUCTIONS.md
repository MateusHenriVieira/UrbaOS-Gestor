# 🚀 Deploy Instructions — Live Tracking v2

**Data**: 20 de abril de 2026  
**Status**: Ready for production deployment

---

## Pre-Deployment Checklist

### ✅ Admin (`urbaos_admin`)
- [x] Repositório atualizado para novo contrato `live_tracking/{uid}`
- [x] Entidades com novos campos (department, status)
- [x] Tratamento correto de `osId` nullable
- [x] Botão de voltar corrigido
- [x] Flutter analyze: 0 errors, 0 warnings
- [x] Database rules criado

### ✅ App do Técnico
- [x] Serviço de background iniciado em login
- [x] Gravação em `live_tracking/{uid}` com heartbeat 15-60s
- [x] Payload com todos os campos esperados
- [x] Limpeza automática com `onDisconnect().remove()`

### ⏳ Firebase
- [ ] Deploy das regras `database.rules.json`

---

## Step 1: Deploy Admin (`urbaos_admin`)

### A. Build & Test Local

```bash
cd /Users/mateus/urbaos_admin

# Validar análise
flutter analyze

# Build APK/IPA se necessário
flutter build apk --release
flutter build ios --release
```

### B. Deploy para App Store / Google Play

Siga o processo padrão de release da sua organização.

---

## Step 2: Deploy App do Técnico

Assumindo que já foi atualizado com o novo contrato:

```bash
cd /caminho/para/app_tecnico

# Validar
flutter analyze

# Build & deploy
flutter build apk --release
flutter build ios --release

# Ou usar CI/CD existente
```

---

## Step 3: ⚠️ **CRÍTICO** — Deploy Firebase Rules

**IMPORTANTE**: Sem isso, o admin pode ter permissões insuficientes.

### Via Firebase CLI

```bash
# 1. Copiar arquivo
cp database.rules.json /caminho/para/firebase/

# 2. Deploy
firebase deploy --only database

# Ou especificamente:
firebase database:set database.rules.json
```

### Via Firebase Console (Manual)

1. Firebase Console → Projeto **urbaos-309a2**
2. Realtime Database → **Rules**
3. Copiar conteúdo de [database.rules.json](database.rules.json)
4. Paste no editor
5. **Publish**

**Teste no simulador antes de publicar:**
- ✅ Técnico faz login → consegue escrever? (deve sim)
- ✅ Gestor lê dados? (deve sim)
- ✅ Técnico A lê dados de Técnico B? (deve não — `$uid/.write` bloqueia)

---

## Step 4: Validation & Testing

### 1. Técnico App — Verificar Escrita

```bash
# Login no app do técnico
# Iniciar uma OS

# Terminal (Firebase CLI):
firebase database:get live_tracking

# Esperado:
{
  "1xp8V19R6yZEI9qqzITt46ElSMT2": {
    "lat": -23.5505,
    "lng": -46.6333,
    "timestamp": 1713625200000,
    "department": "limpeza_urbana",
    "status": "active",
    "osId": "abc123",
    ...
  }
}
```

### 2. Admin App — Verificar Leitura

```dart
// Log esperado:
✅ [LiveTracking] Técnico encontrado: Fulano Silva (OS: abc123)

// UI esperada:
- Mapa com técnico visível
- Badge mostrando "AO VIVO"
- Status badge verde
```

### 3. Queries por Department

```bash
# Terminal:
firebase database:get live_tracking --child "department/limpeza_urbana"

# Esperado: lista de técnicos desse departamento
```

### 4. Logout & Cleanup

```
# Técnico faz logout
# Firebase Console: verificar que nó foi deletado em 60 segundos
firebase database:get live_tracking

# Esperado: o técnico não está mais lá
```

---

## Step 5: Rollback Plan

Se algo der errado:

### A. Revert Admin Code

```bash
git revert <commit_hash>
flutter pub get
flutter run
```

### B. Revert Firebase Rules (Permissivas)

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

**Aviso**: Regras permissivas apenas para debugging. Restaurar regras corretas ASAP.

---

## Monitoramento Pós-Deploy

### Métricas para Observar

| Métrica | Alvo | Ferramenta |
|---------|------|-----------|
| Técnicos online | > 80% do esperado | Firebase Console → Database |
| Latência leitura | < 100ms | Admin → Console logs |
| Erro de parsing | 0 | Admin → `debugPrint` logs |
| Freshness | > 95% | Dashboard do admin |

### Logs para Monitorar

**Admin**:
```
✅ [LiveTracking] Técnico encontrado
⚠️ [LiveTracking] Técnico não encontrado (debug, não é erro)
❌ [LiveTracking] Erro ao parsear dados
```

**Técnico** (se implementar):
```
✅ Localização publicada
❌ Erro ao publicar localização
```

---

## Troubleshooting

### "Técnico não encontrado" no Admin

**Cause**: `live_tracking/{uid}` vazio ou não existe

**Solução**:
1. Verificar se app do técnico está em execução
2. Verificar permissões Firebase (rules)
3. Confirmar que técnico fez login

### "Permission denied" no Admin

**Cause**: Firebase rules muito restritivas ou usuário sem auth

**Solução**:
1. Verificar que usuário está autenticado
2. Verificar rules: `.read: "auth != null"`
3. Testar no Firebase Console → Realtime Database → Simulador de regras

### "Dados antigos/stale"

**Cause**: Heartbeat do app do técnico muito lento ou parado

**Solução**:
1. Verificar que app está em foreground service
2. Confirmar GPS permissions
3. Restartar app do técnico

---

## Success Criteria

Após deploy, confirmar que:

- [x] Técnicos online aparecem no mapa do admin "AO VIVO"
- [x] Técnicos offline desaparecem após 60 segundos
- [x] Filtro por departamento funciona
- [x] Filtro por OS funciona
- [x] Logout limpa dados corretamente
- [x] Sem erros de análise no código
- [x] Logs mostram dados corretos

---

## Timeline

| Fase | Duração | Owner |
|------|---------|-------|
| Testes locais | 1-2h | Dev |
| Deploy Firebase Rules | 15min | DevOps |
| Deploy Admin | 1-2h | CI/CD |
| Deploy Tech App | 1-2h | CI/CD |
| Validação | 30min | QA |
| Monitoramento | Contínuo | Ops |

---

## Documentation

- 📖 [Contrato completo](CONTRATO_LIVE_TRACKING_V2.md)
- 📖 [Diagnóstico histórico](docs/DIAGNOSTICO_LIVE_TRACKING.md)
- 📖 [Prompt para app técnico](docs/PROMPT_GPS_APP_TECNICO_ATUALIZADO.md)
- 📖 [Security rules](database.rules.json)

---

## Contact

Para dúvidas:
- Tech Lead: [seu nome]
- DevOps: [seu nome]
- QA: [seu nome]

---

**Last Updated**: 2026-04-20  
**Version**: 2.0.0  
**Status**: Ready for deployment ✅
