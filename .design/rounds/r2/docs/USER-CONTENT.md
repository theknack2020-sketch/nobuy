# User content placement — N/A, and why
The data model carries NO media fields: no photos, no avatars, no attachments. Waiting-list items are {name: text, amount: optional user-typed text, heldUntil: date}; checklist questions are text; day answers are enums with an optional text note. Therefore:
- No seam rule, global filter, or minimum source size is needed — there is nothing to place.
- Every media-capable field the schema might have implied is hereby declared non-existent (product-completeness 11b): if a future round adds photos to waiting items, that round owes this document for real.
- The only "user content" is text; its rules: verbatim rendering, no auto-capitalisation of notes, truncation at 2 lines with full text in the day/item detail, and the amount is never summed, converted or charted — the app does not do money arithmetic (product truth 4).
