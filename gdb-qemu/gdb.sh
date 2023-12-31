#gdb -ex 'gef-remote localhost:1234'     -ex 'set architecture i8086'  -ex 'set tdesc filename target.xml'   -ex 'break *0x7c00'     -ex 'continue'
# gdb -ex 'target remote localhost:1234'     -ex 'set architecture i8086'  -ex 'set tdesc filename target.xml'   #-ex 'break *0x7c00'     -ex 'continue'

gdb -ix realmode.gdb \
        -ex 'set architecture i8086' \
        -ex 'set tdesc filename target.xml' \
        -ex 'target remote localhost:1234' \
        -ex 'break *0x7c00' \
        -ex 'continue'