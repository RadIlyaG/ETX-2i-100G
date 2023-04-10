## from https://forums.intel.com/s/question/0D50P00003yyGH4SAM/quartus-ii-programmer-command-line?language=en_US
C:\altera\13.0sp1\qprogrammer\bin>quartus_pgm -c usb-blaster -m JTAG -o p;C:\altera\13.0sp1\qprogrammer\common\devinfo\programmer\sfl_ep3c55.sof 

## from https://forums.intel.com/s/question/0D50P00003yySHtSAM/programm-fpga-without-running-the-programmer?language=en_US
%QUARTUS_ROOTDIR%\\bin64\\quartus_pgm.exe -m jtag -c USB-Blaster -o pvbi;output_file.jic

## from https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/tclscriptrefmnl.pdf
-o pvb;file.pof

## from https://stackoverflow.com/questions/23358774/quartus-programmer-ii-tcl-flash-pof-file
quartus_pgm --cable="USB-Blaster [USB-0]" --mode=AS --option="p;C:\folder\Quartus\file.pof"