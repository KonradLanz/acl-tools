# acl-tools

ACL-Anomalie-Erkennung für SMB/QNAP-Shares.

## Ziel

- ACL-Anomalien auf Samba/SMB-Shares automatisch finden
- Rechtekombinationen vergleichen und Gruppen von Pfaden mit verdä·ībigen Abweichungen erzeugen
- Eine übersichtliche Resolution-Liste erstellen (manuell oder mit local-ai-stack abarbeiten)
- Ergebnisse so aufbereiten, dass ein LLM mit einem passenden Prompt klare Handlungsvorschlä·īg machen kann

## Motivation

Der ursprüngliche Fall: `bootstrap-foundation` war auf dem SMB-Mount nicht schreibbar, Ursache war eine abweichende ACL-Maske `mask::r-x` gegenüber dem vergleichbaren `dotAI`-Verzeichnis mit `mask::rwx`.

Solche Fälle sind Kandidaten für automatische Erkennung und Normalisierung.

## Funktionsblö·Į·Ď

1. **Scanner** für `getfacl`-Ausgaben
2. **Vergleich** normaler und abweichender ACL-Muster
3. **Heuristiken** für typische SMB/QNAP-Probleme
4. **Export** einer Resolution-Liste als Markdown/JSON
5. Optionaler **LLM-Workflow** über local-ai-stack zur Vorschlagsgenerierung

## Datenmodell

| Feld | Beschreibung |
|------|-------------|
| `path` | Pfad zur ACL |
| `owner` | Owner der ACL |
| `group` | Group der ACL |
| `effective_mask` | Effektive Maske (z.B. `rwx`) |
| `deviation` | Abweichung zum Referenzmuster |
| `risk_class` | Risikoklasse (low/medium/high) |
| `correction_proposal` | Vorschlag zur Korrektur |
| `status` | offen, geprüft, repariert |

## Offene Fragen

- Welche Referenz-ACL gilt als „normal“ für einen Share?
- Wie stark soll ein Tool in bestehende ACLs eingreifen?
- Soll das Tool nur erkennen oder auch direkt reparieren können?
- Welche Rolle spielt Windows ACL vs. POSIX ACL auf QNAP genau?

## Nächste Schritte

- [ ] Spec schreiben
- [ ] Reale ACL-Beispiele sammeln
- [ ] Erste Scanner-CLI definieren
- [ ] Prompt-Format für local-ai-stack festlegen

## Abhä·īgkeiten

- POSIX ACL (getfacl) auf QNAP
- Optional: local-ai-stack für LLM-Unter erstellung
