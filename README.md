# Hướng Dẫn Dump Liên Quân Mobile (Android 64-bit)

Thư mục này chứa trọn bộ công cụ lấy `libil2cpp.so` (64-bit `arm64-v8a`) + `global-metadata.dat` đã giải mã và dump bằng **Il2CppDumper GUI**.

---

## 1. Cấu trúc thư mục

| Tên File / Thư mục | Chức năng |
| :--- | :--- |
| **[Dump_Lib_And_Metadata.bat](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump_Lib_And_Metadata.bat)** | **Cách 1 (Trên PC):** Tự động kéo và giải mã `libil2cpp.so` + `global-metadata.dat` từ giả lập đang chạy game (không cần Python) |
| **[Dump_GameGuardian.sh](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump_GameGuardian.sh)** | **Cách 2 (GameGuardian / Android `.sh`):** Script chạy trực tiếp trong **GameGuardian** (hoặc chạy `.sh` bằng MT Manager / Termux), xuất file vào `/sdcard/Download/` |
| **[Il2CppDumper_GUI/](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Il2CppDumper_GUI)** | Chứa **[Il2CppDumper GUI.exe](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Il2CppDumper_GUI/Il2CppDumper%20GUI.exe)** đã tích hợp giải mã Metadata v29 và quét nhanh ELF64 |
| **[libil2cpp.so](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/libil2cpp.so)** | File binary 64-bit (`arm64-v8a`) đã giải mã `.rodata` & `.text` |
| **[global-metadata.dat](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/global-metadata.dat)** | File metadata chuẩn (`0xFAB11BAF`, v29) đã giải mã |
| **[Dump/](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump)** | Thư mục chứa kết quả sau khi bấm **Start Dump** (`DummyDll/`, `dump.cs`, `il2cpp.h`, `script.json`, `stringliteral.json`) |

---

## 2. Cách lấy `libil2cpp.so` và `global-metadata.dat`

### Cách A: Dùng bằng GameGuardian hoặc chạy `.sh` trên Android ([Dump_GameGuardian.sh](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump_GameGuardian.sh))
File đã được chép sẵn vào giả lập tại `/sdcard/Download/Dump_GameGuardian.sh`:
1. Mở game **Liên Quân Mobile** vào đến màn hình sảnh.
2. Mở **GameGuardian**, chọn tiến trình **Liên Quân Mobile**.
3. Bấm nút **Play (`▶` - Chạy kịch bản)** ở góc phải -> chọn file `/sdcard/Download/Dump_GameGuardian.sh` -> bấm **Thực thi (Execute)** (chọn **Có / Cho phép** nếu GG hỏi quyền đọc/ghi file).
   - *Hoặc nếu dùng MT Manager / Termux (Root):* chạy trực tiếp file `/sdcard/Download/Dump_GameGuardian.sh`.
4. Sau 5–10 giây, 2 file sạch `libil2cpp.so` và `global-metadata.dat` sẽ nằm ngay tại:
   - `/sdcard/Download/libil2cpp.so`
   - `/sdcard/Download/global-metadata.dat`
5. Chép 2 file này ra máy tính, mở **[Il2CppDumper GUI.exe](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Il2CppDumper_GUI/Il2CppDumper%20GUI.exe)** và bấm **Start Dump** (không cần nhập Base Address hay Offset).

---

### Cách B: Chạy 1-Click trên PC ([Dump_Lib_And_Metadata.bat](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump_Lib_And_Metadata.bat))
1. Mở giả lập **LDPlayer 9**, vào game **Liên Quân Mobile** đến màn hình sảnh.
2. Nhấp đúp chạy **[Dump_Lib_And_Metadata.bat](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump_Lib_And_Metadata.bat)** để tự động kéo và giải mã thẳng `libil2cpp.so` + `global-metadata.dat` vào thư mục này.
3. Mở **[Il2CppDumper GUI.exe](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Il2CppDumper_GUI/Il2CppDumper%20GUI.exe)** và bấm **Start Dump**.

---

## 3. Cách sử dụng kết quả trong thư mục `Dump/`

- **Xem bằng dnSpy / ILSpy:** Mở thư mục **[DummyDll/](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump/DummyDll)**, kéo các file `.dll` (`Project_d.dll`, `Project.Plugins_d.dll`, `AovTdr.dll`, ...) vào **dnSpy** để tra cứu class, hàm, biến và lấy `RVA` / `Offset`.
- **Tra cứu nhanh bằng VS Code / Notepad++:** Mở trực tiếp file **[dump.cs](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump/dump.cs)**.
- **Load vào IDA Pro 64-bit:** Mở [libil2cpp.so](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/libil2cpp.so) trong IDA64 -> vào `File -> Script file...` -> chọn [ida_with_struct_py3.py](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump/ida_with_struct_py3.py) -> chọn lần lượt [script.json](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump/script.json) và [il2cpp.h](file:///C:/Users/Admin/Downloads/Dump_Android_64bit/Dump/il2cpp.h).
