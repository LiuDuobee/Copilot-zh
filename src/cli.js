import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const root = path.resolve(import.meta.dirname, "..");
const localePath = path.join(root, "locales", "zh-CN.json");
const reportPath = path.join(root, "reports", "missing-translations.json");
const releaseUrl = process.env.COPILOT_RELEASES_URL;

async function readLocale() {
  const contents = await fs.readFile(localePath, "utf8");
  const locale = JSON.parse(contents);
  if (!locale.messages || typeof locale.messages !== "object") {
    throw new Error("locales/zh-CN.json must contain a messages object");
  }
  return locale;
}

function collectStrings(value, output = new Set()) {
  if (typeof value === "string") {
    const text = value.trim();
    if (text.length >= 2 && /[A-Za-z]/.test(text)) output.add(text);
  } else if (Array.isArray(value)) {
    for (const item of value) collectStrings(item, output);
  } else if (value && typeof value === "object") {
    for (const item of Object.values(value)) collectStrings(item, output);
  }
  return output;
}

async function readResource(filePath) {
  const text = await fs.readFile(filePath, "utf8");
  if (path.extname(filePath).toLowerCase() === ".json") {
    try {
      return JSON.parse(text);
    } catch {
      return text;
    }
  }
  return text;
}

async function scan(files) {
  if (files.length === 0) {
    throw new Error("Usage: npm run scan -- <resource-file> [more-files]");
  }

  const locale = await readLocale();
  const translated = new Set(Object.keys(locale.messages));
  const discovered = new Set();
  for (const file of files) {
    const absolute = path.resolve(process.cwd(), file);
    const resource = await readResource(absolute);
    for (const value of collectStrings(resource)) discovered.add(value);
  }

  const missing = [...discovered]
    .filter((message) => !translated.has(message))
    .sort((a, b) => a.localeCompare(b));
  const report = {
    generatedAt: new Date().toISOString(),
    files,
    discovered: discovered.size,
    translated: [...discovered].filter((message) => translated.has(message)).length,
    missing
  };

  await fs.mkdir(path.dirname(reportPath), { recursive: true });
  await fs.writeFile(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(`Discovered ${report.discovered} strings; ${missing.length} need translation.`);
  console.log(`Report: ${path.relative(root, reportPath)}`);
}

async function check() {
  const locale = await readLocale();
  const messages = Object.entries(locale.messages);
  const invalid = messages.filter(([key, value]) => !key.trim() || !value.trim());
  if (invalid.length > 0) {
    throw new Error(`Found ${invalid.length} empty translation entries.`);
  }
  console.log(`Validated ${messages.length} zh-CN translation entries.`);
}

async function update() {
  if (!releaseUrl) {
    throw new Error(
      "COPILOT_RELEASES_URL is not configured. Set it to the official or trusted release metadata endpoint."
    );
  }
  const response = await fetch(releaseUrl, {
    headers: {
      Accept: "application/vnd.github+json",
      "User-Agent": "copilot-zh-updater"
    }
  });
  if (!response.ok) {
    throw new Error(`GitHub Releases request failed: ${response.status} ${response.statusText}`);
  }
  const release = await response.json();
  const locale = await readLocale();
  const current = locale.meta.upstreamVersion;
  const latest = release.tag_name || release.name;
  if (!latest) throw new Error("Latest release did not contain a version.");
  if (current === latest) {
    console.log(`Already tracking ${latest}.`);
    return;
  }
  locale.meta.upstreamVersion = latest;
  locale.meta.upstreamReleaseUrl = release.html_url;
  locale.meta.updatedAt = new Date().toISOString().slice(0, 10);
  await fs.writeFile(localePath, `${JSON.stringify(locale, null, 2)}\n`);
  console.log(`Updated upstream version: ${current} -> ${latest}`);
}

const [command, ...args] = process.argv.slice(2);
try {
  if (command === "check") await check();
  else if (command === "scan") await scan(args);
  else if (command === "update") await update();
  else throw new Error("Usage: npm run <check|scan|update>");
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
}
