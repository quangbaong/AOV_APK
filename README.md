# Il2CppDumper GUI — BaoNguyen

## Chạy bản có sẵn

Mở **Start_Dumper.bat** hoặc **Il2CppDumper_GUI\Il2CppDumper GUI.exe**.
Runtime đã tích hợp, không cần cài .NET để chạy GUI.

## Cấu trúc

- **Source/**: project đầy đủ để build EXE, mở Source\Il2CppDumper.sln trong Visual Studio.
- **Il2CppDumper_GUI/**: GUI chạy sẵn, config và các script import đi kèm.
- **build.cmd**: build source bằng .NET 8 SDK, xuất vào Il2CppDumper_GUI.
- **Dump_Lib_And_Metadata.bat**: lấy lib và metadata đã giải mã từ LDPlayer.
- **Dump_GameGuardian.sh**: script lấy dữ liệu trên Android/GameGuardian.

## Dump

1. Mở game vào sảnh, chạy Dump_Lib_And_Metadata.bat.
2. Mở GUI, chọn libil2cpp.so, global-metadata.dat và thư mục đầu ra.
3. Bấm Start Dump để xuất DummyDll và các file dump.

Các default value chưa giải được giữ bằng MetadataOffset và được báo trong log.
DLL là stub để xem cấu trúc/địa chỉ. Repo không chứa dữ liệu game hoặc kết quả dump.
Bản quyền phần tùy biến: BaoNguyen. Credits và giấy phép nguồn mở nằm trong GUI/Source.
