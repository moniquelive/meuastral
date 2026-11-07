import { spawn } from "node:child_process";

const env = {
  ...process.env,
  ELM_HOME: ".elm-home",
  MEUASTRAL_LOCAL_DEV: "1",
};
const child = spawn("npx", ["wrangler", "dev"], {
  env,
  shell: false,
  stdio: "inherit",
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    child.kill(signal);
  });
}

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 0);
});

child.on("error", (error) => {
  console.error(error);
  process.exit(1);
});
