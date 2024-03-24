@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "E:\Ionin\EU\Seminar_4\template\labels.tmp" -fI -W+ie -C V2E -o "E:\Ionin\EU\Seminar_4\template\template.hex" -d "E:\Ionin\EU\Seminar_4\template\template.obj" -e "E:\Ionin\EU\Seminar_4\template\template.eep" -m "E:\Ionin\EU\Seminar_4\template\template.map" "E:\Ionin\EU\Seminar_4\template\template.asm"
