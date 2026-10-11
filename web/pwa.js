// A network-only worker: no athlete data, tokens, videos or API responses in Cache Storage.
if ('serviceWorker' in navigator && window.isSecureContext) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register(new URL('academy-sw.js', document.baseURI))
      .then(registration => registration.update())
      .catch(() => { /* Online app remains usable when registration fails. */ });
  });
}
