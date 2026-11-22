# Recursos del círculo VII

Imágenes creadas mediante la herramienta integrada de generación de imágenes.
Son recursos del juego, no referencias descargadas de otro título.

## violencia_mapa.png

Prompt de producción: mapa de fondo 2D cenital, paisaje 3:2, grabado oscuro inspirado
 en Gustave Doré; monocromo con acento carmesí #7A0C1C. Tres terrazas horizontales:
 río de sangre abajo con puente de piedra ancho en el centro y patio de entrada;
 bosque de árboles petrificados a los bordes de una explanada central despejada;
 arena de ceniza arriba con fisuras periféricas, cuatro pilares y puerta gótica al norte.
 Escaleras centrales anchas y transitables. Sin texto, interfaz, personajes ni jefe.

Se utiliza a escala 1.5 en un mundo de 2304 x 1536. El suelo y las colisiones se
programaron después en violencia_geometry.gd para corresponder con esta imagen.

## minotauro.png

Prompt de producción: un Minotauro completo sobre fondo realmente transparente,
 visto desde un frente ligeramente elevado, orientado hacia el espectador; cuernos
 grandes, torso poderoso, grebas antiguas, tela carmesí y hacha de piedra mellada.
 Grabado monocromo de trazo fino, silueta legible, sin heridas gráficas, texto, fondo,
 suelo ni personajes repetidos. Estética de grabado de Gustave Doré.

Es una ilustración estática, no una hoja de animaciones. Su estado se comunica mediante
movimiento, inclinación, modulación, líneas de aviso, sombra y señales de aturdimiento.

## Audio

violencia_ambiente.wav: ambiente original sintetizado de 16 segundos con graves,
capas de ruido filtrado y pulsos de percusión; importado con reproducción en bucle.

sello, error, carga, choque, impacto, golpe, verso, herida y esquiva: efectos cortos
originales sintetizados, 22050 Hz, mono, PCM de 16 bits. Sin descargas ni licencias
adicionales de música externa.


## Revisión animada
Se añadieron minotauro_frente_espalda.png y minotauro_lados.png: cuatro columnas
(reposo, paso izquierdo, paso derecho, ataque) por dos filas (orientaciones).
Movimiento de Dante: assets/dante/movimiento_completo.png, cuadrícula 4x4.
Almas y Virgilio: almas_virgilio.png, reconstruidos desde limbo_master.png.
La biblioteca sprite_library.gd normaliza los fotogramas y conserva transparencia.
Estas derivaciones se generaron con la herramienta integrada de imágenes usando
las ilustraciones existentes como referencias.
