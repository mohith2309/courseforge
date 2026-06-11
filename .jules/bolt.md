## Performance Optimizations

* Replacing synchronous file I/O operations (`fs.mkdirSync`, `fs.writeFileSync`) with asynchronous equivalents (`fs.promises.mkdir`, `fs.promises.writeFile`) in heavily used paths like `server/server.js`'s `save` function improves concurrent request handling.
* In benchmarks writing a 50MB JSON payload, the asynchronous file writes reduced the max event loop delay from ~90ms to ~0ms. This ensures that the node server doesn't block other requests while saving large items or user datasets to disk.
