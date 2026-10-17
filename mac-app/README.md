# Native Mac interface — Monterey 12

This app is built **locally from source** using Apple's Swift compiler (AppKit), not downloaded as a prebuilt application. It targets the 2016 Intel MacBook running macOS Monterey 12.

## Build on your Mac

Run in Terminal (after cloning this fork):

```bash
cd ~/googleunlimited
xcode-select -p
bash build-mac-app.sh
open GoogleUnlimited.app
```

If Command Line Tools are missing, run `xcode-select --install` first. After a `git pull --ff-only`, rerun `bash build-mac-app.sh` to update the app.

## Controls

- **選擇資料夾** — explicitly choose a watched upload directory. Stored as `watch_dirs.txt`.
- **開始上傳** — start `bash google-unlimited.sh watch` and show console output.
- **停止** — stop the watcher using the existing `stop` script action.
- **上傳統計** / **最近紀錄** — read local SQLite-backed upload results/logs.
- **開啟資料夾** / **Google Photos** — open corresponding folder or website.
- **檢查程式** — verify the gotohp binary checksum.

The app **does not contain or read your Google token**, does not auto-delete photos, and does not enable background startup. Continue to manage credentials using the documented interactive terminal command, never a command line token argument.

The app bundle must stay next to the Bash script in the cloned repo. Do not move it alone into /Applications. You can create a Finder alias to the app if you want a shortcut.

**Security note:** The UI is compiled locally, but the existing downloaded gotohp command-line executable is still unsigned/unnotarized. The GUI cannot make it trusted. Do not disable Gatekeeper or SIP to get it working. Your existing test account and manual verification precautions still apply.

**Backup note:** Upload report counts are only local records. Check the actual media in Google Photos and maintain a separate backup before deleting local files.
