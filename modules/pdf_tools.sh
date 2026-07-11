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
        read -p "Wybierz opcję: " choice
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
    read -p "Katalog z plikami PDF: " d
    read -p "Nazwa wyjściowa (np. merged.pdf): " out
    if command -v pdftk &>/dev/null; then
        pdftk "$d"/*.pdf cat output "$AREKBOX_DIR/$out"
        print_success "Połączono: $AREKBOX_DIR/$out"
    else
        python3 -c "
import PyPDF2, sys, os
d='$d'; out='$out'
merger = PyPDF2.PdfMerger()
for f in sorted(os.listdir(d)):
    if f.endswith('.pdf'):
        merger.append(os.path.join(d, f))
merger.write('$AREKBOX_DIR/'+out)
merger.close()
print('Połączono:', '$AREKBOX_DIR/'+out)
" 2>/dev/null || print_error "Brak PyPDF2 — zainstaluj: pip3 install PyPDF2"
    fi
    pause
}

pdf_split() {
    read -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    read -p "Zakres stron (np. 1-3,5,7-9): " r
    [ -z "$r" ] && { print_error "Nie podano zakresu!"; pause; return; }
    python3 -c "
import PyPDF2

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

with open('$f', 'rb') as fh:
    reader = PyPDF2.PdfReader(fh)
    writer = PyPDF2.PdfWriter()
    pages = parse_range('$r')
    for p in pages:
        if 1 <= p <= len(reader.pages):
            writer.add_page(reader.pages[p - 1])
    with open('$AREKBOX_DIR/split-output.pdf', 'wb') as oh:
        writer.write(oh)
print('Zapisano: $AREKBOX_DIR/split-output.pdf')
" 2>/dev/null || print_error "Błąd — zainstaluj PyPDF2"
    pause
}

pdf_compress() {
    read -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
       -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$f-compressed.pdf" "$f"
    print_success "Skompresowano: $f-compressed.pdf"
    pause
}

pdf_extract_text() {
    read -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    pdftotext "$f" "$f.txt"
    print_success "Tekst wyodrębniony: $f.txt"
    pause
}

pdf_to_image() {
    read -p "Plik PDF: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    python3 -c "
from pdf2image import convert_from_path
import sys
images = convert_from_path('$f')
for i, img in enumerate(images):
    img.save('$f-page-'+str(i+1)+'.png', 'PNG')
print('Konwersja zakończona')
" 2>/dev/null || {
        sudo apt install -y poppler-utils 2>/dev/null
        pdftoppm "$f" "$f-page" -png
        print_success "Konwersja zakończona"
    }
    pause
}

pdf_menu
