// Tiny server for the minirack planner: serves ./public and reads/writes rack.json.
// Run with: bun tools/minirack/server.ts
import { existsSync, readFileSync, renameSync, statSync } from "node:fs";
import { join, normalize, sep } from "node:path";

const publicDir = join(import.meta.dir, "public");
const statePath = process.env.MINIRACK_STATE ?? join(import.meta.dir, "rack.json");
const port = Number(process.env.PORT ?? 4545);
const hostname = process.env.HOST ?? "127.0.0.1";

// The file's mtime doubles as a revision, so a stale tab can't clobber a
// rack.json that changed underneath it (git pull, checkout, another tab).
const revision = () => (existsSync(statePath) ? String(statSync(statePath).mtimeMs) : "0");

async function handleState(req: Request): Promise<Response> {
  if (req.method === "GET") {
    const body = existsSync(statePath) ? readFileSync(statePath, "utf8") : "null";
    return new Response(body, {
      headers: { "content-type": "application/json", "cache-control": "no-store", "x-revision": revision() },
    });
  }

  if (req.method === "PUT") {
    const base = req.headers.get("x-base-revision");
    if (base !== null && base !== revision()) {
      return Response.json({ error: "rack.json changed on disk" }, { status: 409 });
    }

    let data: unknown;
    try {
      data = await req.json();
    } catch {
      return Response.json({ error: "body is not JSON" }, { status: 400 });
    }
    if (!data || typeof data !== "object" || !Array.isArray((data as { layouts?: unknown }).layouts)) {
      return Response.json({ error: "expected an object with a layouts array" }, { status: 400 });
    }

    const tmp = `${statePath}.tmp`;
    await Bun.write(tmp, `${JSON.stringify(data, null, 2)}\n`);
    renameSync(tmp, statePath);
    return Response.json({ revision: revision() });
  }

  return new Response("method not allowed", { status: 405 });
}

async function handleStatic(pathname: string): Promise<Response> {
  const filePath = normalize(join(publicDir, pathname === "/" ? "index.html" : pathname));
  if (!filePath.startsWith(publicDir + sep)) return new Response("not found", { status: 404 });
  const file = Bun.file(filePath);
  if (!(await file.exists())) return new Response("not found", { status: 404 });
  return new Response(file, { headers: { "cache-control": "no-store" } });
}

Bun.serve({
  port,
  hostname,
  fetch(req) {
    const { pathname } = new URL(req.url);
    return pathname === "/api/state" ? handleState(req) : handleStatic(pathname);
  },
});

console.log(`✿ minirack planner is up → http://${hostname}:${port}`);
console.log(`  saving to ${statePath}`);
