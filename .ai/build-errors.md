# E2E Run Failure

Command: ./devtools/run-e2e.sh

Date: 2026-05-10 21:35:20 UTC
Git HEAD: b7ba948

Failure summary:

The E2E wrapper script failed early while attempting to create a temporary log file with mktemp. The script printed the following output (full captured stdout/stderr):

">
=== Versions ===
============================================
= pass: the standard unix password manager =
=                                          =
=                  v1.7.4                  =
=                                          =
=             Jason A. Donenfeld           =
=               Jason@zx2c4.com            =
=                                          =
=      http://www.passwordstore.org/       =
============================================
gpg (GnuPG) 2.5.19
gpgconf (GnuPG) 2.5.19
Copyright (C) 2025 g10 Code GmbH
License GNU GPL-3.0-or-later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Xcode 26.4.1

mktemp: mkstemp failed on /tmp/kizba-e2e-log-XXXXXX.txt: File exists
"

Please inspect /tmp/devtools_run_output.txt for the complete raw output. Likely cause: mktemp reported "mkstemp failed on /tmp/kizba-e2e-log-XXXXXX.txt: File exists" which prevented the script from creating its runtime log and proceeding.

Cleanup attempted: gpgconf --kill all and removal of any /tmp/kizba-e2e-* directories (best-effort) were performed.
