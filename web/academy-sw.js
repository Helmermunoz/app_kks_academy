// Bump this comment for shell updates. Never cache private data or serve stale assets.
// v1: installation support requires connectivity; offline functionality is intentional absent.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  // Cache Storage is shared by origin; never delete another application's caches.
  await self.clients.claim();
})()));
self.addEventListener('fetch', event => {
  // Do not intercept cross-origin Supabase, video, image or OpenAI traffic.
  if (event.request.method === 'GET' && new URL(event.request.url).origin === self.location.origin) {
    event.respondWith(fetch(event.request, {cache: 'no-cache'}));
  }
});
