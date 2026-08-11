import { readdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join, relative, resolve, sep } from "node:path";

const projectRoot = resolve(new URL("..", import.meta.url).pathname);
const siteRoot = resolve(process.argv[2] || join(projectRoot, "build/site"));
const indexPath = join(projectRoot, "docs/api/search-index.js");

async function filesBelow(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const results = [];
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) results.push(...await filesBelow(path));
    else results.push(path);
  }
  return results;
}

const raw = await readFile(indexPath, "utf8");
const prefix = "window.FlyologyApiSearch = ";
if (!raw.startsWith(prefix) || !raw.trimEnd().endsWith(";")) {
  throw new Error("unexpected GNATdoc search-index.js format");
}

const entries = JSON.parse(raw.slice(prefix.length).trim().replace(/;$/, ""));
const targets = new Map();
const overloads = new Map();
for (const entry of entries) {
  const candidates = overloads.get(entry.qualifiedName) || [];
  candidates.push(entry);
  overloads.set(entry.qualifiedName, candidates);
  const previous = targets.get(entry.qualifiedName);
  if (!previous || entry.kind === "Compilation unit") {
    targets.set(entry.qualifiedName, entry.href);
  }
}

const pageCache = new Map();
async function declarationFor(entry) {
  if (entry.kind !== "Subprogram" || !entry.href.includes("#")) return "";
  const [pageName, fragment] = entry.href.split("#", 2);
  let page = pageCache.get(pageName);
  if (!page) {
    page = await readFile(join(siteRoot, "api", pageName), "utf8");
    pageCache.set(pageName, page);
  }
  const unquoted = "id=" + fragment;
  const quoted = 'id="' + fragment + '"';
  const start = Math.max(page.indexOf(unquoted), page.indexOf(quoted));
  if (start < 0) return "";
  const codeStart = page.indexOf("<code>", start);
  const codeEnd = page.indexOf("</code>", codeStart);
  if (codeStart < 0 || codeEnd < 0) return "";
  return page.slice(codeStart + 6, codeEnd)
    .replace(/<[^>]+>/g, " ")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&amp;", "&")
    .replace(/\s+/g, " ")
    .trim();
}

const declarations = new Map();
for (const candidates of overloads.values()) {
  for (const entry of candidates) {
    if (entry.kind === "Subprogram") {
      declarations.set(entry.href, await declarationFor(entry));
    }
  }
}

for (const file of (await filesBelow(siteRoot)).filter((path) => path.endsWith(".html"))) {
  let html = await readFile(file, "utf8");
  html = html.replace(/<a\s+data-api="([^"]+)"([^>]*)>/g, (_, name, rest) => {
    const signatureAttribute = rest.match(/\s+data-api-signature="([^"]+)"/);
    const signature = signatureAttribute?.[1];
    let target = targets.get(name);
    if (signature) {
      const matches = (overloads.get(name) || []).filter((entry) =>
        declarations.get(entry.href)?.includes(signature)
      );
      if (matches.length !== 1) {
        throw new Error(
          "expected one GNATdoc overload for " + name +
          " containing " + signature + ", found " + matches.length +
          " in " + file
        );
      }
      target = matches[0].href;
      rest = rest.replace(/\s+data-api-signature="[^"]+"/, "");
    }
    if (!target) throw new Error("unresolved GNATdoc entity " + name + " in " + file);
    let href = relative(dirname(file), join(siteRoot, "api", target));
    href = href.split(sep).join("/");
    return '<a href="' + href + '"' + rest + '>';
  });
  if (html.includes("data-api=")) {
    throw new Error("unresolved data-api attribute in " + file);
  }
  await writeFile(file, html);
}
