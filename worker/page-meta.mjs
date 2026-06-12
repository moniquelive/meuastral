const SITE_URL = "https://meuastral.com";
const LOGO_URL = `${SITE_URL}/meuastral-marca.png`;
const ADSENSE_PUBLISHER_ID = "ca-pub-7232537493483974";

const PAGE_COPY = {
  "pt-BR": {
    htmlLang: "pt-BR",
    ogLocale: "pt_BR",
    alternateOgLocale: "en_US",
    url: `${SITE_URL}/`,
    title: "MeuAstral.com | Horoscopo diario, biorritmo e mestres ascensionados",
    ogTitle: "MeuAstral: horoscopo, biorritmo e mestres ascensionados",
    description:
      "MeuAstral combina horoscopo diario, biorritmo e mestres ascensionados para consultas gratuitas de autoconhecimento.",
    heading: "MeuAstral: horoscopo, biorritmo e mestres ascensionados",
    intro:
      "O MeuAstral oferece uma consulta gratuita de autoconhecimento com horoscopo diario, calculo de biorritmo e correspondencia com mestres ascensionados a partir da data de nascimento.",
    support:
      "A experiencia interativa carrega no navegador e permite escolher uma data para ver signo, dias de vida, ciclos fisico, emocional e intelectual, alem do raio espiritual associado.",
    navLabel: "Paginas do MeuAstral",
    about: "Sobre o MeuAstral",
    privacy: "Politica de privacidade",
    terms: "Termos de uso",
    financing: "Como o MeuAstral se financia",
    noscript:
      "O MeuAstral funciona melhor com JavaScript ativado. Mesmo assim, voce pode acessar as paginas institucionais e voltar depois para consultar horoscopo, biorritmo e mestres ascensionados.",
  },
  "en-US": {
    htmlLang: "en-US",
    ogLocale: "en_US",
    alternateOgLocale: "pt_BR",
    url: `${SITE_URL}/en/`,
    title: "MeuAstral.com | Daily horoscope, biorhythm, and ascended masters",
    ogTitle: "MeuAstral: daily horoscope, biorhythm, and ascended masters",
    description:
      "MeuAstral combines daily horoscope, biorhythm cycles, and ascended master insights for free self-knowledge readings.",
    heading: "MeuAstral: daily horoscope, biorhythm, and ascended masters",
    intro:
      "MeuAstral offers a free self-knowledge reading with a daily horoscope, biorhythm calculation, and ascended master correspondence based on your birth date.",
    support:
      "The interactive experience loads in your browser and lets you choose a date to see your zodiac sign, days of life, physical, emotional, and intellectual cycles, and associated spiritual ray.",
    navLabel: "MeuAstral pages",
    about: "About MeuAstral",
    privacy: "Privacy policy",
    terms: "Terms of use",
    financing: "How MeuAstral is funded",
    noscript:
      "MeuAstral works best with JavaScript enabled. You can still access the institutional pages and return later to check the horoscope, biorhythm, and ascended masters.",
  },
};

export function localeForPath(pathname) {
  if (pathname === "/en/" || pathname === "/en/index.html") {
    return "en-US";
  }

  if (pathname === "/" || pathname === "/index.html") {
    return "pt-BR";
  }

  return null;
}

export function redirectPathForHomeLocale(request, locale) {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return null;
  }

  const url = new URL(request.url);

  if (url.pathname !== "/" && url.pathname !== "/index.html") {
    return null;
  }

  return locale === "en-US" ? "/en/" : null;
}

export function shouldServeAppShellFallback(request) {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return false;
  }

  const url = new URL(request.url);
  const isAssetRequest =
    url.pathname.includes(".") && !url.pathname.endsWith(".html");

  return !isAssetRequest;
}

export function injectPageMetadata(html, locale) {
  const copy = PAGE_COPY[locale] ?? PAGE_COPY["pt-BR"];

  return html
    .replace(/<html([^>]*)\slang="[^"]*"/i, `<html$1 lang="${copy.htmlLang}"`)
    .replace(
      /<noscript>[\s\S]*?<\/noscript>/i,
      `<noscript>\n    ${copy.noscript}\n  </noscript>`,
    )
    .replace(/<title>[\s\S]*?<\/title>/i, `<title>${copy.title}</title>`)
    .replace(
      /<meta\s+name="description"[\s\S]*?>/i,
      `<meta name="description" content="${copy.description}" />`,
    )
    .replace(
      /<meta\s+name="google-adsense-account"[\s\S]*?>/i,
      `<meta name="google-adsense-account" content="${ADSENSE_PUBLISHER_ID}" />`,
    )
    .replace(
      /<link\s+rel="canonical"[\s\S]*?>/i,
      canonicalAndAlternates(copy.url),
    )
    .replace(/<meta\s+property="og:title"[\s\S]*?>/i, ogTag("title", copy.ogTitle))
    .replace(/<meta\s+property="og:url"[\s\S]*?>/i, ogTag("url", copy.url))
    .replace(/<meta\s+property="og:image"[\s\S]*?>/i, ogTag("image", LOGO_URL))
    .replace(
      /<meta\s+property="og:description"[\s\S]*?>/i,
      ogTag("description", copy.description),
    )
    .replace(
      /<meta\s+property="fb:admins"[\s\S]*?>/i,
      `${socialLocaleTags(copy)}\n  ${twitterTags(copy)}\n  <meta property="fb:admins" content="506596308" />`,
    )
    .replace(
      /<script\s+type="application\/ld\+json">[\s\S]*?<\/script>/i,
      jsonLd(copy),
    )
    .replace(
      /<div id="root">[\s\S]*?<\/div>\s*(?=<script src="\/elm\.js")/i,
      fallbackRoot(copy),
    )
    .replace("</head>", `  ${localeScript(copy.htmlLang)}\n</head>`);
}

export async function responseWithPageMetadata(response, locale) {
  const html = await response.text();
  const headers = new Headers(response.headers);

  headers.set("content-type", "text/html; charset=utf-8");

  return new Response(injectPageMetadata(html, locale), {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function canonicalAndAlternates(canonicalUrl) {
  return [
    `<link rel="canonical" href="${canonicalUrl}" />`,
    `<link rel="alternate" hreflang="pt-BR" href="${SITE_URL}/" />`,
    `<link rel="alternate" hreflang="en-US" href="${SITE_URL}/en/" />`,
    `<link rel="alternate" hreflang="x-default" href="${SITE_URL}/" />`,
  ].join("\n  ");
}

function ogTag(property, content) {
  return `<meta property="og:${property}" content="${content}" />`;
}

function socialLocaleTags(copy) {
  return [
    `<meta property="og:locale" content="${copy.ogLocale}" />`,
    `<meta property="og:locale:alternate" content="${copy.alternateOgLocale}" />`,
  ].join("\n  ");
}

function twitterTags(copy) {
  return [
    `<meta name="twitter:card" content="summary_large_image" />`,
    `<meta name="twitter:title" content="${copy.ogTitle}" />`,
    `<meta name="twitter:description" content="${copy.description}" />`,
    `<meta name="twitter:image" content="${LOGO_URL}" />`,
  ].join("\n  ");
}

function jsonLd(copy) {
  return `<script type="application/ld+json">\n${JSON.stringify(
    {
      "@context": "https://schema.org",
      "@graph": [
        {
          "@type": "Organization",
          "@id": `${SITE_URL}/#organization`,
          name: "MeuAstral",
          url: `${SITE_URL}/`,
          logo: LOGO_URL,
          sameAs: [
            "https://www.facebook.com/meuastral/",
            "https://twitter.com/MeuAstral_Com",
          ],
        },
        {
          "@type": "WebSite",
          "@id": `${SITE_URL}/#website`,
          name: "MeuAstral",
          url: copy.url,
          description: copy.description,
          publisher: {
            "@id": `${SITE_URL}/#organization`,
          },
          inLanguage: copy.htmlLang,
        },
      ],
    },
    null,
    2,
  )}\n  </script>`;
}

function fallbackRoot(copy) {
  return `<div id="root">
    <main>
      <header>
        <img src="/logo.png" alt="MeuAstral" width="220" height="112" />
        <h1>${copy.heading}</h1>
      </header>
      <p>
        ${copy.intro}
      </p>
      <p>
        ${copy.support}
      </p>
      <nav aria-label="${copy.navLabel}">
        <a href="/sobre/">${copy.about}</a>
        <a href="/politica-de-privacidade/">${copy.privacy}</a>
        <a href="/termos-de-uso/">${copy.terms}</a>
        <a href="/como-o-meuastral-se-financia/">${copy.financing}</a>
      </nav>
    </main>
  </div>

  `;
}

function localeScript(locale) {
  return `<script>window.__MEUASTRAL_LOCALE__ = ${JSON.stringify(locale)};</script>`;
}
