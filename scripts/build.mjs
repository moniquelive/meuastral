import { spawn } from 'node:child_process';
import { cp, copyFile, mkdir, rm } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const currentFile = fileURLToPath(import.meta.url);
const rootDir = resolve(dirname(currentFile), '..');
const buildDir = resolve(rootDir, 'build');

await rm(buildDir, { recursive: true, force: true });
await mkdir(buildDir, { recursive: true });

await cp(resolve(rootDir, 'public'), buildDir, { recursive: true });

await Promise.all([
  copyFile(resolve(rootDir, 'index.html'), resolve(buildDir, 'index.html')),
  copyFile(resolve(rootDir, 'src', 'main.css'), resolve(buildDir, 'main.css')),
  copyFile(resolve(rootDir, 'src', 'datepicker.css'), resolve(buildDir, 'datepicker.css')),
  copyFile(resolve(rootDir, 'src', 'zodiac.css'), resolve(buildDir, 'zodiac.css')),
  copyFile(resolve(rootDir, 'src', 'bootstrap.js'), resolve(buildDir, 'bootstrap.js'))
]);

await runElmMake(rootDir, buildDir);

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
