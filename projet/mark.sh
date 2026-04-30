#!/usr/bin/env bash

BIN="factorielle"
SCORE=0
MALUS=0

# Recupere nom/prenom meme si readme.txt est absent ou mal formate.
get_student_identity() {
  STUDENT_NOM=""
  STUDENT_PRENOM=""

  if [ -f "readme.txt" ]; then
    read -r STUDENT_PRENOM STUDENT_NOM _ < readme.txt
  fi

  [ -n "$STUDENT_NOM" ] || STUDENT_NOM="Inconnu"
  [ -n "$STUDENT_PRENOM" ] || STUDENT_PRENOM="Inconnu"
}

#Partie points

# 1) Compilation
make >/dev/null 2>&1
if [ ! -x "./$BIN" ]; then
  echo "[Compilation] KO -> note finale: 0"
  get_student_identity
  [ -f note.csv ] || echo "Nom,Prenom,Note" > note.csv
  printf "%s,%s,0\n" "${STUDENT_NOM%$'\r'}" "${STUDENT_PRENOM%$'\r'}" >> note.csv
  echo "0"
  exit 0
fi

SCORE=$((SCORE + 2))
echo "[Compilation] OK -> +2 (score: $SCORE)"

# 2) Cas general
ok_general=1
for n in 1 2 3 4 5 6 7 8 9 10; do
  expected=1
  i=1
  while [ "$i" -le "$n" ]; do
    expected=$((expected * i))
    i=$((i + 1))
  done

  output="$("./$BIN" "$n" 2>/dev/null)"
  output="$(printf '%s' "$output" | tr -d '\r')"
  if [ "$output" != "$expected" ]; then
    ok_general=0
    break
  fi
done
if [ "$ok_general" -eq 1 ]; then
  SCORE=$((SCORE + 5))
  echo "[Cas 1..10] OK -> +5 (score: $SCORE)"
else
  echo "[Cas 1..10] KO -> +0 (score: $SCORE)"
fi

# 3) Cas factorielle de 0
output_zero="$("./$BIN" 0 2>/dev/null || true)"
output_zero="$(printf '%s' "$output_zero" | tr -d '\r')"
if [ "$output_zero" = "1" ]; then
  SCORE=$((SCORE + 3))
  echo "[Cas 0] OK -> +3 (score: $SCORE)"
else
  echo "[Cas 0] KO (sortie: $output_zero) -> +0 (score: $SCORE)"
fi

# 4) Signature exacte
if [ -f "main.c" ]; then
  if grep -Fq "int factorielle( int number )" main.c; then
    SCORE=$((SCORE + 2))
    echo "[Signature] OK -> +2 (score: $SCORE)"
  else
    echo "[Signature] KO -> +0 (score: $SCORE)"
  fi
else
  echo "[Signature] main.c manquant -> +0 (score: $SCORE)"
fi

# 5) Message sans argument
real_noarg="$("./$BIN" 2>&1 || true)"
real_noarg="$(printf '%s' "$real_noarg" | tr -d '\r')"
if [ "$real_noarg" = "Erreur: Mauvais nombre de parametres" ]; then
  SCORE=$((SCORE + 4))
  echo "[Message sans argument] OK -> +4 (score: $SCORE)"
else
  echo "[Message sans argument] KO (sortie: $real_noarg) -> +0 (score: $SCORE)"
fi

# 6) Message argument negatif
real_neg="$("./$BIN" -5 2>&1 || true)"
real_neg="$(printf '%s' "$real_neg" | tr -d '\r')"
if [ "$real_neg" = "Erreur: nombre negatif" ]; then
  SCORE=$((SCORE + 4))
  echo "[Message negatif] OK -> +4 (score: $SCORE)"
else
  echo "[Message negatif] KO (sortie: $real_neg) -> +0 (score: $SCORE)"
fi

#Partie malus

# A) ligne > 80 chars
line_too_long=0
for f in main.c header.h; do
  if [ -f "$f" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      if [ "${#line}" -gt 80 ]; then
        line_too_long=1
        break
      fi
    done < "$f"
  fi
  [ "$line_too_long" -eq 1 ] && break
done
[ "$line_too_long" -eq 1 ] && MALUS=$((MALUS + 2))
if [ "$line_too_long" -eq 1 ]; then
  echo "[Malus >80 chars] OUI -> -2 (malus: $MALUS)"
else
  echo "[Malus >80 chars] NON -> -0 (malus: $MALUS)"
fi

# B) header .h manquant
has_header=0
for h in *.h; do
  if [ -f "$h" ]; then
    has_header=1
    break
  fi
done

if [ "$has_header" -eq 0 ]; then
  MALUS=$((MALUS + 2))
  echo "[Malus header manquant] OUI -> -2 (malus: $MALUS)"
else
  echo "[Malus header manquant] NON -> -0 (malus: $MALUS)"
fi

# C) indentation
indent_bad=0
for f in main.c header.h; do
  if [ -f "$f" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      trimmed="${line#"${line%%[![:space:]]*}"}"
      case "$trimmed" in
        "" | "//"* | "/*"* | "*" | "*/"* | "#"*) continue ;;
      esac

      case "$line" in
        $'\t'* ) indent_bad=1; break ;; 
      esac

      leading_spaces="${line%%[^ ]*}"
      if [ $(( ${#leading_spaces} % 2 )) -ne 0 ]; then
        indent_bad=1
        break
      fi

    done < "$f"
  fi
  [ "$indent_bad" -eq 1 ] && break
done
[ "$indent_bad" -eq 1 ] && MALUS=$((MALUS + 2))
if [ "$indent_bad" -eq 1 ]; then
  echo "[Malus indentation] OUI -> -2 (malus: $MALUS)"
else
  echo "[Malus indentation] NON -> -0 (malus: $MALUS)"
fi

# D) make clean doit supprimer l'executable
if make clean >/dev/null 2>&1; then
  if [ -e "./$BIN" ]; then
    MALUS=$((MALUS + 2))
    echo "[Malus make clean] KO -> -2 (malus: $MALUS)"
  else
    echo "[Malus make clean] OK -> -0 (malus: $MALUS)"
  fi
else
  MALUS=$((MALUS + 2))
  echo "[Malus make clean] Regle absente/erreur -> -2 (malus: $MALUS)"
fi

#Note finale

NOTE=$((SCORE - MALUS))
[ "$NOTE" -lt 0 ] && NOTE=0
[ "$NOTE" -gt 20 ] && NOTE=20

echo "=== Resume: score=$SCORE | malus=$MALUS | note=$NOTE ==="
echo "$NOTE"

#Fichier CSV
get_student_identity
[ -f note.csv ] || echo "Nom,Prenom,Note" > note.csv
printf "%s,%s,%s\n" "${STUDENT_NOM%$'\r'}" "${STUDENT_PRENOM%$'\r'}" "$NOTE" >> note.csv