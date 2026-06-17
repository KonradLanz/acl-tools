# CLI Specification: acl-scanner

## Command

```bash
acl-scanner [OPTIONS] <PATH>
```

## Optionen

| Option | Beschreibung |
|--------|-------------|
| `--recursive` | Rekursiv durch alle Unterverzeichnisse scannen |
| `--reference REF` | Referenz-ACL von REF verwenden (z.B. `dotAI` als Normal) |
| `--output FORMAT` | Ausgabeformat: `markdown`, `json`, `table` (default: `table`) |
| `--output-file FILE` | Ergebnis in FILE schreiben (statt stdout) |
| `--risk-threshold N` | Nur Ausgaben ab Risikoklasse N (low=1, medium=2, high=3) |
| `--share SHARE` | SMB-Share-Name für Kontext (z.B. `nw`) |

## Ausgabe

### Table-Format (default)

```text
PATH                          OWNER    GROUP    MASK     DEV    RISK    STATUS
----------------------------------------------------------------------
w/bootstrap-foundation/foo    user1    grp1     r-x      +1   medium  offen
dotAI/bar                     user1    grp1     rwx      0    low     geprüft
```

### JSON-Format

```json
{
  "scan_metadata": {
    "path": "/nw/nas/git",
    "recursive": true,
    "reference": "dotAI",
    "timestamp": "2026-06-17T19:00:00Z"
  },
  "results": [
    {
      "path": "bootstrap-foundation/foo",
      "owner": "user1",
      "group": "grp1",
      "effective_mask": "r-x",
      "deviation": "+1",
      "risk_class": "medium",
      "correction_proposal": "mask::rwx",
      "status": "open"
    }
  ]
}
```

## Beispiele

```bash
# Rekursiv scannen, JSON-Output
acl-scanner --recursive --output json ~/nw/nas/git

# Mit Referenz, nur medium/high Risiko
acl-scanner --recursive --reference dotAI --risk-threshold 2 ~/nw/nas/git

# Ergebnis in Markdown-File
acl-scanner --recursive --output markdown --output-file acl-report.md ~/nw/nas/git
```

## Exit Codes

| Code | Bedeutung |
|------|----------|
| 0 | Scan erfolgreich, keine Anomalien gefunden |
| 1 | Scan erfolgreich, Anomalien gefunden |
| 2 | Fehler (z.B. ungä·īgiger Pfad, getfacl nicht verfügbar) |
