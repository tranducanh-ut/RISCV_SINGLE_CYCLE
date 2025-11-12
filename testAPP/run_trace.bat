@echo off
setlocal ENABLEDELAYEDEXPANSION

:: ===== CONFIG =====
set "TXT_NAME=regtrace.txt"
set "BASE=%~dp0"
set "WORK=%BASE%sim_work"
if not exist "%WORK%" mkdir "%WORK%"

echo ================= RISC-V TRACE RUNNER =================
echo Nhap duong dan vivado.bat (vd: C:\Xilinx\Vivado\2024.2\bin\vivado.bat)
set /p VIVADO=vivado.bat: 
if not exist "%VIVADO%" (
  echo [ERR] Khong tim thay: "%VIVADO%"
  goto :HOLD
)

echo.
echo Nhap duong dan file .h (hex) (vd: C:\Users\...\mem.h)
set /p HEX=hex (.h): 
if not exist "%HEX%" (
  echo [ERR] Khong tim thay: "%HEX%"
  goto :HOLD
)

echo.
echo [1/4] Copy "%HEX%" -> "%WORK%\mem.h"
copy /Y "%HEX%" "%WORK%\mem.h" >nul || (echo [ERR] Copy vao sim_work that bai & goto :HOLD)

echo [2/4] Tao run_sim.tcl
> "%WORK%\run_sim.tcl" echo file delete -force xsim.dir .Xil
>>"%WORK%\run_sim.tcl" echo puts ">> xvlog ..."
>>"%WORK%\run_sim.tcl" echo exec xvlog --incr --relax ^
 ../riscv_top.v ^
 ../regfile.v ^
 ../mem.v ^
 ../alu.v ^
 ../brc.v ^
 ../controller.v ^
 ../ImmGen.v ^
 ../lsu.v ^
 ../tb_regtrace.v
>>"%WORK%\run_sim.tcl" echo puts ">> xelab ..."
>>"%WORK%\run_sim.tcl" echo exec xelab tb_regtrace -s tb_regtrace_sim
>>"%WORK%\run_sim.tcl" echo puts ">> xsim -R ..."
>>"%WORK%\run_sim.tcl" echo exec xsim tb_regtrace_sim -R --testplusarg LOGFILE=%TXT_NAME%
>>"%WORK%\run_sim.tcl" echo puts "Simulation DONE."

echo [3/4] Chay Vivado (batch)...
pushd "%WORK%"
"%VIVADO%" -mode batch -source run_sim.tcl
set "RC=!ERRORLEVEL!"
popd

echo.
echo [4/4] IN KET QUA LEN TERMINAL
:: ==== THU GOM & IN ====
set "TXT_BASE=%BASE%%TXT_NAME%"
set "TXT_WORK=%WORK%\%TXT_NAME%"

:: Nếu file ở sim_work thì chuyển về BASE
if exist "%TXT_WORK%" move /Y "%TXT_WORK%" "%TXT_BASE%" >nul

:: Chờ tối đa 10s để file xuất hiện (đề phòng xsim đóng file trễ)
for /l %%i in (1,1,20) do (
  if exist "%TXT_BASE%" goto :PRINT_OK
  if exist "%TXT_WORK%" move /Y "%TXT_WORK%" "%TXT_BASE%" >nul
  >nul ping -n 2 127.0.0.1
)

:: Không thấy file -> show chẩn đoán để biết vì sao chưa in
echo [WARN] Khong thay "%TXT_NAME%" sau khi mo phong.
echo.
echo ---- DIR (goc) ----
dir /b "%BASE%"
echo.
echo ---- DIR (sim_work) ----
dir /b "%WORK%"
echo.
echo ---- GREP xsim.log (dong LOG) ----
if exist "%WORK%\xsim.log" findstr /C:">>> LOG" "%WORK%\xsim.log"
echo.
echo ---- TAIL xsim.log ----
if exist "%WORK%\xsim.log" powershell -NoProfile -Command "Get-Content -Path '%WORK%\xsim.log' -Tail 40"
echo.
echo ---- vivado.log (cuoi) ----
if exist "%WORK%\vivado.log" powershell -NoProfile -Command "Get-Content -Path '%WORK%\vivado.log' -Tail 40"
goto :HOLD

:PRINT_OK
echo.
echo ================== TRACE OUTPUT (%TXT_NAME%) ==================
type "%TXT_BASE%"
echo ================= END OF OUTPUT ==================

:HOLD
echo.
set /p "=Nhan ENTER de thoat..." <nul
echo.
exit /b
