# .ai Anchors — acl-tools

> Neugier-Anker: offene Fragen, die wir später träumen oder mit local-ai-stack klären.
> Kein stiller Fallback — jeder unbekannte Fall ist ein Lernmoment.

## ANKER: unknown $SYSTEM in stat_perms()

```sh
# Aktuell (still bad):
*) echo "000" ;;
# Oder:
*) echo "" ;;
```

**Fragen:**
- Welche Systeme existieren außer macOS/QNAP/Linux?
- Alpine? WSL2? FreeBSD? Docker container?
- Was ist der richtige stat-Aufruf auf jedem?

**Aktion:**
- [ ] local-ai-stack: Prompt mit `uname -a` output und Frage nach `stat` Format
- [ ] bootstrap-foundation/lib/detect-system.sh: system_map.json erweitern
- [ ] ggf. GitHub Issue auf bootstrap-foundation öffnen

**Cue:** `stat_perms unknown system` → findet diesen Anker

---

## ANKER: .ai Kontext-Folder mit Zeit-Granularität

**Idee:**
```
.ai/
  latest/          ← symlink auf aktuellsten Slot (1-3h)
  2026-06-17T19/   ← Slot für 19:00-22:00 (3h Granularität)
  2026-06-17T16/   ← älterer Slot, komprimierter
  archive/         ← Cue-only: starke Keywords, kein Volltext
```

**decay.sh** (träumt während du schläfst):
- `latest/` → nach 3h archivieren
- Abstraktionen extrahieren, Volltext komprimieren
- Cues beibehalten ("never really forget if the cue is strong enough")

**Aktion:**
- [ ] decay.sh schreiben (crontab: jede 1h)
- [ ] Struktur in dotAI upstream dokumentieren
- [ ] Backflow: dotAI/adr/002-ai-context-decay.md

**Cue:** `.ai decay granularity dream` → findet diesen Anker

---

## ANKER: exception handling policy (Principle 9)

**Problem:** Drei Strategien für unbekannte Fälle:
1. local-ai-stack (schnell, lokal, review nötig)
2. GitHub Issue (persistent, öffentlich, teuer)
3. TODO anchor (billig, lokal, vergessbar)

**Kosten-Matrix:**
| Typ | Lernkosten | Austauschkosten | Persistence |
|-----|-----------|----------------|-------------|
| local-ai-stack | niedrig | mittel | Kontext-flushbar |
| GitHub Issue | mittel | niedrig | permanent |
| TODO anchor | sehr niedrig | hoch | vergessbar |

**Frage:** Wann welche Strategie?

**Cue:** `exception handling escalation local-ai github issue` → findet diesen Anker

---

## ANKER: system_map.json in bootstrap-foundation

```json
{
  "commands": {
    "stat_perms": {
      "macos": "stat -f \"%Lp\"",
      "qnap": "stat -c \"%A\"",
      "linux": "stat -c \"%A\"",
      "alpine": "stat -c \"%A\"",
      "unknown": "TODO: investigate"
    },
    "getfacl": {
      "macos": "NOT_AVAILABLE (use ls -le for extended ACLs)",
      "qnap": "getfacl",
      "linux": "getfacl",
      "alpine": "getfacl (wenn acl package installiert)",
      "unknown": "TODO: investigate"
    }
  }
}
```

**Aktion:**
- [ ] bootstrap-foundation/lib/system_map.json erstellen
- [ ] detect-system.sh: system_map.json laden
- [ ] acl_scanner_qnap.sh: system_map.json nutzen

**Cue:** `system_map stat getfacl cross-platform` → findet diesen Anker
