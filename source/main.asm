.386                  ; Use 32-bit instructions
.model flat, stdcall  ; Use flat memory and stdcall calling convention (used for Windows API calling)
.stack 4096           ; Set up a stack with a size of 4096 bytes (4 KB)

include win.inc
include helper.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib shlwapi.lib

.data
    ; ========== BAGIAN DATA (VARIABEL) ==========
    EXTERN cfg : CONFIG              ; Mengambil variabel konfigurasi dari file lain
    screen_data      dd 0            ; Tempat menyimpan data gambar (screenshot) layar
    pixel_count      dd 0            ; Menyimpan jumlah total piksel yang akan discan
    h_window         dd 0            ; ID atau handle untuk jendela game Valorant
    msg_buffer       db 64 dup(0)    ; Buffer (ruang kosong) untuk format teks pesan
    
    ; Pesan yang akan ditampilkan ke CMD (Console)
    msg1             db "The triggerbot is running successfully. Go into a game and enjoy!", 0AH, 0AH, 0  
    msg2             db 13, "Reaction time: %lu ms  ", 0
    error_msg1       db "ERROR: Failed reading Config. Ensure config.txt is in the same folder as main.exe with correct values", 0AH, 0
    error_msg2       db "ERROR: GetScreenshot failed.", 0AH, 0 
    error_msg3       db "ERROR: FindWindow failed. Make sure that Valorant is running.", 0AH, 0 
    error_msg4       db "ERROR: LeftClick (PostMessage) failed", 0AH, 0 
    window_name      db "VALORANT  ", 0 ; Nama window game yang dicari

.code
; ========== FUNGSI UTAMA PROGRAM ==========
main: 
    ; 1. Membaca pengaturan dari file config.txt
    invoke GetConfig
    cmp eax, 0
    je CFG_FAILED 

    ; 2. Menghitung jumlah piksel yang perlu diperiksa (lebar area x tinggi area)
    mov eax, cfg.scan_area
    mov ebx, cfg.scan_area
    mul ebx
    mov pixel_count, eax

    ; 3. Mencari game Valorant yang sedang berjalan dan mendapatkan ID jendelanya
    ; Ini digunakan nanti untuk mengirim perintah "klik" secara rahasia (PostMessage)
    invoke FindWindowA, 0, offset window_name
    cmp eax, 0
    je FIND_WINNM_FAILED
    mov h_window, eax

    ; Menampilkan pesan bahwa bot sudah aktif
    invoke PrintConsole, offset msg1

    ; Menyiapkan penghitung waktu untuk menghitung kecepatan respons bot (ms)
    invoke InitPerformanceCounters

; ========== LOOP UTAMA (Berjalan terus menerus) ==========
MAIN_LOOP:
    ; 4. Mengecek apakah tombol pemicu utama (misal Left Alt) sedang ditekan
    invoke IsKeyPressed, cfg.hold_key
    cmp eax, 0
    je MAIN_LOOP        ; Jika tidak ditekan, ulang periksa tombol lagi terus menerus
    
    ; Memastikan pemain tidak sedang bergerak saat akan menembak (akurasi senjata hilang saat jalan)
    invoke IsKeyPressed, 57h    ; Mengecek tombol W (0x57)
    cmp eax, 1
    je MAIN_LOOP                ; Jika sedang ditekan, batalkan tembakan & kembali ngeloop
    
    invoke IsKeyPressed, 41h    ; Mengecek tombol A (0x41)
    cmp eax, 1
    je MAIN_LOOP
    
    invoke IsKeyPressed, 53h    ; Mengecek tombol S (0x53)
    cmp eax, 1
    je MAIN_LOOP
    
    invoke IsKeyPressed, 44h    ; Mengecek tombol D (0x44)
    cmp eax, 1
    je MAIN_LOOP

    ; 5. Jika ditekan dan pemain sedang diam, mulai hitung waktu respons (timer)
    invoke StartCounter

    ; 6. Mengambil gambar (screenshot) area kecil di tengah layar (tempat crosshair)
    invoke GetScreenshot, cfg.scan_area, cfg.scan_area, 0
    cmp eax, 0
    je SS_FAILED
    mov screen_data, eax

    ; 7. Mengecek pixel satu per satu untuk mencari warna musuh (R, G, B + dengan Sensitivitas)
    invoke FindColor, screen_data, pixel_count, cfg.color_sens, cfg.red, cfg.green, cfg.blue
    cmp eax, 1
    je COLOR_FOUND      ; Jika warna target ditemukan, loncat ke bagian COLOR_FOUND

    ; Jika warnanya tidak ditemukan, hapus gambar screenshot dari memori agar RAM tidak penuh, lalu ulang dari awal
    invoke GlobalFree, screen_data 
    jmp MAIN_LOOP

; ========== JIKA WARNA MUSUH DITEMUKAN ==========
COLOR_FOUND:
    ; 8. Kirim perintah KLIK KIRI otomatis ke dalam game
    invoke LeftClick, h_window
    cmp eax, 0
    je LEFT_CLICK_FAILED

    ; Hentikan penghitung waktu dan catat durasi (berapa ms waktu responsnya)
    invoke StopCounter

    ; Tampilkan waktu responsnya (dalam milidetik) ke console agar keren
    invoke wsprintfA, offset msg_buffer, offset msg2, eax
    invoke PrintConsole, offset msg_buffer

    ; 9. Berhenti sejenak sesuai dengan waktu tap_time (supaya ga nembak terlalu cepat / spammy macem mesin senapan)
    invoke Sleep, cfg.tap_time
    
    ; Bersihkan memori gambar dan kembali mengulang pendeteksian
    invoke GlobalFree, screen_data 
    jmp MAIN_LOOP


; ========== BAGIAN PENANGANAN ERROR (Muncul tulisan & program tertutup) ==========
CFG_FAILED:
    invoke PrintConsole, offset error_msg1
    invoke Sleep, 3000
    invoke ExitProcess, 0    

SS_FAILED:
    invoke PrintConsole, offset error_msg2
    invoke Sleep, 3000
    invoke ExitProcess, 0    

FIND_WINNM_FAILED:
    invoke PrintConsole, offset error_msg3
    invoke Sleep, 3000
    invoke ExitProcess, 0  

LEFT_CLICK_FAILED:
    invoke PrintConsole, offset error_msg4
    invoke Sleep, 3000
    invoke ExitProcess, 0
    
end main