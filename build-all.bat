@echo off
REM Remove all directories in server/public except .gitkeep
echo Removing directories in server\public...
for /D %%i in (server\public\*) do (
    echo Checking directory %%i
    if /I not "%%~nxi" == ".gitkeep" (
        echo Removing directory %%i
        rd /s /q "%%i"
    )
)
REM Remove all files in server/public except .gitkeep
echo Removing files in server\public...
for %%i in (server\public\*) do (
    echo Checking file %%i
    if /I not "%%~nxi" == ".gitkeep" (
        echo Removing file %%i
        del /q "%%i"
    )
)
REM Build client
cd client
call C:\Users\Sara\git\flutter\bin\flutter build web --no-tree-shake-icons
if %ERRORLEVEL% neq 0 (
    echo Flutter build failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)
cd ..
REM Copy client/build/web/* to server/public/
echo Copying client\build\web\* to server\public\
xcopy client\build\web\* server\public\ /s /e /y
REM Copy client/assets to server/public/
echo Copying client\assets to server\public\assets
xcopy client\assets server\public\assets /s /e /y
REM Remove all directories in build except .gitkeep
echo Removing directories in build...
for /D %%i in (build\*) do (
    echo Checking directory %%i
    if /I not "%%~nxi" == ".gitkeep" (
        echo Removing directory %%i
        rd /s /q "%%i"
    )
)
REM Remove all files in build except .gitkeep
echo Removing files in build...
for %%i in (build\*) do (
    echo Checking file %%i
    if /I not "%%~nxi" == ".gitkeep" (
        echo Removing file %%i
        del /q "%%i"
    )
)
REM Change directory to server
echo Changing directory to server
cd server
REM Build the server using Cargo in WSL
echo Building server using Cargo in WSL...
wsl -u sara /home/sara/.cargo/bin/cargo build --release
REM Copy target/release/server to ../build
echo Copying target\release\server to ..\build
xcopy target\release\server ..\build /y
REM Copy public to ../build
echo Creating directory ..\build\public
mkdir ..\build\public
echo Copying public to ..\build\public
xcopy public ..\build\public\ /s /e /y
cd ..
echo Done.