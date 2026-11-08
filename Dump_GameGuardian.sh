_=0; --[[ 2>/dev/null
# ==============================================================================
# SCRIPT DUMP & GIAI MA LIBIL2CPP.SO + GLOBAL-METADATA.DAT (LIEN QUAN 64-BIT)
# Ho tro chay tren:
#   1. GameGuardian (Bam Play -> Chon file Dump_GameGuardian.sh -> Thuc thi)
#   2. Root Shell / MT Manager / Termux (sh /sdcard/Download/Dump_GameGuardian.sh)
# Dau ra: /sdcard/Download/libil2cpp.so & /sdcard/Download/global-metadata.dat
# ==============================================================================
PKG="com.garena.game.kgvn"
OUT_DIR="/sdcard/Download"

REMOTE_LIB=$(find /data/data/$PKG/files/Resources -name libil2cpp.so 2>/dev/null | head -n 1)
if [ -z "$REMOTE_LIB" ]; then
    echo "[!] Khong tim thay libil2cpp.so! Hay mo game Lien Quan it nhat 1 lan."
    exit 1
fi
RES_ROOT=$(echo "$REMOTE_LIB" | sed 's|/arm[^/]*/libil2cpp\.so$||')
REMOTE_META="$RES_ROOT/Managed/Metadata/global-metadata.dat"

echo "[*] Dang copy libil2cpp.so & global-metadata.dat..."
cp "$REMOTE_LIB" "$OUT_DIR/libil2cpp.so"
cp "$REMOTE_META" "$OUT_DIR/global-metadata.dat"

GAME_PID=$(pidof $PKG)
if [ -z "$GAME_PID" ]; then
    echo "[!] Hay mo game Lien Quan vao den sanh roi chay lai!"
    exit 1
fi

BASE_HEX=$(grep "libil2cpp.so" /proc/$GAME_PID/maps | awk '/00000000/{prev=$1} /0322e000/{split(prev,a,"-"); print a[1]; exit}')
if [ -n "$BASE_HEX" ]; then
    BASE_ADDR=$(( 0x$BASE_HEX ))
    RO_START=$(( 0x1600000 ))
    RO_END=$(( 0x322e224 ))
    RO_SKIP=$(( (BASE_ADDR + RO_START) / 65536 ))
    RO_SEEK=$(( RO_START / 65536 ))
    RO_CNT=$(( (RO_END - RO_START + 65535) / 65536 ))

    echo "[*] Dang giai ma .rodata & .text tu RAM (PID: $GAME_PID, Base: 0x$BASE_HEX)..."
    dd if=/proc/$GAME_PID/mem of="$OUT_DIR/libil2cpp.so" bs=65536 skip=$RO_SKIP seek=$RO_SEEK count=$RO_CNT conv=notrunc 2>/dev/null

    TX_SKIP=$(( (BASE_ADDR + 0x3230000) / 65536 ))
    TX_CNT=$(( (0x6e6c1c0 + 0x2230 + 65535) / 65536 ))
    dd if=/proc/$GAME_PID/mem of="/data/local/tmp/tx.tmp" bs=65536 skip=$TX_SKIP count=$TX_CNT 2>/dev/null
    dd if="/data/local/tmp/tx.tmp" of="$OUT_DIR/libil2cpp.so" bs=16 skip=547 seek=3288611 count=221 conv=notrunc 2>/dev/null
    dd if="/data/local/tmp/tx.tmp" of="$OUT_DIR/libil2cpp.so" bs=4096 skip=3 seek=12847 count=28267 conv=notrunc 2>/dev/null
    rm -f "/data/local/tmp/tx.tmp"
fi

chmod 666 "$OUT_DIR/libil2cpp.so" "$OUT_DIR/global-metadata.dat" 2>/dev/null
echo "[OK] Hoan tat! File da luu tai: $OUT_DIR/libil2cpp.so va $OUT_DIR/global-metadata.dat"
exit 0
]]

-- ============================================================================
-- PHẦN CHẠY TRONG GAMEGUARDIAN (DÙNG 100% gg.dumpMemory - KHÔNG CẦN QUYỀN ĐỌC /data/data)
-- ============================================================================
local OUT_DIR = "/sdcard/Download"

local function read_u32_le(str, pos)
    local b1, b2, b3, b4 = string.byte(str, pos, pos + 3)
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function read_u64_le(str, pos)
    local lo = read_u32_le(str, pos)
    local hi = read_u32_le(str, pos + 4)
    return lo + hi * 4294967296
end

local function read_u16_le(str, pos)
    local b1, b2 = string.byte(str, pos, pos + 1)
    return b1 + b2 * 256
end

local function pack_u32_le(val)
    val = val % 4294967296
    local b1 = val % 256; val = math.floor(val / 256)
    local b2 = val % 256; val = math.floor(val / 256)
    local b3 = val % 256; val = math.floor(val / 256)
    local b4 = val % 256
    return string.char(b1, b2, b3, b4)
end

local function bxor32(a, b)
    local res = 0
    local bit = 1
    a = a % 4294967296
    b = b % 4294967296
    while a > 0 or b > 0 do
        local ra = a % 2
        local rb = b % 2
        if ra ~= rb then res = res + bit end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return res
end

local function decrypt_metadata_header(hdr256)
    local magic = read_u32_le(hdr256, 1)
    if magic ~= 0xEAB11BAF then
        return hdr256, false
    end

    local in_hdr = {}
    local out_hdr = {}
    for i = 0, 63 do
        in_hdr[i] = read_u32_le(hdr256, i * 4 + 1)
        out_hdr[i] = in_hdr[i]
    end

    local map = {4, 8, 12, 16, 20, 6, 10, 14, 18, 22, 2, 48, 46, 44, 42, 24, 28, 32, 36, 40, 26, 30, 34, 38}
    for k = 0, 23 do
        local in_idx  = 2 + (2 * k)
        local out_idx = map[k + 1]
        local v0 = (in_hdr[in_idx]     - (3 * k)) % 4294967296
        local v1 = (in_hdr[in_idx + 1] - (7 * k)) % 4294967296
        out_hdr[out_idx]     = bxor32(v0, 0x00A8C72D + k)
        out_hdr[out_idx + 1] = bxor32(v1, 0x00A8C72D + (2 * k))
    end
    out_hdr[0] = 0xFAB11BAF
    out_hdr[1] = 29

    local out = {}
    for i = 0, 63 do
        out[i + 1] = pack_u32_le(out_hdr[i])
    end
    return table.concat(out), true
end

local function copy_stream(src_f, dst_f, size)
    local CHUNK = 1024 * 1024
    local remaining = size
    while remaining > 0 do
        local to_read = remaining > CHUNK and CHUNK or remaining
        local buf = src_f:read(to_read)
        if not buf or #buf == 0 then break end
        dst_f:write(buf)
        remaining = remaining - #buf
    end
end

local function wait_dump_file(path, min_size)
    for _ = 1, 60 do
        local f = io.open(path, "rb")
        if f then
            local sz = f:seek("end")
            if sz and sz >= min_size then
                f:seek("set", 0)
                return f
            end
            f:close()
        end
        gg.sleep(250)
    end
    return io.open(path, "rb")
end

local function main()
    gg.toast("Đang quét vùng nhớ libil2cpp.so...")
    local lib_ranges = gg.getRangesList("libil2cpp.so")
    if not lib_ranges or #lib_ranges == 0 then
        gg.alert("❌ Không tìm thấy libil2cpp.so trong RAM!\nHãy mở game Liên Quân vào đến sảnh rồi chọn đúng tiến trình game trong GameGuardian.")
        return
    end

    local pkg = gg.getTargetPackage() or "com.garena.game.kgvn"

    -- 1. Tìm vùng nhớ chứa toàn bộ Disk ELF libil2cpp.so (~171 MB) trên RAM
    local disk_range = nil
    for _, r in ipairs(lib_ranges) do
        local sz = r["end"] - r.start
        if sz > 0x9000000 then
            disk_range = r
            break
        end
    end

    if not disk_range then
        gg.alert("❌ Không tìm thấy vùng nhớ ELF gốc của libil2cpp.so! Hãy đảm bảo đang dùng bản 64-bit.")
        return
    end

    gg.toast("Bước 1/4: Đang dump khung ELF gốc từ RAM...")
    gg.dumpMemory(disk_range.start, disk_range["end"] - 1, OUT_DIR)
    local disk_bin_path = string.format("%s/%s-%x-%x.bin", OUT_DIR, pkg, disk_range.start, disk_range["end"])
    local f_disk = wait_dump_file(disk_bin_path, disk_range["end"] - disk_range.start)
    if not f_disk then
        gg.alert("❌ Không thể đọc file dump tại:\n" .. disk_bin_path)
        return
    end

    local ehdr = f_disk:read(64)
    local e_phoff = read_u64_le(ehdr, 33)
    local e_phnum = read_u16_le(ehdr, 57)
    f_disk:seek("set", e_phoff)
    local ph_raw = f_disk:read(e_phnum * 56)

    local load_phdrs = {}
    for i = 0, e_phnum - 1 do
        local base = i * 56 + 1
        local p_type   = read_u32_le(ph_raw, base)
        local p_flags  = read_u32_le(ph_raw, base + 4)
        local p_offset = read_u64_le(ph_raw, base + 8)
        local p_vaddr  = read_u64_le(ph_raw, base + 16)
        local p_filesz = read_u64_le(ph_raw, base + 32)
        if p_type == 1 and p_filesz > 0 then
            table.insert(load_phdrs, {
                flags = p_flags,
                offset = p_offset,
                vaddr = p_vaddr,
                filesz = p_filesz
            })
        end
    end

    local ph_ro = load_phdrs[1]
    local ph_tx = load_phdrs[2]

    -- 2. Tìm Base Address của instance libil2cpp.so đang chạy trên RAM
    local base_addr = nil
    for _, r in ipairs(lib_ranges) do
        local sz = r["end"] - r.start
        if sz >= ph_ro.filesz and sz < (ph_ro.filesz + 0x100000) then
            base_addr = r.start
            break
        end
    end
    if not base_addr then
        base_addr = lib_ranges[2] and lib_ranges[2].start or lib_ranges[1].start
    end

    local ro_mem_start  = base_addr
    local ro_mem_end    = base_addr + math.floor((ph_ro.filesz + 4095) / 4096) * 4096
    local tx_page_vaddr = math.floor(ph_tx.vaddr / 4096) * 4096
    local tx_mem_start  = base_addr + tx_page_vaddr
    local tx_mem_end    = base_addr + math.floor((ph_tx.vaddr + ph_tx.filesz + 4095) / 4096) * 4096

    gg.toast("Bước 2/4: Đang dump .rodata & .text đã giải mã...")
    gg.dumpMemory(ro_mem_start, ro_mem_end - 1, OUT_DIR)
    gg.dumpMemory(tx_mem_start, tx_mem_end - 1, OUT_DIR)

    local ro_bin_path = string.format("%s/%s-%x-%x.bin", OUT_DIR, pkg, ro_mem_start, ro_mem_end)
    local tx_bin_path = string.format("%s/%s-%x-%x.bin", OUT_DIR, pkg, tx_mem_start, tx_mem_end)

    local f_ro = wait_dump_file(ro_bin_path, ro_mem_end - ro_mem_start)
    local f_tx = wait_dump_file(tx_bin_path, tx_mem_end - tx_mem_start)
    if not f_ro or not f_tx then
        f_disk:close()
        if f_ro then f_ro:close() end
        if f_tx then f_tx:close() end
        gg.alert("❌ Không tìm thấy file dump .rodata/.text tại:\n" .. ro_bin_path)
        return
    end

    -- 3. Ghép thành /sdcard/Download/libil2cpp.so hoàn chỉnh
    gg.toast("Bước 3/4: Đang ghép libil2cpp.so...")
    local out_lib_path = OUT_DIR .. "/libil2cpp.so"
    os.remove(out_lib_path)
    local f_out = io.open(out_lib_path, "wb")

    local ro_patch_start = 0x1600000
    local ro_patch_len   = ph_ro.filesz - ro_patch_start

    f_disk:seek("set", 0)
    copy_stream(f_disk, f_out, ro_patch_start)

    f_ro:seek("set", ro_patch_start)
    copy_stream(f_ro, f_out, ro_patch_len)

    if ph_tx.offset > ph_ro.filesz then
        f_disk:seek("set", ph_ro.filesz)
        copy_stream(f_disk, f_out, ph_tx.offset - ph_ro.filesz)
    end

    local tx_pad = ph_tx.vaddr - tx_page_vaddr
    f_tx:seek("set", tx_pad)
    copy_stream(f_tx, f_out, ph_tx.filesz)

    local after_tx = ph_tx.offset + ph_tx.filesz
    local total_disk_size = f_disk:seek("end")
    f_disk:seek("set", after_tx)
    copy_stream(f_disk, f_out, total_disk_size - after_tx)

    f_out:close()
    f_ro:close()
    f_tx:close()
    f_disk:close()

    os.remove(disk_bin_path)
    os.remove(ro_bin_path)
    os.remove(tx_bin_path)

    -- 4. Dump và giải mã global-metadata.dat từ RAM bằng gg.dumpMemory
    gg.toast("Bước 4/4: Đang dump & giải mã global-metadata.dat...")
    local meta_ranges = gg.getRangesList("global-metadata.dat")
    local meta_status = "Không tìm thấy"
    if meta_ranges and #meta_ranges > 0 then
        local mr = meta_ranges[1]
        gg.dumpMemory(mr.start, mr["end"] - 1, OUT_DIR)
        local meta_bin_path = string.format("%s/%s-%x-%x.bin", OUT_DIR, pkg, mr.start, mr["end"])
        local fm_in = wait_dump_file(meta_bin_path, mr["end"] - mr.start)
        if fm_in then
            local hdr256 = fm_in:read(256)
            local dec_hdr, was_enc = decrypt_metadata_header(hdr256)
            local out_meta_path = OUT_DIR .. "/global-metadata.dat"
            os.remove(out_meta_path)
            local fm_out = io.open(out_meta_path, "wb")
            fm_out:write(dec_hdr)
            local meta_total = fm_in:seek("end")
            fm_in:seek("set", 256)
            copy_stream(fm_in, fm_out, meta_total - 256)
            fm_out:close()
            fm_in:close()
            os.remove(meta_bin_path)
            meta_status = was_enc and "Đã giải mã (0xEAB11BAF -> 0xFAB11BAF)" or "Chuẩn (0xFAB11BAF)"
        end
    end

    gg.alert(string.format(
        "✅ DUMP & GIẢI MÃ HOÀN TẤT!\n\n" ..
        "📂 Đã lưu tại: %s\n" ..
        "1️⃣ libil2cpp.so\n" ..
        "2️⃣ global-metadata.dat (%s)\n\n" ..
        "👉 Chép 2 file này ra PC và bấm Start Dump trên Il2CppDumper GUI!",
        OUT_DIR, meta_status
    ))
end

main()
