# Il2CppDumper GUI — BaoNguyen

Copyright © 2026 BaoNguyen (AOV customization and distribution).

Open Il2CppDumper GUI.exe directly. The Windows x64 runtime is bundled; no separate
.NET installation or terminal command is needed. Keep config.json and the import
scripts next to the executable.

Select the decoded libil2cpp.so, metadata file and output folder, then Start Dump.
The AOV metadata header can also be decoded by the GUI automatically. Encrypted
code sections still need to be captured from the running game first.

The GUI retains MetadataOffset annotations for malformed default-value blobs and
reports the unresolved count in the log. Values are not guessed. DummyDll files
are inspection stubs; native code remains in libil2cpp.so.

Upstream credits retained: Perfare (Il2CppDumper), AndnixSH (GUI), djkaty, T5ive.
https://github.com/Perfare/Il2CppDumper
https://github.com/AndnixSH/Il2CppDumper-GUI
AOV source base: https://github.com/quangbaong/Il2CppDumper_GUI_AOV
See ../Source for the complete project; run ../build.cmd to build the EXE.
