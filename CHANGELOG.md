# Changelog

Semua perubahan penting pada proyek ini akan didokumentasikan di file ini.

## [v1.0.0] - 2026-03-13

### Ditambahkan (Added)
- **Dokumentasi Kode**: Menambahkan komentar dan penjelasan rinci di file `main.asm` dan `helper.asm` agar kode assembly lebih mudah dipahami oleh programmer pemula.
- **Workflow Rilis Otomatis**: Menambahkan GitHub Actions workflow (`.github/workflows/release.yml`) untuk membuat `.exe` dan merilis artefak secara otomatis setiap kali ada push dengan tag versi (misal: `v*`).
- **Pencegahan Tembak Saat Bergerak**: Triggerbot sekarang mengecek tombol pergerakan (w, a, s, d). Jika salah satu tombol sedang ditekan, bot tidak menembak. Ini dibuat untuk mencegah *inaccuracy penalty* dari mekanisme tembak sambil bergerak di Valorant.

### Diperbarui (Changed)
- Peningkatan pemahaman *source code* pada logika utama (`main`) maupun fungsi pendukung (`helper`).
