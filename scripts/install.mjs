import { createHash } from 'node:crypto';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';

const lockDir = new URL('../.install.lock/', import.meta.url);
const lockInfo = new URL('owner.json', lockDir);
const stampFile = new URL('../node_modules/.meuastral-install-stamp', import.meta.url);
const packageJson = new URL('../package.json', import.meta.url);
const packageLock = new URL('../package-lock.json', import.meta.url);
const staleAfterMs = 10 * 60 * 1000;

async function sleep(ms) {
  await new Promise(resolve => {
    setTimeout(resolve, ms);
  });
}

async function acquireLock() {
  const startedAt = Date.now();

  while (true) {
    try {
      await mkdir(lockDir);
      await writeFile(
        lockInfo,
        JSON.stringify(
          {
            pid: process.pid,
            startedAt: new Date().toISOString()
          },
          null,
          2
        )
      );
      return;
    } catch (error) {
      if (error && error.code !== 'EEXIST') {
        throw error;
      }

      if (Date.now() - startedAt > staleAfterMs) {
        await rm(lockDir, { force: true, recursive: true });
        continue;
      }

      await sleep(250);
    }
  }
}

async function releaseLock() {
  await rm(lockDir, { force: true, recursive: true });
}

async function dependencyHash() {
  const hash = createHash('sha256');
  hash.update(await readFile(packageJson));
  hash.update(await readFile(packageLock));
  return hash.digest('hex');
}

async function isInstalled(expectedHash) {
  try {
    const currentHash = await readFile(stampFile, 'utf8');
    return currentHash.trim() === expectedHash;
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return false;
    }

    throw error;
  }
}

function runNpmCi() {
  const child = spawn(
    'npm',
    ['ci', '--prefer-offline', '--no-audit', '--fund=false'],
    {
      stdio: 'inherit'
    }
  );

  return new Promise((resolve, reject) => {
    child.on('error', reject);
    child.on('exit', (code, signal) => {
      if (signal) {
        reject(new Error(`npm ci exited from signal ${signal}`));
        return;
      }

      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(`npm ci exited with code ${code}`));
    });
  });
}

await acquireLock();

try {
  const expectedHash = await dependencyHash();

  if (!(await isInstalled(expectedHash))) {
    await runNpmCi();
    await writeFile(stampFile, `${expectedHash}\n`);
  }
} finally {
  await releaseLock();
}
