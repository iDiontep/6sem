@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "E:\lab1\lab1\labels.tmp" -fI -W+ie -C V2E -o "E:\lab1\lab1\lab1.hex" -d "E:\lab1\lab1\lab1.obj" -e "E:\lab1\lab1\lab1.eep" -m "E:\lab1\lab1\lab1.map" "E:\lab1\lab1\lab1.asm"
