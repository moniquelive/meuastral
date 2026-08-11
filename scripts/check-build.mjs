import { readdir, readFile } from 'node:fs/promises';
import { dirname, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const currentFile = fileURLToPath(import.meta.url);
const rootDir = resolve(dirname(currentFile), '..');
const buildDir = resolve(rootDir, 'build');
const siteOrigin = 'https://meuastral.com';
const files = await collectFiles(buildDir);
const fileSet = new Set(files);
const htmlFiles = files.filter(filePath => filePath.endsWith('.html'));
const errors = [];
const canonicalUrls = new Set();

for (const filePath of htmlFiles) {
  const html = await readFile(filePath, 'utf8');
  const pagePath = pagePathForFile(filePath);
  const pageLabel = relative(rootDir, filePath).split(sep).join('/');

  if (!/<html\b[^>]*\blang=(?:"[^"]+"|'[^']+'|[^\s>]+)/i.test(html)) {
    errors.push(`${pageLabel}: missing html lang attribute`);
  }

  if (/user-scalable\s*=\s*no|maximum-scale\s*=\s*1/i.test(html)) {
    errors.push(`${pageLabel}: viewport prevents browser zoom`);
  }

  for (const duplicateId of duplicateHtmlIds(html)) {
    errors.push(`${pageLabel}: duplicate id "${duplicateId}"`);
  }

  const canonical = linkHref(html, 'canonical');
  if (!canonical) {
    errors.push(`${pageLabel}: missing canonical link`);
  } else {
    canonicalUrls.add(canonical);
  }

  for (const reference of htmlReferences(html)) {
    const target = localBuildTarget(reference, pagePath);

    if (target && !fileSet.has(target)) {
      errors.push(`${pageLabel}: missing local target ${reference}`);
    }
  }
}

const unexpectedPngSources = files
  .map(filePath => relative(buildDir, filePath).split(sep).join('/'))
  .filter(fileName => /^\d+-.*\.png$/i.test(fileName));

for (const fileName of unexpectedPngSources) {
  errors.push(`build/${fileName}: redundant PNG source copied beside its WebP asset`);
}

const sitemapPath = resolve(buildDir, 'sitemap.xml');
const sitemap = await readFile(sitemapPath, 'utf8');
const sitemapUrls = new Set(
  [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map(match => decodeXml(match[1])),
);

for (const canonical of canonicalUrls) {
  if (!sitemapUrls.has(canonical)) {
    errors.push(`build/sitemap.xml: missing canonical URL ${canonical}`);
  }
}

for (const sitemapUrl of sitemapUrls) {
  if (!canonicalUrls.has(sitemapUrl)) {
    errors.push(`build/sitemap.xml: URL has no canonical page ${sitemapUrl}`);
  }
}

const sourceHeaders = await readFile(resolve(rootDir, 'public', '_headers'), 'utf8');
const builtHeaders = await readFile(resolve(buildDir, '_headers'), 'utf8');

if (builtHeaders !== sourceHeaders) {
  errors.push('build/_headers: does not match the source static-asset cache policy');
}

if (errors.length > 0) {
  console.error(errors.join('\n'));
  process.exitCode = 1;
} else {
  console.log(`Checked ${htmlFiles.length} HTML files, ${sitemapUrls.size} sitemap URLs, and all local references.`);
}

async function collectFiles(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const nested = await Promise.all(entries.map(entry => {
    const entryPath = resolve(dir, entry.name);
    return entry.isDirectory() ? collectFiles(entryPath) : [entryPath];
  }));

  return nested.flat();
}

function pagePathForFile(filePath) {
  const fileName = relative(buildDir, filePath).split(sep).join('/');

  if (fileName === 'index.html') {
    return '/';
  }

  return `/${fileName.replace(/index\.html$/, '')}`;
}

function duplicateHtmlIds(html) {
  const counts = new Map();

  for (const match of html.matchAll(/\bid=(?:"([^"]+)"|'([^']+)'|([^\s>]+))/gi)) {
    const id = match[1] ?? match[2] ?? match[3];
    counts.set(id, (counts.get(id) ?? 0) + 1);
  }

  return [...counts.entries()]
    .filter(([, count]) => count > 1)
    .map(([id]) => id);
}

function linkHref(html, relation) {
  const tags = [...html.matchAll(/<link\b[^>]*>/gi)].map(match => match[0]);
  const tag = tags.find(candidate => htmlAttribute(candidate, 'rel') === relation);
  return tag ? htmlAttribute(tag, 'href') : '';
}

function htmlReferences(html) {
  const tags = [...html.matchAll(/<[a-z][^>]*>/gi)].map(match => match[0]);

  return tags.flatMap(tag => {
    return [...tag.matchAll(/\b(?:href|src)=(?:"([^"]*)"|'([^']*)'|([^\s>]+))/gi)]
      .map(match => match[1] ?? match[2] ?? match[3])
      .filter(Boolean);
  });
}

function localBuildTarget(reference, pagePath) {
  if (
    reference.startsWith('#') ||
    reference.startsWith('data:') ||
    reference.startsWith('mailto:') ||
    reference.startsWith('tel:')
  ) {
    return null;
  }

  const url = new URL(reference.replaceAll('&amp;', '&'), new URL(pagePath, siteOrigin));

  if (url.origin !== siteOrigin || url.pathname.startsWith('/api/')) {
    return null;
  }

  let targetPath = decodeURIComponent(url.pathname);
  if (targetPath.endsWith('/')) {
    targetPath += 'index.html';
  }

  return resolve(buildDir, `.${targetPath}`);
}

function htmlAttribute(tag, name) {
  const pattern = new RegExp(`\\b${name}=(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`, 'i');
  const match = tag.match(pattern);
  return match ? match[1] ?? match[2] ?? match[3] : '';
}

function decodeXml(value) {
  return value
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');
}
