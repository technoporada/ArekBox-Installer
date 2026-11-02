#!/bin/bash
pdf_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA PDF ===${NC}"
        echo "1) Połącz PDF"
        echo "2) Podziel PDF"
        echo "3) Kompresuj PDF"
        echo "4) Wyodrębnij tekst z PDF"
        echo "5) PDF do obrazu"
        echo "6) Zainstaluj narzędzia PDF"
        echo "0) Powrót"
        read -r -p "Wybierz opcję: " choice
        case "$choice" in
            1) pdf_merge ;;
            2) pdf_split ;;
            3) pdf_compress ;;
            4) pdf_extract_text ;;
            5) pdf_to_image ;;
            6) install_pdf_tools ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_pdf_tools() {
    sudo apt install -y poppler-utils ghostscript pdftk-java 2>/dev/null
    pip3 install --user PyPDF2 pdf2image 2>/dev/null
    print_success "Narzędzia PDF zainstalowane!"
    pause
}

pdf_merge() {
    read -r -p "Katalog z plikami PDF: " d
    read -r -p "Nazwa wyjściowa (np. merged.pdf): " out
    # Walidacja ścieżki katalogu (brak traversal)
    case "$d" in
        ''|*[!a-zA-Z0-9./_-]*) print_error "Nieprawidłowa ścieżka katalogu."; pause; return ;;
    esac
    # Limit łączny: 500 MB, plik: 100 MB
    local total=0
    for f in "$d"/*.pdf; do
        [ -f "$f" ] || continue
        local sz
        sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
        if [ "$sz" -gt 104857600 ]; then
            print_error "Plik za duży (>100 MB): $f"; pause; return
        fi
        total=$((total + sz))
        if [ "$total" -gt 524288000 ]; then
            print_error "Łączny rozmiar przekracza 500 MB."; pause; return
        fi
    done
    if command -v pdftk &>/dev/null; then
        pdftk "$d"/*.pdf cat output "$AREKBOX_DIR/$out"
        print_success "Połączono: $AREKBOX_DIR/$out"
    else
        python3 - "$d" "$out" << 'PYEOF'
import PyPDF2, sys, os
d = sys.argv[1]
out = sys.argv[2]
MAX_PAGES = 1000
merger = PyPDF2.PdfMerger()
total_pages = 0
for f in sorted(os.listdir(d)):
    if f.endswith('.pdf'):
        r = PyPDF2.PdfReader(os.path.join(d, f))
        np = len(r.pages)
        if total_pages + np > MAX_PAGES:
            print(f"Przekroczono limit {MAX_PAGES} stron (plik: {f})")
            sys.exit(1)
        total_pages += np
        merger.append(os.path.join(d, f))
merger.write(os.path.join(os.getenv('AREKBOX_DIR', ''), out))
merger.close()
print('Połączono:', os.path.join(os.getenv('AREKBOX_DIR', ''), out))
PYEOF
        if [ $? -ne 0 ]; then print_error "Brak PyPDF2 lub błąd przetwarzania — zainstaluj: pip3 install PyPDF2"; fi
    fi
    pause
}

pdf_split() {
    read -r -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    # Limit pliku: 100 MB
    local sz
    sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
    if [ "$sz" -gt 104857600 ]; then
        print_error "Plik za duży (>100 MB)."; pause; return
    fi
    read -r -p "Zakres stron (np. 1-3,5,7-9): " r
    [ -z "$r" ] && { print_error "Nie podano zakresu!"; pause; return; }
    python3 - "$f" "$r" << 'PYEOF'
import PyPDF2, sys, os

def parse_range(range_str):
    pages = set()
    for part in range_str.split(','):
        part = part.strip()
        if '-' in part:
            start, end = part.split('-', 1)
            pages.update(range(int(start), int(end) + 1))
        else:
            pages.add(int(part))
    return sorted(pages)

MAX_PAGES = 1000
f = sys.argv[1]
r = sys.argv[2]
out = os.path.join(os.getenv('AREKBOX_DIR', ''), 'split-output.pdf')
with open(f, 'rb') as fh:
    reader = PyPDF2.PdfReader(fh)
    npages = len(reader.pages)
    if npages > MAX_PAGES:
        print(f"Plik ma {npages} stron — przekracza limit {MAX_PAGES}.")
        sys.exit(1)
    writer = PyPDF2.PdfWriter()
    pages = parse_range(r)
    for p in pages:
        if 1 <= p <= len(reader.pages):
            writer.add_page(reader.pages[p - 1])
    with open(out, 'wb') as oh:
        writer.write(oh)
print('Zapisano:', out)
PYEOF
    if [ $? -ne 0 ]; then print_error "Błąd — zainstaluj PyPDF2"; fi
    pause
}

pdf_compress() {
    read -r -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
       -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$f-compressed.pdf" "$f"
    print_success "Skompresowano: $f-compressed.pdf"
    pause
}

pdf_extract_text() {
    read -r -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    pdftotext "$f" "$f.txt"
    print_success "Tekst wyodrębniony: $f.txt"
    pause
}

pdf_to_image() {
    read -r -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    python3 - "$f" << 'PYEOF'
from pdf2image import convert_from_path
import sys, os
f = sys.argv[1]
images = convert_from_path(f)
for i, img in enumerate(images):
    img.save(f + '-page-' + str(i+1) + '.png', 'PNG')
print('Konwersja zakończona')
PYEOF
    if [ $? -ne 0 ]; then
        sudo apt install -y poppler-utils 2>/dev/null
        pdftoppm "$f" "$f-page" -png
        print_success "Konwersja zakończona"
    fi
    pause
}

pdf_menu