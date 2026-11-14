# Dump Liên Quân Mobile — Android ARM64

Bộ công cụ lấy libil2cpp.so, giải mã metadata và xuất dump bằng CLI portable.

## Công cụ

- [Il2CppDumper_CLI_AOV.zip](Il2CppDumper_CLI_AOV.zip): tool mới, kèm .NET runtime và script import IDA/Ghidra.
- [SHA-256](Il2CppDumper_CLI_AOV.zip.sha256): checksum của gói tool.
- [Dump_Lib_And_Metadata.bat](Dump_Lib_And_Metadata.bat): lấy lib và metadata đã giải mã từ LDPlayer trên PC.
- [Dump_GameGuardian.sh](Dump_GameGuardian.sh): lấy dữ liệu qua GameGuardian hoặc root shell Android; CLI cần metadata đã giải mã.
- [CLI_PATCH](CLI_PATCH/README.md): hướng dẫn và mã sửa fallback khi không đọc được default value.

## Dump trên PC

1. Mở Liên Quân trên LDPlayer và vào sảnh.
2. Chạy Dump_Lib_And_Metadata.bat để lấy libil2cpp.so và global-metadata.dat đã giải mã.
3. Tải và giải nén Il2CppDumper_CLI_AOV.zip vào thư mục Il2CppDumper_CLI_AOV trong repo.
4. Chạy từ thư mục repo:

```bat
Il2CppDumper_CLI_AOV\dump.cmd "libil2cpp.so" "global-metadata.dat" "Dump"
```

Kết quả gồm DummyDll, dump.cs, il2cpp.h, script.json và stringliteral.json trong thư mục Dump.
DLL là stub để xem cấu trúc và địa chỉ; mã thực thi vẫn nằm trong libil2cpp.so.
Default value chưa giải được giữ dưới dạng MetadataOffset, không điền constant đoán.

Repo chỉ phân phối tool. Lib, metadata và dữ liệu dump được tạo tại máy, không được commit.
