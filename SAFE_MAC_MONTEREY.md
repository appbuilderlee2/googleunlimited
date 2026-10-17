# Safe setup — Intel MacBook 12-inch (2016), macOS Monterey 12

> This fork is experimental. Pixel emulation and Google authentication are unofficial.
> Using a dedicated test Google account does not eliminate account compromise, service-policy, or data-loss risks.
> SHA-256 checks ensure a downloaded binary matches a pinned value; they are **not** a malware audit.
> Never use this as the only copy of irreplaceable photos.

## 1. Inspect your machine (read-only)

```bash
sw_vers -productVersion
uname -m
spctl --status
git --version
command -v sqlite3
command -v curl
command -v fswatch
command -v brew
```

Expected: Monterey 12.x, x86_64, `assessments enabled`. Git can be installed with Apple's `xcode-select --install`. Python 3 is **not required** by the Bash manager. Homebrew is optional unless installing the file watcher; Monterey is an unsupported/limited-support platform for current Homebrew releases.

## 2. Download and inspect

```bash
git clone https://github.com/appbuilderlee2/googleunlimited.git
cd googleunlimited
bash -n google-unlimited.sh
git rev-parse HEAD
```

Never paste login tokens into chat, public issues, screenshots, shell command arguments, or your Git repository.

## 3. Dependencies and setup

The manager needs `sqlite3`, `curl`, and for continuous watching, `fswatch`. macOS generally includes sqlite3 and curl. If Homebrew is **already installed and working**, use:

```bash
brew install fswatch
```

Do not install Homebrew blindly on an unsupported OS. You can skip live watching and use upstream gotohp's documented CLI for explicit manual uploads instead.

```bash
bash google-unlimited.sh setup
bash google-unlimited.sh verify
```

The setup is designed to **fail closed** on missing/mismatched pinned SHA-256; it does **not** strip Apple's quarantine flag. Stop if SHA verification fails or Gatekeeper rejects the downloaded binary. **Do not** disable Gatekeeper/SIP or run `xattr -d com.apple.quarantine` to force execution.

Before executing a binary, inspect it with:

```bash
file gotohp-cli-macos-universal
codesign -dv --verbose=2 gotohp-cli-macos-universal
spctl -a -vv -t execute gotohp-cli-macos-universal
```

An unsigned or unnotarized third-party binary may be blocked. This guide does not recommend bypassing that protection.

## 4. Explicit upload folder (required in this fork)

```bash
mkdir -p "$HOME/GoogleUpload"
printf '%s\n' "$HOME/GoogleUpload" > watch_dirs.txt
chmod 600 watch_dirs.txt
```

Only put **copies** of test photos into this directory. This fork does not automatically scan Pictures/Downloads when `watch_dirs.txt` is absent. If there are no valid configured directories, watcher startup fails rather than scanning elsewhere.

## 5. Authentication and test

Use a fresh Google test account with no important data. The upstream tool uses sensitive embedded-setup tokens. This does not provide normal, fine-grained Google OAuth authorization.

```bash
bash google-unlimited.sh creds add
bash google-unlimited.sh creds list
bash google-unlimited.sh watch
```

Only use the interactive hidden prompt. **Never** provide the token as a command-line argument. `watch` scans the explicitly configured directory before watching for changes. Press Control-C to stop. Inspect progress:

```bash
bash google-unlimited.sh status
bash google-unlimited.sh logs
```

Verify each test photo/video independently at https://photos.google.com, including downloaded integrity and storage quota, before larger experiments. No upload success message guarantees zero quota usage or long-term availability.

## 6. Safety caveats

- macOS Monterey is old and no longer a suitable high-assurance host for sensitive long-lived Google credentials.
- `gotohp.config` is restricted with Unix file permissions, not established as encrypted by this project.
- Do not enable unattended startup until you are comfortable with the behavior and have inspected the LaunchAgent.
- Keep at least two independent copies of original media; do not delete the sole iPhone originals after upload.
- A new upstream version changes binaries/checksums: **review and verify** before updating pinned hashes.
