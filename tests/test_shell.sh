#!/usr/bin/env bash
# Testy dla ArekBox-Installer — sprawdzają składnię skryptów i dostępność funkcji.
# Uruchomienie: bash tests/test_shell.sh

set -euo pipefail

AREKBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc — expected '$expected', got '$actual'"
        FAIL=$((FAIL + 1))
    fi
}

assert_true() {
    local desc="$1"
    if eval "$2"; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc — condition '$2' was false"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== ArekBox-Installer Shell Tests ==="
echo ""

# 1. Wszystkie skrypty .sh mają poprawną składnię (bash -n)
echo "--- Składnia skryptów (bash -n) ---"
shopt -s nullglob
scripts=(
    "$AREKBOX_DIR/arekbox.sh"
    "$AREKBOX_DIR/arekbox-dashboard.sh"
    "$AREKBOX_DIR/yt-dlp-dashboard.sh"
    "$AREKBOX_DIR"/modules/*.sh
    "$AREKBOX_DIR"/ffmpeg-scripts/*.sh
    "$AREKBOX_DIR"/media-scripts/*.sh
)

for script in "${scripts[@]}"; do
    if bash -n "$script" 2>/dev/null; then
        echo "PASS: składnia $script"
        PASS=$((PASS + 1))
    else
        echo "FAIL: składnia $script"
        FAIL=$((FAIL + 1))
    fi
done

echo ""

# 2. Funkcje pomocnicze z arekbox.sh są dostępne
echo "--- Funkcje pomocnicze (arekbox.sh) ---"
# Źródłujemy tylko definicje funkcji, nie uruchamiamy pętli głównej.
# arekbox.sh po sourcowaniu wykona pętlę while, więc ładujemy tylko fragment z funkcjami.
# Prostsze podejście: wyciągamy definicje funkcji i testujemy je osobno.
source <(sed -n '1,16p' "$AREKBOX_DIR/arekbox.sh")

assert_true "print_success istnieje" 'declare -f print_success >/dev/null'
assert_true "print_error istnieje" 'declare -f print_error >/dev/null'
assert_true "print_info istnieje" 'declare -f print_info >/dev/null'
assert_true "print_warning istnieje" 'declare -f print_warning >/dev/null'
assert_true "pause istnieje" 'declare -f pause >/dev/null'

echo ""

# 3. Kolory są zdefiniowane
echo "--- Zmienne kolorów ---"
assert_true "CYAN zdefiniowane" '[[ -n "${CYAN:-}" ]]'
assert_true "RED zdefiniowane" '[[ -n "${RED:-}" ]]'
assert_true "GREEN zdefiniowane" '[[ -n "${GREEN:-}" ]]'
assert_true "YELLOW zdefiniowane" '[[ -n "${YELLOW:-}" ]]'
assert_true "NC zdefiniowane" '[[ -n "${NC:-}" ]]'

echo ""

# 4. Moduły można źródłować (nie wyrzucają błędów przy ładowaniu definicji)
echo "--- Źródłowanie modułów ---"
for mod in "$AREKBOX_DIR"/modules/*.sh; do
    mod_name="$(basename "$mod")"
    if source <(head -n -1 "$mod") 2>/dev/null; then
        echo "PASS: moduł $mod_name źródłuje się poprawnie"
        PASS=$((PASS + 1))
    else
        echo "FAIL: moduł $mod_name nie źródłuje się"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "=== Wynik: $PASS passed, $FAIL failed ==="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0