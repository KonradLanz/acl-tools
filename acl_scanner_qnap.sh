#!/bin/sh
#
# ACL Scanner für QNAP (via SSH)
# POSIX ACLs mit getfacl
#
# ANOMALIE-LOGIK:
#   Echte Anomalie = Basis-group > ACL-mask  (mask kürzt tatsächlich)
#   - Basis: rwx (775), ACL mask: r-x → ANOMALIE! (group wird auf r-x gekurz)
#   - Basis: r-x (755), ACL mask: rwx → Redundant (keine Wirkung, harmlos)
#   - Basis: rwx (775), ACL mask: rwx → OK (keine Kürzung)
#
# VERERBUNG:
#   default:mask:: im Parent wird auf neue Dateien/kinder vererbt
#   - Parent hat default:mask::r-x → alle neuen Dateien in diesem Dir bekommen r-x
#
# KLASSEN:
#   shared_rw  - Repos die schreibbar sein sollen (dotAI, bootstrap-foundation, acl-tools)
#   shared_ro  - Archive/Backups (nur Lesen, mask::r-x ist kein Bug)
#   private    - .git, .ssh, private Configs (kein SMB-Zugriff)
#
# ToDo:
#   - [ ] Klassen-Config (acl_classes.conf) statt 1 Referenz
#   - [ ] SMB Share-Kontext (/etc/config/smb.conf) prüfen
#   - [ ] Vererbung von default:mask explizit prüfen
#   - [ ] user:: vs group:: - wirkt ACL auf user oder nur group?
#   - [ ] Best Practices: mask::rwx ist Standard, mask::r-x ist Geheimnis
#
# Author: @KonradLanz
# Date: 2026-06-17
# Version: 0.2.0 (refactored - echte Anomalie-Logik)
#

# Output Files (overwrite - fresh run)
RESOLUTION_FILE="resolution_qnap.json"
ANOMALIES_FILE="anomalies_qnap.md"

# Defaults (kann per Param übergeben werden)
REF_DIR="${REF_DIR:-dotAI}"
BASE_DIR="${BASE_DIR:-.}"

# Hilfs: Extrahiere mask aus getfacl output (trim whitespace)
get_mask()  { echo "$1" | grep "mask::"  | sed 's/.*mask:://;s/[[:space:]].*//' ; }
get_user()  { echo "$1" | grep "user::"  | sed 's/.*user:://;s/[[:space:]].*//' ; }
get_group() { echo "$1" | grep "group::" | sed 's/.*group:://;s/[[:space:]].*//' ; }

# Helper: numeric Permission (775) -> rwx
perm_to_rwx() {
    case "$1" in
        7) echo "rwx" ;;
        6) echo "rw-" ;;
        5) echo "r-x" ;;
        4) echo "r--" ;;
        3) echo "-wx" ;;
        2) echo "-w-" ;;
        1) echo "--x" ;;
        0) echo "---" ;;
        *) echo "???" ;;
    esac
}

# Helper: rwx -> numeric (7)
rwx_to_num() {
    case "$1" in
        rwx) echo 7 ;;
        rw-) echo 6 ;;
        r-x) echo 5 ;;
        r--) echo 4 ;;
        -wx) echo 3 ;;
        -w-) echo 2 ;;
        --x) echo 1 ;;
        ---) echo 0 ;;
        *) echo -1 ;;
    esac
}

echo "=== ACL Scanner QNAP (v0.2.0) ==="
echo "Base: $BASE_DIR"
echo "Referenz: $REF_DIR"
echo ""

# 1. Ref ACL (getfacl)
ref_acl=$(getfacl "$BASE_DIR/$REF_DIR" 2>/dev/null)
if [ -z "$ref_acl" ]; then
    echo "ERROR: getfacl für $BASE_DIR/$REF_DIR fehlgeschlagen"
    echo "Pruefe: sind POSIX ACLs auf QNAP aktiv? (mkfs -O acl)"
    exit 1
fi

ref_mask=$(get_mask "$ref_acl")
ref_user=$(get_user "$ref_acl")
ref_group=$(get_group "$ref_acl")

# 2. Ref Basis-Perms (stat)
ref_base=$(stat -f "%Lp" "$BASE_DIR/$REF_DIR" 2>/dev/null || echo "000")
ref_base_owner=${ref_base:0:1}
ref_base_group=${ref_base:1:1}

ref_mask_num=$(rwx_to_num "$ref_mask")
ref_base_group_num=${ref_base_group}

echo "Referenz:"
echo "  getfacl:  mask=$ref_mask user=$ref_user group=$ref_group"
echo "  ls -la:   $ref_base (owner=$ref_base_owner group=$ref_base_group)"

# 3. Check: Ist Ref-mask einschräķľnd?
#    Wenn ref_mask < ref_base_group → Ref hat schon selbst die Kürzung!
ref_mask_group_num=$(rwx_to_num "$ref_mask")
if [ "$ref_mask_group_num" -lt "$ref_base_group_num" ]; then
    echo "WARNING: Referenz hat selbst Kürzung! mask=$ref_mask < base-group=$ref_base_group"
    echo "  → Das ist shared_ro (nur Lesen) oder Bug!"
fi

# Init Output Files
echo "[" > "$RESOLUTION_FILE"
echo "# ACL Anomalien - QNAP POSIX ACL" > "$ANOMALIES_FILE"
echo ""
echo "## Referenz:"
echo "  getfacl: mask=$ref_mask user=$ref_user group=$ref_group" >> "$ANOMALIES_FILE"
echo "  ls -la:  $ref_base (owner=$ref_base_owner group=$ref_base_group)" >> "$ANOMALIES_FILE"
echo "  Kürzung: mask=$ref_mask vs base-group=$ref_base_group" >> "$ANOMALIES_FILE"
echo ""
echo "## Scan-Logik:" >> "$ANOMALIES_FILE"
echo "  Echte Anomalie = Basis-group > ACL-mask (mask kürzt tatsächlich)" >> "$ANOMALIES_FILE"
echo "  - Bug:      Basis=775, mask=r-x → elevated auf r-x" >> "$ANOMALIES_FILE"
echo "  - Redundant: Basis=755, mask=rwx → keine Wirkung" >> "$ANOMALIES_FILE"
echo "  - OK:       Basis=775, mask=rwx → keine Kürzung" >> "$ANOMALIES_FILE"
echo "" >> "$ANOMALIES_FILE"

anomalies=0

# Scan alle Dirs (maxdepth 2 = 1 Ebene tief)
dirs=$(find "$BASE_DIR" -maxdepth 2 -type d 2>/dev/null)

for dir in $dirs; do
    # Skip Ref selbst
    [ "$dir" = "$BASE_DIR/$REF_DIR" ] && continue
    
    # ACL (getfacl)
    acl=$(getfacl "$dir" 2>/dev/null) || continue
    [ -z "$acl" ] && continue
    
    mask=$(get_mask "$acl")
    user=$(get_user "$acl")
    group=$(get_group "$acl")
    
    # Basis-Perms (stat)
    base=$(stat -f "%Lp" "$dir" 2>/dev/null || echo "000")
    base_owner=${base:0:1}
    base_group=${base:1:1}
    
    # Konvertieren
    mask_num=$(rwx_to_num "$mask")
    base_group_num=$(rwx_to_num "$ref_base_group")
    
    # Check: Ist mask einschräķľnd?
    deviation=""
    risk="low"
    typo=""
    
    # Echte Anomalie: mask < base_group (KÜİZUNG!)
    if [ "$mask_num" -lt "$base_group_num" ]; then
        deviation="ANOMALIE: mask=$mask kürzt base-group=$base_group"
        risk="high"
        typo="KURZUNG"
    fi
    
    # Redundant: mask > base_group (keine Wirkung)
    if [ "$mask_num" -gt "$base_group_num" ]; then
        deviation="REDUNDANT: mask=$mask > base-group=$base_group (keine Wirkung)"
        risk="low"
        typo="REDUNDANT"
    fi
    
    # User/Group mismatch (nur wenn nicht redundant)
    if [ -z "$typo" ]; then
        if [ "$user" != "$ref_user" ]; then
            deviation="user=$user vs ref=$ref_user"
            risk="medium"
        fi
        if [ "$group" != "$ref_group" ]; then
            deviation="$deviation; group=$group vs ref=$ref_group"
            risk="medium"
        fi
    fi
    
    # Anomalie gefunden?
    if [ -n "$deviation" ] && [ "$typo" != "REDUNDANT" ]; then
        anomalies=$((anomalies + 1))
        
        # JSON
        if [ "$anomalies" -gt 1 ]; then
            echo "," >> "$RESOLUTION_FILE"
        fi
        echo "{\"path\":\"$dir\",\"mask\":\"$mask\",\"user\":\"$user\",\"group\":\"$group\",\"base\":\"$base\",\"deviation\":\"$deviation\",\"risk\":\"$risk\",\"typo\":\"$typo\",\"fix\":\"setfacl -m mask::$ref_mask $dir\"}" >> "$RESOLUTION_FILE"
        
        # Markdown
        echo "### $dir" >> "$ANOMALIES_FILE"
        echo "  getfacl: mask=$mask user=$user group=$group" >> "$ANOMALIES_FILE"
        echo "  ls -la:  $base (owner=$base_owner group=$base_group)" >> "$ANOMALIES_FILE"
        echo "  Typo:    $typo" >> "$ANOMALIES_FILE"
        echo "  Deviation: $deviation" >> "$ANOMALIES_FILE"
        echo "  Risk:    $risk" >> "$ANOMALIES_FILE"
        echo "  Fix:     setfacl -m mask::$ref_mask $dir" >> "$ANOMALIES_FILE"
        echo "" >> "$ANOMALIES_FILE"
    fi
done

echo "]" >> "$RESOLUTION_FILE"

echo ""
echo "=== Scan abgeschlossen ==="
echo "Anomalien: $anomalies"
echo "Resolution: $RESOLUTION_FILE"
echo "Report:     $ANOMALIES_FILE"
