#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
alr=$($project_root/scripts/find-alr.sh)
log="$project_root/proof/obj/gnatprove-run.txt"
mkdir -p "$project_root/proof/obj"

cd "$project_root/proof"
if ! "$alr" gnatprove -P flyology_simd_proof.gpr --mode=all --level=1 -j0 \
  --output=oneline --output-header --report=all --warnings=error -U -f \
  >"$log" 2>&1
then
  cat "$log"
  exit 1
fi
cat "$log"
report="$project_root/proof/obj/gnatprove/gnatprove.out"
if [ ! -f "$report" ]; then
  printf '%s\n' "GNATprove did not write its detailed report" >&2
  exit 1
fi
if ! grep -Eq '^gnatprove version[[:space:]]+:[[:space:]]+FSF 16\.1\.0$' "$report" \
  || ! grep -Eq '^command line[[:space:]]+:.*--level=1.*-U' "$report"
then
  printf '%s\n' "GNATprove report lacks the expected invocation header" >&2
  exit 1
fi
if ! grep -Eq '^Total[[:space:]]+[1-9][0-9]*.*[[:space:]]\.[[:space:]]+\.[[:space:]]*$' "$report"
then
  printf '%s\n' "GNATprove summary has justified or unproved checks" >&2
  exit 1
fi
if ! grep -Eq \
  'Index_Arithmetic_Proof\.Stream_Indexes\.Index_At.*and proved \(6 checks\)' \
  "$report"
then
  printf '%s\n' "GNATprove did not prove the SEA index-arithmetic instance" >&2
  exit 1
fi
if ! grep -Eq \
  'Stream_Element_Arrays\.Scalar\.Find_First_Of.*flow analyzed \(0 errors, 0 checks, 0 warnings and 0 pragma Assume statements\) and proved \(0 checks\)' \
  "$report"
then
  printf '%s\n' "GNATprove did not analyze the production Scalar SEA search" >&2
  exit 1
fi
if ! grep -Eq '^Run-time Checks[[:space:]]+5[[:space:]]' "$report" \
  || ! grep -Eq '^Functional Contracts[[:space:]]+1[[:space:]]' "$report" \
  || ! grep -Eq '^Termination[[:space:]]+2[[:space:]]' "$report" \
  || ! grep -Eq '^Total[[:space:]]+8[[:space:]]' "$report"
then
  printf '%s\n' "GNATprove check categories differ from the reviewed proof boundary" >&2
  exit 1
fi
if grep -Eq 'and not proved|[1-9][0-9]* pragma Assume statements' "$report"; then
  printf '%s\n' "GNATprove report contains an unproved target or an assumption" >&2
  exit 1
fi
printf '%s\n' "Flyology_SIMD SPARK proof suite passed"
