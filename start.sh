nasm -I include/ -o mbr.bin mbr.S
nasm -I include/ -o loader.bin loader.S

dd if=./mbr.bin of=./hd60M.img bs=512 count=1 seek=0 conv=notrunc
dd if=./loader.bin of=./hd60M.img bs=512 count=4 seek=2 conv=notrunc

rm -rf mbr.bin
rm -rf loader.bin

bochs -f ./bochsrc.disk -q
