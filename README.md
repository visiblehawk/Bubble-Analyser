# Bubble sizer

Image processing code for a bubble sizer device

Primero se corre el BV_calibration. 
Este codigo genera un archivo .mat con el parametro mm/pixeles.

Luego se corre BV_quantification.Ese es el codigo importante. 
Ese cdigo esta diseñado para correrse en bulk, leyendo muchas carpetas con fotos.

BSDphotoexample es una version que analiza una foto a la vez. 
Se elije el numero de foto en la linea 21 (j = identificacion de la foto a usar).
Al final muestra la foto original vs el resultado del analisis.