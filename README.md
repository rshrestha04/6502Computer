# 6502Computer
6502Computer.s is the most recent complete file. I have used the vasm compiler for the project:

Here is how to set up the 6502 monitor: 

connect the computer with the 6502 monitor. 

Type the following commands in the terminal:

1) vasm6502_oldstyle -dotdir -Fbin -wdc02  6502monitor
2) dd if=a.out of=rom.bin bs=1 count=32768 skip=32768
3) minipro -p AT28C256 -w rom.bin                        ; insert the 6502 into the EPROM then enter this command to copy the code into the 6502 chip
4) picocom --b 19200 /dev/ttyUSB0                        ; insert the 6502 chip back to the breadboard
5) You can now use the commands 
