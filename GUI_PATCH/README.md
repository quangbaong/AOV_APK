# BaoNguyen GUI build

Base source: https://github.com/quangbaong/Il2CppDumper_GUI_AOV
Base commit: 835d723cf1383bfa363fe63cbbd7eb4cbf4cc5d9

Apply changes.patch in that checkout, then publish with .NET SDK 8.0.428:

```powershell
dotnet publish Il2CppDumper/Il2CppDumper.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeAllContentForSelfExtract=true -p:EnableCompressionInSingleFile=true -p:PackageVersion=3.0.3 -o publish
```

Changes: BaoNguyen branding in window/About/EXE metadata, malformed default-value
fallback preserving MetadataOffset, and a GUI log summary of unresolved values.
Original upstream credits remain in About and the distribution README/license.

Validation: GUI XAML initialized and its actual Init/Dump methods ran against the
Android lib captured from LD and the original obfuscated metadata. It generated
88 DLLs; all were read back with Mono.Cecil (34,373 types, 268,741 methods).
The test ran without displaying a window. Published EXE copyright and company
metadata were verified as BaoNguyen. Generated game data is not included here.
