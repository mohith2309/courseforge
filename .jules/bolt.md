## 2025-05-22 - [O(N^2) Course Enrichment Bottleneck]
**Learning:** The backend used `users.find()` inside a `.map()` for public catalog and admin listing endpoints. With 1,000 courses and 5,000 users, this $O(C \times U)$ operation took ~60-140ms on a single request.
**Action:** Use a pre-computed hash map for lookups in enrichment functions to reduce complexity to $O(C + U)$.

## 2025-05-22 - [String Concatenation in readBody]
**Learning:** Using `b += c` for reading request chunks is inefficient and can cause issues with multi-byte characters split across chunks.
**Action:** Use an array of Buffer chunks and `Buffer.concat()` for better memory efficiency and correctness.
