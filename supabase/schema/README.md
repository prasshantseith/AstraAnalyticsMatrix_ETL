# supabase/schema

Read-only mirror of current schema objects, organized as `<schema>/<tables|views|procedures>/<object>.sql`,
for browsing what exists without reading through migration history.

This folder is **not** applied to any database and is not a source of truth. `supabase/migrations/`
is the source of truth for every schema and data change — when a migration creates, alters, or drops
an object, update the matching file here by hand (add/edit/delete it) in the same PR.

Objects that already existed in the database before this repo's migrations started (e.g. `MF.MF_NAV`)
won't have a file here until a migration formally captures their definition, to avoid documenting a
guessed definition as if it were authoritative.
