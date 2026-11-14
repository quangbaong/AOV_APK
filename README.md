# Dump Liên Quân Mobile — BaoNguyen

Tool GUI Windows x64, bản quyền hiển thị **BaoNguyen**. Runtime được tích hợp sẵn.

## Mở tool

Nhấp đúp [Start_Dumper.bat](Start_Dumper.bat), hoặc mở trực tiếp
[Il2CppDumper GUI.exe](Il2CppDumper_GUI/Il2CppDumper%20GUI.exe).
Nếu tải từ GitHub, tải ZIP của repo và giải nén trước khi mở tool.

## Dump trên PC

1. Mở Liên Quân trên LDPlayer và vào sảnh.
2. Chạy [Dump_Lib_And_Metadata.bat](Dump_Lib_And_Metadata.bat) để lấy lib và metadata đã giải mã.
3. Mở GUI, chọn libil2cpp.so, global-metadata.dat và thư mục đầu ra.
4. Bấm **Start Dump**.

Kết quả: DummyDll, dump.cs, il2cpp.h, script.json và stringliteral.json.
Giá trị mặc định chưa giải được giữ bằng MetadataOffset và được báo trong log.
DLL là stub để xem cấu trúc/địa chỉ; mã thực thi vẫn nằm trong libil2cpp.so.

[Mã sửa GUI và hướng dẫn build](GUI_PATCH/README.md).
Bản CLI vẫn có trong [Il2CppDumper_CLI_AOV.zip](Il2CppDumper_CLI_AOV.zip) nếu cần.
Repo chỉ chứa tool; không kèm lib, metadata hay dữ liệu dump của game.
