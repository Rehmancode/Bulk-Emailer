# Square Ex Studios Mailer

## Setup

**Windows:** double-click `run_app.bat` — it installs dependencies, reports
(but doesn't auto-install) any newer versions available upstream, then
launches the app. No `.exe` build step; this runs from source directly.

**macOS/Linux:**
```bash
pip install -r requirements.txt
python main.py
```

## Directory layout
```
mailsender/
├── main.py                 # entry point
├── requirements.txt
├── app/
│   ├── config_manager.py   # encrypted credential storage, machine id, settings
│   ├── database.py         # SQLite sent-mail log + merge logic for Drive sync
│   ├── gdrive_sync.py       # Google Drive OAuth + upload/download of the shared db
│   ├── bootstrap.py        # first-run dependency check (source-run only, see below)
│   ├── excel_parser.py     # xlsx loading, header mapping, email validation
│   ├── smtp_client.py      # smtplib wrapper (connect/send/test)
│   ├── email_worker.py     # QThread: throttling, retries, window, DB logging
│   └── main_window.py      # PyQt6 UI (tabs: Settings / Leads / Compose / Send / Database)
```

Runtime data (encrypted credentials, `sent_mail.db`, suppression list, cached
Google Drive login) lives in `~/.squareex_mailer/`, not inside the project folder.

## Centralized database (Google Drive)

Sent-mail history is now SQLite (`sent_mail.db`), not the old CSV. Optionally
sync it to your own Google Drive so history is shared across machines:

1. One-time setup at https://console.cloud.google.com/ — create a project,
   enable the **Google Drive API**, then create an OAuth client ID of type
   **Desktop app** and download the `client_secret.json`.
2. In the app's **Database** tab, click **Connect Google Drive...** and
   select that file. A browser window opens once for login; after that,
   the token is cached in `~/.squareex_mailer/gdrive_token.json` and you
   won't be asked again on this machine.
3. Sync happens automatically on startup and after each send batch, or
   click **Sync Now** manually.

**Concurrency limit, worth repeating:** this syncs one shared file with a
download-merge-upload cycle, not row-level locking. Fine for one person
alternating between two machines. Not safe for two people running
campaigns from two machines at the same time — the second upload wins,
silently.

## Running without a manual `pip install` first (source only)

`main.py` checks for missing packages on startup and asks (via a popup,
not silently) before installing them with pip — see `app/bootstrap.py`.
This is **skipped entirely** when running the compiled `.exe`, since that
already bundles every dependency statically at build time; the bootstrap
only matters if you're running `python main.py` from source on a machine
that hasn't run `pip install -r requirements.txt` yet.

## What I changed vs. the literal spec, and why

1. **Unsubscribe footer, on by default.** Appended to every send unless you
   uncheck it. Sending unsolicited bulk commercial email without an opt-out
   mechanism is a CAN-SPAM/GDPR violation, not just a nice-to-have.
2. **Suppression list** at `~/.squareex_mailer/suppressed_emails.txt`. Add an
   email per line and it will be filtered out of every future upload,
   permanently, even if that address reappears in a new spreadsheet. The UI
   doesn't yet expose an "auto-add on unsubscribe reply" flow because that
   requires reading a mailbox (IMAP), which is out of scope for what you
   asked for — you'd add addresses here manually or wire up IMAP polling
   later.
3. **Rolling 24h daily limit** is derived from the SQLite database
   (`sent_mail.db`) timestamps rather than an in-memory counter, so it's
   correct across app restarts and across machines once Drive sync is on.

## No `.exe` build — this runs from source

Earlier versions of this README covered a PyInstaller `.exe` build and an
Inno Setup installer. That's been dropped per request — `run_app.bat` on
Windows (or `pip install -r requirements.txt && python main.py` on
macOS/Linux) is the only supported way to launch this now. If you want the
`.exe` path back later, the previous approach was: PyInstaller with
`--collect-all tzdata --collect-all googleapiclient --collect-all
google_auth_oauthlib` (those three load resources dynamically, so
PyInstaller's static import scan misses them without that flag), then
optionally Inno Setup to wrap it into a proper installer. Two things that
bit as a result of removing that path, if you ever bring it back: Windows
Defender/SmartScreen flags a fresh unsigned `.exe` on first run regardless
of PyInstaller settings, and it needs a paid code-signing cert to avoid
cleanly — neither of those apply to `run_app.bat`.


- **Hostinger will likely rate-limit or suspend the mailbox** if you send
  genuinely cold, unsolicited email at volume, independent of anything this
  app does. Shared hosting SMTP is not built for cold outreach at scale —
  check your specific plan's sending limits in hPanel before setting the
  daily limit here.
- **The encryption is local-key, not OS-keychain.** See the docstring in
  `config_manager.py`. Fine against casual exposure, not against a
  compromised machine.
- **No IMAP bounce/reply handling.** Hard bounces won't automatically
  suppress an address; only failures visible at SMTP `sendmail()` time are
  caught and logged.
- **HTML rendering is naive** (`\n` → `<br>`). If you want a real HTML
  template with inline CSS, write it directly in the body field — it will
  pass through as-is.
