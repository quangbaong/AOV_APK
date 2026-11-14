@echo off
setlocal
where dotnet >nul 2>nul
if errorlevel 1 (
  echo Install the .NET 8 SDK, then run build.cmd again.
  exit /b 1
)
dotnet publish "%~dp0Source\Il2CppDumper\Il2CppDumper.csproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeAllContentForSelfExtract=true -p:EnableCompressionInSingleFile=true -p:PackageVersion=3.0.3 -o "%~dp0Il2CppDumper_GUI"
exit /b %ERRORLEVEL%
