@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "D:\SM11-61\Lab4_Sys\lab4\labels.tmp" -fI -W+ie -C V2E -o "D:\SM11-61\Lab4_Sys\lab4\lab4.hex" -d "D:\SM11-61\Lab4_Sys\lab4\lab4.obj" -e "D:\SM11-61\Lab4_Sys\lab4\lab4.eep" -m "D:\SM11-61\Lab4_Sys\lab4\lab4.map" "D:\SM11-61\Lab4_Sys\lab4\lab4.asm"
