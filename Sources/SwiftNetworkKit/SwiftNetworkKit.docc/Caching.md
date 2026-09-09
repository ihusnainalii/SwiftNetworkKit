# Caching

Policy-driven HTTP response caching over a pluggable two-tier store.

## Overview

Caching is off by default. Enable it by giving ``NetworkConfiguration`` a
``CacheConfiguration`` with a ``ResponseCache`` store and a default ``CachePolicy``.

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.cache = CacheConfiguration(
    store: MemoryCacheStore(limitBytes: 20 * 1024 * 1024),
    defaultPolicy: .networkFirst,
    defaultTTL: 300
)
```

## Policies

| ``CachePolicy`` | Behaviour |
|---|---|
| `.ignoreCache` | never read or write the cache |
| `.networkOnly` | always fetch; still writes the response |
| `.networkFirst` | fetch; fall back to a fresh cache entry on failure |
| `.cacheFirst` | serve a fresh entry without a request; fetch only on miss |
| `.cacheOnly` | serve from cache or throw ``NetworkError/noInternet`` |
| `.staleWhileRevalidate` | serve the cached entry now, refresh in the background |

Set a per-endpoint override with `var cachePolicy: CachePolicy? { .cacheFirst }`.

## Stores

| Store | Notes |
|---|---|
| ``MemoryCacheStore`` | actor, LRU eviction by byte budget |
| ``DiskCacheStore`` | actor, files written with `.completeFileProtectionUnlessOpen` |
| your own | conform to ``ResponseCache`` |

Compose both by wrapping them in a type that checks memory, then disk, then the network.

## Freshness and revalidation

``CachedResponse`` records `storedAt`, `maxAge` (from `Cache-Control`), and `etag`. Entries
are considered fresh for `maxAge ?? defaultTTL`. `Cache-Control: no-store` responses are
never persisted. A `304 Not Modified` reply refreshes the stored entry's timestamp.

## Cache identity

The cache key is derived from method, URL, and whether the request was authenticated, so an
authenticated response is not served to an unauthenticated caller on the same client.
