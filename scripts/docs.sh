#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
alr=$("$project_root/scripts/find-alr.sh")
documentation_output="$project_root/docs/api"
website_kit="$project_root/vendor/website-kit"
warning_baseline_file="$project_root/docs/gnatdoc-warning-baseline.txt"
expected_warnings_file="$project_root/docs/gnatdoc-expected-warnings.txt"

if [ ! -f "$website_kit/scripts/render-gnatdoc-theme.mjs" ]; then
   printf '%s\n' \
     "website kit is unavailable; run: git submodule update --init" >&2
   exit 1
fi

if ! command -v gnatdoc >/dev/null 2>&1; then
   installed_gnatdoc="${ALIRE_INSTALL_PREFIX:-"$HOME/.alire"}/bin/gnatdoc"
   if [ ! -x "$installed_gnatdoc" ]; then
      printf '%s\n' \
        "gnatdoc not found; install it with: $alr install gnatdoc_bin" >&2
      exit 1
   fi
   PATH=$(dirname "$installed_gnatdoc"):$PATH
   export PATH
fi

case "$documentation_output" in
   "$project_root"/docs/api) ;;
   *)
      printf '%s\n' \
        "refusing unsafe documentation output path: $documentation_output" >&2
      exit 1
      ;;
esac

cd "$project_root"
python3 "$project_root/scripts/check_api_support_docs.py"
"$alr" build -- -XFLYOLOGY_SIMD_ARCH=scalar
rm -rf "$documentation_output"
node "$website_kit/scripts/render-gnatdoc-theme.mjs" \
  "$project_root/docs/gnatdoc-theme.json" \
  "$project_root/docs/gnatdoc/html"
gnatdoc_log=$(mktemp -t flyology-simd-gnatdoc.XXXXXX)
normalized_warnings=$(mktemp -t flyology-simd-gnatdoc-normalized.XXXXXX)
unexpected_warnings=$(mktemp -t flyology-simd-gnatdoc-unexpected.XXXXXX)
trap 'rm -f "$gnatdoc_log" "$normalized_warnings" "$unexpected_warnings"' EXIT HUP INT TERM
if ! "$alr" exec -- gnatdoc \
  --backend=html \
  --generate=public \
  --warnings \
  --style=gnat \
  -P flyology_simd.gpr \
  -XFLYOLOGY_SIMD_ARCH=scalar \
  -O docs/api >"$gnatdoc_log" 2>&1
then
   cat "$gnatdoc_log" >&2
   exit 1
fi
cat "$gnatdoc_log"
warning_count=$(awk '/warning:/ { count++ } END { print count + 0 }' "$gnatdoc_log")
#  GNATdoc 26 reports the formals of a documented deep private generic as
#  undocumented. Match complete normalized diagnostics so every other warning
#  remains subject to the zero-warning baseline.
if [ ! -s "$expected_warnings_file" ] \
  || grep -Eqv '^[^:]+: warning: .+$' "$expected_warnings_file"
then
   printf '%s\n' "invalid expected GNATdoc warnings file" >&2
   exit 1
fi
sed -nE \
  '/warning:/ { s/^([^:]+):[0-9]+:[0-9]+: (warning:.*)$/\1: \2/; p; }' \
  "$gnatdoc_log" >"$normalized_warnings"
if grep -Fvx -f "$expected_warnings_file" "$normalized_warnings" \
  >"$unexpected_warnings"
then
   :
else
   status=$?
   test "$status" -eq 1 || exit "$status"
fi
unexpected_warning_count=$(wc -l <"$unexpected_warnings" | tr -d ' ')
warning_baseline=$(cat "$warning_baseline_file")
if [ "$unexpected_warning_count" -gt "$warning_baseline" ]; then
   cat "$unexpected_warnings" >&2
   printf '%s\n' \
     "Unexpected GNATdoc warning count increased: $unexpected_warning_count > $warning_baseline" >&2
   exit 1
fi
expected_warning_count=$((warning_count - unexpected_warning_count))
printf '%s%s\n' \
  "GNATdoc warnings: $unexpected_warning_count unexpected," \
  " $expected_warning_count known private-generic false positives"
rm -f "$gnatdoc_log" "$normalized_warnings" "$unexpected_warnings"
trap - EXIT HUP INT TERM

node "$project_root/scripts/normalize-gnatdoc-html.mjs" docs/api

mkdir -p docs/api/fonts
cp "$website_kit/assets/fonts/geologica-latin-variable.woff2" docs/api/fonts/
cp website/assets/brand/flyology-mark-transparent.svg docs/api/flyology-mark.svg
cp "$website_kit/assets/scripts/ada-highlight.js" docs/api/ada-highlight.js
node "$website_kit/scripts/build-api-search-index.mjs" docs/api
if grep -q 'FlyologyApiSearch = \[\];' docs/api/search-index.js; then
   node "$project_root/scripts/build-legacy-api-index.mjs" docs/api
fi

test -f docs/api/index.html
test -f docs/api/search-index.js
