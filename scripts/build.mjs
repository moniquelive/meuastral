import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFile, mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const currentFile = fileURLToPath(import.meta.url);
const rootDir = resolve(dirname(currentFile), '..');
const buildDir = resolve(rootDir, 'build');
const publicDir = resolve(rootDir, 'public');

await rm(buildDir, { recursive: true, force: true });
await mkdir(buildDir, { recursive: true });

await runHugo(rootDir, buildDir);
await writeSitemap(buildDir);
await runTailwind(rootDir, buildDir);
await writeCssBundle(rootDir, buildDir);
await copyPublicAssets(publicDir, buildDir);
await copyBootstrap(rootDir, buildDir);
await runElmMake(rootDir, buildDir);
await minifyJavaScript(rootDir, buildDir, 'elm.js');
await fingerprintBuildAssets(buildDir);

function runHugo(root, outDir) {
  return new Promise((resolvePromise, rejectPromise) => {
    const command = spawn('hugo', [
      '--gc',
      '--minify',
      '--destination',
      outDir
    ], {
      cwd: root,
      env: process.env,
      stdio: 'inherit'
    });

    command.on('error', rejectPromise);

    command.on('exit', code => {
      if (code === 0) {
        resolvePromise();
        return;
      }

      rejectPromise(new Error(`hugo failed with exit code ${code}`));
    });
  });
}

function runTailwind(root, outDir) {
  return new Promise((resolvePromise, rejectPromise) => {
    const command = spawn('tailwindcss', [
      '--config',
      resolve(root, 'tailwind.config.cjs'),
      '--input',
      resolve(root, 'src', 'tailwind.css'),
      '--output',
      resolve(outDir, 'app.tailwind.css'),
      '--minify'
    ], {
      cwd: root,
      env: process.env,
      stdio: 'inherit'
    });

    command.on('error', rejectPromise);

    command.on('exit', code => {
      if (code === 0) {
        resolvePromise();
        return;
      }

      rejectPromise(new Error(`tailwindcss failed with exit code ${code}`));
    });
  });
}

async function writeCssBundle(root, outDir) {
  const cssSources = [
    resolve(outDir, 'app.tailwind.css'),
    resolve(root, 'themes', 'meuastral', 'static', 'site.css'),
    resolve(root, 'src', 'main.css'),
    resolve(root, 'src', 'datepicker.css'),
    resolve(root, 'src', 'zodiac.css')
  ];

  const bundle = await Promise.all(cssSources.map(async source => {
    const css = await readFile(source, 'utf8');
    return `/* ${relative(root, source).split(sep).join('/')} */\n${css.trim()}\n`;
  }));

  await writeFile(resolve(outDir, 'app.css'), bundle.join('\n'));
  await Promise.all([
    rm(resolve(outDir, 'app.tailwind.css'), { force: true }),
    rm(resolve(outDir, 'site.css'), { force: true })
  ]);
}

async function copyPublicAssets(sourceDir, outDir) {
  const entries = await readdir(sourceDir, { withFileTypes: true });

  await Promise.all(entries.map(async entry => {
    if (entry.isDirectory()) {
      return;
    }

    if (!shouldCopyPublicAsset(entry.name)) {
      return;
    }

    await copyFile(resolve(sourceDir, entry.name), resolve(outDir, entry.name));
  }));
}

function shouldCopyPublicAsset(fileName) {
  if (fileName === 'ads.txt' || fileName === 'CNAME') {
    return true;
  }

  return [
    '.ico',
    '.png',
    '.webp',
    '.json'
  ].some(ext => fileName.endsWith(ext));
}

async function copyBootstrap(root, outDir) {
  await copyFile(resolve(root, 'src', 'bootstrap.js'), resolve(outDir, 'bootstrap.js'));
}

async function writeSitemap(outDir) {
  const htmlPaths = await collectIndexHtmlFiles(outDir);
  const urlPaths = htmlPaths
    .map(filePath => urlPathFromIndexFile(outDir, filePath))
    .filter(path => path !== null)
    .sort((left, right) => left.localeCompare(right));

  const lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">'
  ];

  for (const urlPath of urlPaths) {
    lines.push('  <url>');
    lines.push(`    <loc>${xmlEscape(absoluteUrl(urlPath))}</loc>`);

    for (const alternate of alternatesForPath(urlPath)) {
      lines.push(
        `    <xhtml:link rel="alternate" hreflang="${alternate.lang}" href="${xmlEscape(absoluteUrl(alternate.path))}" />`
      );
    }

    lines.push('  </url>');
  }

  lines.push('</urlset>');
  lines.push('');

  await writeFile(resolve(outDir, 'sitemap.xml'), lines.join('\n'));
  await rm(resolve(outDir, 'pt-br', 'sitemap.xml'), { force: true });
  await rm(resolve(outDir, 'en', 'sitemap.xml'), { force: true });
}

async function collectIndexHtmlFiles(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const nestedFiles = await Promise.all(entries.map(async entry => {
    const entryPath = resolve(dir, entry.name);

    if (entry.isDirectory()) {
      return collectIndexHtmlFiles(entryPath);
    }

    if (entry.isFile() && entry.name === 'index.html') {
      return [entryPath];
    }

    return [];
  }));

  return nestedFiles.flat();
}

function urlPathFromIndexFile(outDir, filePath) {
  const fileName = relative(outDir, filePath).split(sep).join('/');

  if (fileName === 'pt-br/index.html') {
    return null;
  }

  if (fileName === 'index.html') {
    return '/';
  }

  return `/${fileName.replace(/\/?index\.html$/, '')}/`;
}

function alternatesForPath(urlPath) {
  const pair = translatedPaths().find(paths => {
    return paths.pt === urlPath || paths.en === urlPath;
  });

  if (!pair) {
    return [];
  }

  return [
    { lang: 'pt-BR', path: pair.pt },
    { lang: 'en-US', path: pair.en }
  ];
}

function translatedPaths() {
  return [
    { pt: '/', en: '/en/' },
    { pt: '/sobre/', en: '/en/about/' },
    { pt: '/politica-de-privacidade/', en: '/en/privacy-policy/' },
    { pt: '/termos-de-uso/', en: '/en/terms/' },
    { pt: '/como-o-meuastral-se-financia/', en: '/en/how-meuastral-is-funded/' },
    { pt: '/politica-editorial/', en: '/en/editorial-policy/' },
    { pt: '/metodologia/', en: '/en/methodology/' }
  ];
}

function absoluteUrl(path) {
  return new URL(path, 'https://meuastral.com').toString();
}

function xmlEscape(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

function runElmMake(root, outDir) {
  return new Promise((resolvePromise, rejectPromise) => {
    const command = spawn('elm', [
      'make',
      'src/Main.elm',
      '--optimize',
      `--output=${resolve(outDir, 'elm.js')}`
    ], {
      cwd: root,
      env: process.env,
      stdio: 'inherit'
    });

    command.on('error', rejectPromise);

    command.on('exit', code => {
      if (code === 0) {
        resolvePromise();
        return;
      }

      rejectPromise(new Error(`elm make failed with exit code ${code}`));
    });
  });
}

function minifyJavaScript(root, outDir, fileName) {
  return new Promise((resolvePromise, rejectPromise) => {
    const filePath = resolve(outDir, fileName);
    const command = spawn('terser', [
      filePath,
      '--compress',
      '--mangle',
      '--output',
      filePath
    ], {
      cwd: root,
      env: process.env,
      stdio: 'inherit'
    });

    command.on('error', rejectPromise);

    command.on('exit', code => {
      if (code === 0) {
        resolvePromise();
        return;
      }

      rejectPromise(new Error(`terser failed with exit code ${code}`));
    });
  });
}

async function fingerprintBuildAssets(outDir) {
  const replacements = new Map();

  for (const fileName of ['app.css', 'elm.js', 'bootstrap.js']) {
    const hashedFileName = await fingerprintFile(outDir, fileName);
    replacements.set(`/${fileName}`, `/${hashedFileName}`);
  }

  const htmlFiles = await collectHtmlFiles(outDir);

  await Promise.all(htmlFiles.map(async filePath => {
    let html = await readFile(filePath, 'utf8');

    for (const [from, to] of replacements.entries()) {
      html = html.replaceAll(from, to);
    }

    await writeFile(filePath, html);
  }));
}

async function fingerprintFile(outDir, fileName) {
  const filePath = resolve(outDir, fileName);
  const contents = await readFile(filePath);
  const hash = createHash('sha256').update(contents).digest('hex').slice(0, 10);
  const dotIndex = fileName.lastIndexOf('.');
  const hashedFileName = `${fileName.slice(0, dotIndex)}.${hash}${fileName.slice(dotIndex)}`;

  await writeFile(resolve(outDir, hashedFileName), contents);
  await rm(filePath, { force: true });

  return hashedFileName;
}

async function collectHtmlFiles(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const nestedFiles = await Promise.all(entries.map(async entry => {
    const entryPath = resolve(dir, entry.name);

    if (entry.isDirectory()) {
      return collectHtmlFiles(entryPath);
    }

    if (entry.isFile() && entry.name.endsWith('.html')) {
      return [entryPath];
    }

    return [];
  }));

  return nestedFiles.flat();
}
