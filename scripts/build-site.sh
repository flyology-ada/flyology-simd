#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
site="$project_root/build/site"
kit="$project_root/vendor/website-kit"

test -f "$kit/scripts/install-assets.mjs" || {
   printf '%s\n' \
     "website-kit submodule is missing; run git submodule update --init" >&2
   exit 1
}

case "$site" in
   "$project_root"/build/site) ;;
   *) printf '%s\n' "refusing unexpected site path: $site" >&2; exit 1 ;;
esac

"$project_root/scripts/docs.sh"
rm -rf "$site"
mkdir -p "$project_root/build"
cp -R "$project_root/website" "$site"
node "$kit/scripts/install-assets.mjs" "$site"
mkdir -p "$site/api"
cp -R "$project_root/docs/api/." "$site/api/"
node "$project_root/scripts/resolve-api-links.mjs" "$site"
touch "$site/.nojekyll"
node "$kit/scripts/check-site.mjs" "$site"

test -f "$site/index.html"
test "$(cat "$site/CNAME")" = "simd.flyology.org"
test -f "$site/llms.txt"
test -f "$site/guide/index.html"
test -f "$site/guide/practical/index.html"
test -f "$site/guide/masks/index.html"
test -f "$site/guide/memory/index.html"
test -f "$site/guide/conversions/index.html"
test -f "$site/guide/dispatch/index.html"
test -f "$site/guide/benchmarking/index.html"
test -f "$site/architecture/index.html"
test -f "$site/support/index.html"
test -f "$site/api/index.html"

printf '%s\n' "site built at $site"
