# Prompt-Format für local-ai-stack: ACL-Resolution

## Kontext

Dieser Prompt wird verwendet, um ein LLM (via local-ai-stack) Handlungsvorschlä·īg für reparierte ACL-Anomalien zu generieren.

## Eingabe-Format (JSON)

```json
{
  "scan_metadata": {
    "share": "nw",
    "path": "/nw/nas/git",
    "reference": "dotAI"
  },
  "anomalies": [
    {
      "path": "bootstrap-foundation/foo",
      "owner": "user1",
      "group": "grp1",
      "current_mask": "r-x",
      "reference_mask": "rwx",
      "risk_class": "medium"
    }
  ]
}
```

## Prompt-Template

```text
Du bist ein ACL-Experte für SMB/Samba-Shares auf QNAP-NAS.

Kontext:
- Share: ${scan_metadata.share}
- Basis-Path: ${scan_metadata.path}
- Referenz-ACL (Normalfall): ${scan_metadata.reference} mit mask::rwx

Finde:
${anomalies.map(a => `
Pfad: ${a.path}
- Owner: ${a.owner}
- Group: ${a.group}
- Aktuelle Maske: ${a.current_mask}
- Referenz-Maske: ${a.reference_mask}
- Risikoklasse: ${a.risk_class}
`).join('
')}

Aufgabe:
1. Für jede Anomalie einen konkreten Korrekturvorschlag machen (z.B. `chmod g+rwX ...` oder `setfacl -m m:rwx ...`)
2. Bei medium/high Risiko: vorherige Prüfung empfehlen (z.B. anderen Admin kontaktieren)
3. Einen zusammengefassten Ablaufplan geben, der alle Reparaturen in einer sicheren Reihenfolge beschreibt

Ausgabe-Format (Markdown):

## ACL-Reparaturplan für ${scan_metadata.share}

### Einzelne Reparaturen

| Pfad | Aktuelle Maske | Ziel-Maske | Beteiligten | Risiko | Vorschlag |
|------|---------------|------------|-------------|--------|----------|
| ...  | ...           | ...        | ...         | ...    | ...      |

### Abladeplan (schrittweise)

1. Schritt 1: ...
   - Befehl: ...
   - Erwartetes Ergebnis: ...
   - Eventuelle Nebenwirkungen: ...

2. Schritt 2: ...
   ...

### Empfehlungen

- Prüfe vor hoch-Risiko-Reparaturen mit anderem Admin
- Fasse eine Ad-change nie auf mehrere Shares gleichzeitig aus
- Dokumentiere alle Änderungen in einem Change-Log
```

## Ausgabe-Beispiel (erwartet)

```markdown
## ACL-Reparaturplan für nw

### Einzelne Reparaturen

| Pfad | Aktuelle Maske | Ziel-Maske | Beteiligte | Risiko | Vorschlag |
|------|---------------|------------|------------|--------|----------|
| bootstrap-foundation/foo | r-x | rwx | user1/grp1 | medium | `setfacl -m m:rwx bootstrap-foundation/foo` |

### Ablaufplan (schrittweise)

1. Schritt 1: bootstrap-foundation/foo reparieren
   - Befehl: `setfacl -m m:rwx ~/nw/nas/git/bootstrap-foundation/foo`
   - Erwartetes Ergebnis: `mask::rwx` statt `mask::r-x`
   - Eventuelle Nebenwirkungen: Keine (nur dieses Verzeichnis)

### Empfehlungen

- Prüfe vor hoch-Risiko-Reparaturen mit anderem Admin
- Dokumentiere alle Änderungen in einem Change-Log (
```

## Nutzung in local-ai-stack

```bash
# JSON-Input in Datei schreiben
echo '{...}' > acl-anomalies.json

# Prompt mit local-ai-stack generieren
cat LLM_PROMPT.md | sed "s|\${scan_metadata.share}|nw|" | \
  llm inference --input acl-anomalies.json --model mlx
```
