#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
alr=$($project_root/scripts/find-alr.sh)
broad_log="$project_root/proof/obj/gnatprove-broad-run.txt"
broad_report="$project_root/proof/obj/gnatprove-broad.out"
sea_log="$project_root/proof/obj/gnatprove-sea-run.txt"
mkdir -p "$project_root/proof/obj"

cd "$project_root/proof"
if ! "$alr" gnatprove -P flyology_simd_proof.gpr --mode=all --level=1 -j0 \
  --output=oneline --output-header --report=all --warnings=error -U -f \
  >"$broad_log" 2>&1
then
  cat "$broad_log"
  exit 1
fi
report="$project_root/proof/obj/gnatprove/gnatprove.out"
if [ ! -f "$report" ]; then
  printf '%s\n' "GNATprove did not write its detailed report" >&2
  exit 1
fi
if ! grep -Eq '^gnatprove version[[:space:]]+:[[:space:]]+FSF 16\.1\.0$' "$report" \
  || ! grep -Eq '^command line[[:space:]]+:.*--level=1.*--warnings=error.*-U' "$report"
then
  printf '%s\n' "GNATprove broad report lacks the expected invocation header" >&2
  exit 1
fi
if ! grep -Eq '^Analyzed 33 units$' "$report" \
  || ! grep -Eq '^Total[[:space:]]+[1-9][0-9]{3,}.*[[:space:]]\.[[:space:]]+\.[[:space:]]*$' "$report"
then
  printf '%s\n' "GNATprove broad coverage collapsed or has justified or unproved checks" >&2
  exit 1
fi
if ! grep -Eq \
  'Stream_Element_Arrays\.Native\.Implementation\.Find_First_Of.*and proved \([1-9][0-9]* checks\)' \
  "$report"
then
  printf '%s\n' "GNATprove did not prove the production Native SEA traversal" >&2
  exit 1
fi
if ! grep -Eq \
  'Stream_Element_Arrays\.Native\.Implementation\.Index_Arithmetic\.Index_At.*and proved \(6 checks\)' \
  "$report"
then
  printf '%s\n' "GNATprove did not prove production Native SEA index arithmetic" >&2
  exit 1
fi
if ! grep -Eq \
  'Stream_Element_Arrays\.Scalar\.Find_First_Of.*0 pragma Assume statements\).*and proved \(0 checks\)' \
  "$report"
then
  printf '%s\n' "GNATprove did not analyze the production Scalar SEA search" >&2
  exit 1
fi
if grep -Eq 'and not proved|[1-9][0-9]* pragma Assume statements' "$report"; then
  printf '%s\n' "GNATprove broad report contains an unproved target or an assumption" >&2
  exit 1
fi
cp "$report" "$broad_report"

#  Re-run the safety-critical SEA traversal independently so broad coverage
#  cannot mask accidental loss of its production proof target.
if ! "$alr" gnatprove -P flyology_simd_proof.gpr --mode=all --level=1 -j0 \
  --output=oneline --report=all --warnings=error \
  -u flyology_simd-algorithms-stream_element_arrays-native.adb \
  >"$sea_log" 2>&1
then
  cat "$sea_log"
  exit 1
fi
if grep -Eq 'and not proved|[1-9][0-9]* pragma Assume statements' "$report" \
  || ! grep -Eq \
    'Stream_Element_Arrays\.Native\.Implementation\.Find_First_Of.*and proved \([1-9][0-9]* checks\)' \
    "$report"
then
  printf '%s\n' "GNATprove focused SEA report is incomplete" >&2
  exit 1
fi

sed -n '10,26p' "$broad_report"
printf '%s\n' "Flyology_SIMD broad SPARK campaign and warning-clean SEA proof passed"
