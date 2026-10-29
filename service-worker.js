"use strict";

const CACHE_NAME = "classmate-shell-v2";
const APP_PATH = "Smart%20Attendance%20and%20Shortage%20Predictor.html";
const ASSETS = [
  `./${APP_PATH}`,
  "./manifest.webmanifest",
  "./icon.svg"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys
        .filter((key) => key.startsWith("classmate-shell-") && key !== CACHE_NAME)
        .map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET" || new URL(event.request.url).origin !== self.location.origin) return;
  event.respondWith(
    caches.match(event.request, { ignoreSearch: true })
      .then((cached) => cached || fetch(event.request).then((response) => {
        if (response.ok && new URL(event.request.url).origin === self.location.origin) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        }
        return response;
      }))
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const action = event.action;
  const details = event.notification.data || {};
  const target = new URL(`./${APP_PATH}`, self.registration.scope);
  if (details.date) target.searchParams.set("date", details.date);
  if (details.id) target.searchParams.set("id", details.id);
  if (Number.isInteger(details.slot)) target.searchParams.set("slot", String(details.slot));
  if (details.subject) target.searchParams.set("subject", details.subject);
  if (action) target.searchParams.set("classAction", action);

  event.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clients) => {
    const client = clients.find((item) => item.url.startsWith(self.registration.scope));
    if (client && action) {
      client.postMessage({
        type: "class-action",
        id: details.id,
        date: details.date,
        slot: details.slot,
        subject: details.subject,
        action
      });
      return client.focus();
    }
    if (client) return client.navigate(target.href).then((page) => page && page.focus());
    return self.clients.openWindow(target.href);
  }));
});
