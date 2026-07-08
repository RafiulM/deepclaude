# Panduan deepclaude

Panduan ini menjelaskan apa itu `deepclaude`, komponen yang dipakainya (Claude Code dan DeepSeek), serta cara instalasi dan penggunaannya langkah demi langkah.

## 1. Apa itu Claude Code

Claude Code adalah CLI (dan juga tersedia sebagai aplikasi desktop) buatan Anthropic yang menjalankan model Claude sebagai *coding agent* langsung di terminal atau editor kamu. Bedanya dengan chat biasa: Claude Code punya akses ke tool nyata di mesin kamu — baca/tulis file, jalankan perintah shell, jalankan test, baca output git, dsb — sehingga bisa mengeksekusi task engineering end-to-end, bukan sekadar menyarankan potongan kode.

Beberapa hal penting soal Claude Code yang relevan untuk deepclaude:

- Claude Code mengambil kredensial dan target API lewat environment variable, bukan hanya lewat login `claude.ai`. Dua variabel kuncinya adalah `ANTHROPIC_BASE_URL` (endpoint API yang dituju) dan `ANTHROPIC_AUTH_TOKEN` (API key/token otentikasi).
- Claude Code punya konsep "model tier" — model default untuk task berat (biasa dipetakan ke Opus), task menengah (Sonnet), dan task ringan/cepat (Haiku) — masing-masing bisa dioverride lewat env var (`ANTHROPIC_DEFAULT_OPUS_MODEL`, dst).
- Karena arsitekturnya berbasis env var + endpoint yang kompatibel dengan Anthropic API, Claude Code bisa "dialihkan" untuk bicara ke provider lain selama providernya menyediakan API yang kompatibel dengan format Anthropic (Messages API). Ini prinsip yang sama dipakai harness lain seperti OpenCode — semuanya berbasis "base URL + auth token + nama model", bukan terkunci ke satu backend.

## 2. Apa itu DeepSeek dan modelnya

DeepSeek adalah lab AI yang merilis model bahasa besar (LLM) open-weight maupun API komersial, dikenal karena kualitas reasoning dan coding yang kompetitif dengan biaya jauh lebih rendah dibanding model-model frontier lain. DeepSeek menyediakan API-nya sendiri di `api.deepseek.com`.

Yang membuat DeepSeek bisa dipakai langsung oleh Claude Code tanpa proxy tambahan: DeepSeek menyediakan **endpoint kompatibel-Anthropic** di `https://api.deepseek.com/anthropic`. Endpoint ini menerima request dalam format Anthropic Messages API, jadi tool apa pun yang sudah tahu cara bicara ke Claude (termasuk Claude Code) bisa langsung diarahkan ke sana hanya dengan mengganti `ANTHROPIC_BASE_URL` dan `ANTHROPIC_AUTH_TOKEN` — tanpa perlu SDK atau adapter khusus.

Model yang dipakai `deepclaude` secara default (per konfigurasi saat ini di `deepclaude`):

| Env var Claude Code | Model DeepSeek | Peran |
|---|---|---|
| `ANTHROPIC_MODEL` | `deepseek-v4-pro[1m]` | Model utama saat `claude` dijalankan |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro[1m]` | Pengganti tier "Opus" (task berat) |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro[1m]` | Pengganti tier "Sonnet" (task standar) |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` | Pengganti tier "Haiku" (task ringan/cepat) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` | Model yang dipakai subagent (mis. hasil `Task`/`Agent` tool) |

`[1m]` menandakan varian context window besar (1 juta token) dari model pro tersebut. Dengan pemetaan ini, semua tier model Claude Code otomatis diarahkan ke model DeepSeek yang setara dari sisi peran (berat vs ringan), tanpa perlu mengubah cara kamu memakai Claude Code sehari-hari.

## 3. Apa itu deepclaude

`deepclaude` adalah wrapper shell script tipis di sekitar `claude` CLI. Ia tidak memodifikasi Claude Code — ia hanya:

1. Menyimpan dan mengelola DeepSeek API key kamu secara lokal.
2. Meng-*export* environment variable yang diperlukan (base URL, auth token, pemetaan model) sebelum memanggil `claude`.
3. Menjalankan `claude --dangerously-skip-permissions "$@"`, meneruskan semua argumen yang kamu berikan ke `deepclaude`.

Karena ini "hanya" env var + exec, kamu tetap memakai `claude` versi asli yang sudah terpasang di mesin kamu — deepclaude bukan fork atau distribusi Claude Code sendiri.

> **Catatan tentang `--dangerously-skip-permissions`:** flag ini membuat Claude Code menjalankan tool (edit file, jalankan command, dsb.) tanpa meminta konfirmasi per-aksi. Ini nyaman untuk kecepatan kerja, tapi berarti perintah shell dan perubahan file akan langsung dieksekusi tanpa persetujuan manual. Gunakan `deepclaude` hanya di direktori/project yang kamu percaya.

## 4. Prasyarat

- Sistem operasi: macOS, Linux, atau Windows (native PowerShell atau via Git Bash/WSL).
- `curl` atau `wget` terpasang (untuk installer shell).
- **Claude Code CLI (`claude`) sudah terpasang** di PATH. Ini prasyarat wajib — deepclaude tidak menginstal Claude Code, hanya mengatur env var lalu memanggilnya. Instal dulu dari [docs.claude.com/en/docs/claude-code](https://docs.claude.com/en/docs/claude-code) kalau belum ada.
- API key DeepSeek. Buat di [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys).

## 5. Instalasi langkah demi langkah

### macOS / Linux

1. Jalankan installer:

   ```bash
   curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors https://raw.githubusercontent.com/RafiulM/deepclaude/main/install.sh | bash
   ```

   Kalau GitHub raw content sedang rate-limited (`curl: (56) ... 429`), pakai mirror jsDelivr sebagai gantinya:

   ```bash
   curl -fsSL https://cdn.jsdelivr.net/gh/RafiulM/deepclaude@main/install.sh | bash
   ```

   Script installer ini mengunduh satu file executable `deepclaude` ke `~/.local/bin/deepclaude` (bisa diubah lewat env var `DEEPCLAUDE_BIN_DIR`), lalu `chmod +x` di atasnya. Ia juga mencoba retry otomatis dan fallback ke mirror kalau unduhan awal gagal.

2. Kalau `~/.local/bin` belum ada di `PATH`, installer akan mencetak baris yang perlu kamu tambahkan ke shell profile (`~/.bashrc` atau `~/.zshrc`):

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

   Tambahkan baris itu, lalu buka terminal baru (atau `source` ulang profile-nya).

3. Verifikasi instalasi:

   ```bash
   deepclaude --help
   ```

### Windows (PowerShell)

1. Jalankan:

   ```powershell
   irm https://raw.githubusercontent.com/RafiulM/deepclaude/main/install.ps1 | iex
   ```

   Ini menginstal `deepclaude` ke `%LOCALAPPDATA%\Programs\deepclaude` dan menambahkannya ke user `PATH`.

2. **Wajib buka terminal baru** setelah instalasi supaya perubahan `PATH` terbaca.

3. Alternatif: dari **Git Bash** atau **WSL** di Windows, kamu juga bisa memakai command macOS/Linux di atas.

## 6. Konfigurasi API key

Saat pertama kali `deepclaude` dijalankan tanpa key tersimpan, ia akan menanyakan API key secara interaktif (input tersembunyi, tidak tampil di terminal) lalu menyimpannya.

Urutan resolusi key (dari prioritas tertinggi ke terendah):

1. `deepclaude config <KEY>` — set langsung lewat argumen, tanpa prompt.
2. File konfigurasi tersimpan dari run sebelumnya.
3. Environment variable `DEEPSEEK_API_KEY` — dipakai sekali lalu otomatis disimpan untuk run berikutnya.
4. Prompt interaktif — muncul otomatis kalau tak satu pun di atas tersedia.

Lokasi penyimpanan key:

| Platform | Path | Keterangan |
|---|---|---|
| macOS/Linux | `~/.config/deepclaude/config` | permission `600` (hanya owner) |
| Windows | `%APPDATA%\deepclaude\config` | ACL: hanya user kamu |

Key disimpan **plaintext**. Siapa pun dengan akses ke akun user kamu bisa membacanya — perlakukan seperti kredensial lokal lainnya (jangan commit, jangan share screen dengan file itu terbuka).

## 7. Cara pakai

Jalankan langsung, semua argumen diteruskan apa adanya ke `claude`:

```bash
deepclaude                          # buka Claude Code interaktif seperti biasa
deepclaude "refactor modul ini"     # kirim prompt langsung
deepclaude --help                   # lihat opsi `claude` asli
```

Yang terjadi di balik layar setiap kali kamu run `deepclaude` (dengan key sudah tersedia):

```sh
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="<key DeepSeek kamu>"
export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_EFFORT_LEVEL="max"

exec claude --dangerously-skip-permissions "$@"
```

Karena ini `exec`, proses `deepclaude` digantikan langsung oleh proses `claude` — bukan menjalankannya sebagai child process terpisah.

## 8. Mengelola key

```bash
deepclaude change-key            # ganti key tersimpan (prompt interaktif)
deepclaude change-key <KEY>      # ganti key tanpa prompt
deepclaude reset                 # hapus key yang tersimpan
```

`config`, `set-key`, dan `change` adalah alias yang setara dengan `change-key`.

## 9. Update deepclaude

```bash
deepclaude update
```

Perintah ini menjalankan ulang installer (`install.sh`) untuk menarik versi terbaru dari GitHub, dengan retry dan fallback ke mirror jsDelivr kalau `raw.githubusercontent.com` sedang rate-limited.

## 10. Uninstall

**macOS / Linux**

```bash
rm ~/.local/bin/deepclaude
rm -rf ~/.config/deepclaude
```

**Windows (PowerShell)**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Programs\deepclaude"
Remove-Item -Recurse -Force "$env:APPDATA\deepclaude"
```

## 11. Troubleshooting singkat

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `curl: (56) ... 429` saat instalasi/update | Rate limit di `raw.githubusercontent.com` (bersifat intermiten, tergantung IP) | Installer sekarang retry otomatis lalu fallback ke mirror jsDelivr — cukup jalankan ulang perintah yang sama. Kalau masih gagal, pakai mirror jsDelivr secara eksplisit (lihat bagian 5), atau tunggu beberapa menit |
| `claude CLI not found on PATH` | Claude Code belum terpasang atau belum ada di `PATH` | Instal Claude Code dari docs resminya, pastikan `claude --version` berjalan sebelum memakai `deepclaude` |
| `No API key available` | Key belum pernah disimpan dan tidak ada di env | Jalankan `deepclaude config <KEY>` atau biarkan prompt interaktif muncul saat run pertama |
| Perubahan `PATH` tidak terbaca setelah instalasi | Shell profile belum di-reload | Buka terminal baru, atau `source ~/.zshrc` / `source ~/.bashrc` |

### Tentang penanganan error 429

`install.sh` versi saat ini punya mekanisme `fetch()` yang: (1) mencoba `raw.githubusercontent.com` dengan `curl --retry 3 --retry-delay 2 --retry-all-errors`, (2) kalau tetap gagal, otomatis pindah ke mirror `cdn.jsdelivr.net`. Mekanisme yang sama dipakai `deepclaude update` dan one-liner instalasi di README — bootstrap curl yang mengunduh `install.sh` itu sendiri juga sudah diberi retry + fallback ke jsDelivr, bukan cuma unduhan binary `deepclaude` di dalamnya.

Sudah diuji langsung: dengan mensimulasikan kegagalan pada `raw.githubusercontent.com` (termasuk kasus nyata di mana GitHub benar-benar mengembalikan `429` saat pengujian), instalasi tetap **berhasil** karena jatuh ke mirror jsDelivr secara otomatis. Rate limit di `raw.githubusercontent.com` bersifat intermiten (tidak selalu terjadi), sehingga kadang instalasi langsung sukses di percobaan pertama — mekanisme fallback ini menjaga instalasi tetap jalan di saat rate limit itu muncul.

## 12. Ringkasan konseptual

- **Claude Code** = harness/agent CLI yang bicara ke API bergaya Anthropic lewat `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN`.
- **DeepSeek** = provider LLM dengan endpoint kompatibel-Anthropic di `api.deepseek.com/anthropic`, sehingga bisa "menyamar" sebagai backend Claude tanpa proxy tambahan.
- **deepclaude** = wrapper tipis yang mengelola key DeepSeek kamu dan mengarahkan `claude` ke endpoint DeepSeek tersebut lewat env var, lalu `exec claude` — tidak ada logic AI tambahan di dalamnya, murni konfigurasi routing.
