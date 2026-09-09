# Pagination and batching

Walk pages as an `AsyncSequence`; run independent requests together.

## Paginated endpoints

Conform to ``PaginatedEndpoint`` to describe how one page requests the next.

```swift
struct ListRepos: PaginatedEndpoint {
    typealias Item = Repo
    var path: String { "/user/repos" }
    func request(pageAfter cursor: String?) -> some Endpoint { ... }
    func page(from response: PageResponse) -> Page<Repo> { ... }
}
```

Then stream every item, or collect a bounded number:

```swift
for try await repo in client.paginate(ListRepos()) {
    render(repo)
}

let firstThree = try await client.collectAll(ListRepos(), max: 3 * pageSize)
```

The sequence stops when a page reports no next cursor, and cancels cleanly if the consuming
task is cancelled.

## Batching

Run independent requests concurrently and get the results together:

```swift
let (profile, settings, feed) = try await client.batch(
    GetProfile(), GetSettings(), GetFeed()
)
```

Each request still flows through the full pipeline (auth, retry, cache) and the bounded
concurrency queue. A failure in one propagates; the others are cancelled.
