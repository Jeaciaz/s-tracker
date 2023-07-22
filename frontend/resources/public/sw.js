self.addEventListener('install', event => {
	event.waitUntil(caches.open('pwa-assets-v1').then(cache => {
		return cache.addAll(['index.html', 'offline.html', 'css/offline.css', 'manifest.json'])
	}))
})

self.addEventListener('activate', event => {
	console.log('worker activated')
})

self.addEventListener('fetch', event => {
	if (event.request.destination === 'document') {
		event.respondWith(fetch(event.request).catch(() => {
			return caches.match('offline.html')
		}))
	}
	event.respondWith(caches.match(event.request).then(cachedResponse => {
		return cachedResponse || fetch(event.request)
	}))
})
