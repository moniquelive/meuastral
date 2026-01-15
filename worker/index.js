export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);

    if (response.status !== 404) {
      return response;
    }

    return handleSpaFallback(request, env);
  },
};

function handleSpaFallback(request, env) {
  const url = new URL(request.url);
  const isAssetRequest =
    url.pathname.includes(".") && !url.pathname.endsWith(".html");

  if (!isAssetRequest && request.method === "GET") {
    const indexUrl = new URL("/index.html", url.origin);
    return env.ASSETS.fetch(
      new Request(indexUrl.toString(), {
        headers: request.headers,
        method: "GET",
      }),
    );
  }

  return new Response("Not Found", { status: 404 });
}
