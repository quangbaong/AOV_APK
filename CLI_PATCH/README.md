# Portable CLI with default-value fallback

[Download the complete Windows x64 tool](../Il2CppDumper_CLI_AOV.zip), extract it, then run:

```bat
dump.cmd "C:\path\libil2cpp.so" "C:\path\global-metadata.dat" "C:\path\Dump"
```

The archive includes Il2CppDumper 6.7.46, the .NET 6.0.36 runtime, import scripts,
and the fallback patch source/helper. Inputs must already be decoded using the
repository capture script. It contains no game binaries, metadata or dump data.

The fallback catches failed default-value decoding and uses the exporter's existing
MetadataOffset annotation instead of inventing a constant. Method signatures,
RVA/Offset annotations and type layouts can still be inspected in DummyDll.
Consumers must inspect those annotations when default values matter.

Validation: this exact patched assembly exported 88 DLLs from the local Android
capture; all were read back with Mono.Cecil. The launcher usage path and archive
contents were checked. The 88-DLL result is input-specific, not a fixed guarantee.

To reproduce the tool patch, compile PatchDefaultFallback.cs with the framework
C# compiler and a Mono.Cecil reference, then pass the original managed
Il2CppDumper.dll and an output DLL path to PatchDefaultFallback.exe. Replace only
the tool DLL, not the input game files. Keep the adjacent deps/runtimeconfig files.
