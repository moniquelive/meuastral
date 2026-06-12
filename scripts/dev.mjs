import { spawn } from "node:child_process";
import { chmod, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const env = { ...process.env, ELM_HOME: ".elm-home" };
const args = ["wrangler", "dev"];
let envFile;

if (env.API_NINJAS_KEY) {
  envFile = join(
    tmpdir(),
    `meuastral-wrangler-${Date.now()}-${Math.random().toString(16).slice(2)}.env`,
  );

  await writeFile(envFile, `API_NINJAS_KEY=${env.API_NINJAS_KEY}\n`, {
    mode: 0o600,
  });
  await chmod(envFile, 0o600);
  args.push("--env-file", envFile);
}

const child = spawn("npx", args, {
  env,
  shell: false,
  stdio: "inherit",
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    child.kill(signal);
  });
}

child.on("exit", async (code, signal) => {
  if (envFile) {
    await rm(envFile, { force: true });
  }

  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 0);
});

child.on("error", async (error) => {
  if (envFile) {
    await rm(envFile, { force: true });
  }

  console.error(error);
  process.exit(1);
});
