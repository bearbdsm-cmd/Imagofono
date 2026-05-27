# =====================================================================
# 3. ESCUCHA OSC - ESCENA 4 (Controlador por Cuadrantes + Efectos)
# =====================================================================
live_loop :procesador_escena4_osc do
  use_real_time
  datos = sync "/osc*/imaginofono/mano/4"
  posX, posY, matiz = datos[0], datos[1], datos[2]
  
  # Ruta a tu carpeta (Guardada de forma nativa para que no falle)
  ruta_carpeta = "/Users/ozz/Documents/HandPosev2/sonidos"
  
  # -----------------------------------------------------------------
  # ESCENA 4 - ZONA A: BOTONES INFERIORES (Y > 352) -> Cambian FX
  # -----------------------------------------------------------------
  if posY > 352
    fx_elegido = (posX / 160).to_i # Botón 0, 1, 2 o 3
    set :efecto_activo, fx_elegido
    print "🎛️ FX Cambiado a modo: #{fx_elegido}"
    
    synth :chipbass, note: :c5, release: 0.05, amp: 0.2
    cue "/fx/cambiado_a_#{fx_elegido}"
    
    # -----------------------------------------------------------------
    # ESCENA 4 - ZONA B: SLIDER LATERAL (X >= 540 e Y <= 352) -> Cambia Rate
    # -----------------------------------------------------------------
  elsif posX >= 540 && posY <= 352
    nueva_velocidad = 0.5 + ((posY - 352) * (2.0 - 0.5) / (0 - 352)).to_f
    set :rate_sample, nueva_velocidad
    print "🎛️ Slider Escena 4 -> Rate de Sample: #{nueva_velocidad}"
    
    # -----------------------------------------------------------------
    # ESCENA 4 - ZONA C: EL VIDEO EN 4 CUADRANTES (X < 540 e Y <= 352)
    # -----------------------------------------------------------------
  elsif posX < 540 && posY <= 352
    
    # Mitad horizontal = 270 | Mitad vertical = 176
    cuadrante = 1
    if posX <= 270 && posY <= 176
      cuadrante = 1 # Sup. Izquierdo
    elsif posX > 270 && posY <= 176
      cuadrante = 2 # Sup. Derecho
    elsif posX <= 270 && posY > 176
      cuadrante = 3 # Inf. Izquierdo
    elsif posX > 270 && posY > 176
      cuadrante = 4 # Inf. Derecho
    end
    
    # 🔍 SOLUCIÓN CRÍTICA: Leemos los archivos usando comandos del sistema operativo (Dir.glob)
    # Buscamos todos los archivos en tu ruta que comiencen con el número del cuadrante (ej: 1-*.wav)
    patron_busqueda = "#{ruta_carpeta}/#{cuadrante}-*.wav"
    audios_cuadrante = Dir.glob(patron_busqueda)
    
    if audios_cuadrante.length > 0
      # Elegimos uno de los archivos completos al azar de la lista
      archivo_completo = audios_cuadrante.choose
      
      # Extraemos el nombre limpio (el archivo final con su extensión) para el log
      nombre_limpio = File.basename(archivo_completo)
      
      fx = get(:efecto_activo)
      vel = get(:rate_sample)
      
      print "💥 Cuadrante: #{cuadrante} | Audio: #{nombre_limpio} | FX: #{fx} | Rate: #{vel}"
      cue "/cuadrante_#{cuadrante}/disparado"
      
      # Bloque de efectos dinámicos aplicando la ruta absoluta directa
      case fx
      when 1
        # 🤖 EFECTO 1: TRANSFORMA-HUMANOS (Ring Modulator + Modulación de Tono)
        # Sintoniza el audio en una frecuencia metálica fija. Ideal para que cualquier
        # voz o golpe suene como un androide de película de los 80.
        with_fx :ring_mod, freq: 45, mod_amp: 1 do
          with_fx :pitch_shift, pitch: -5, window_size: 0.01 do # Modula el tono hacia abajo para darle peso
            sample archivo_completo, rate: vel, amp: 1.4
          end
        end
        
      when 2
        # 🛸 EFECTO 2: AGUJERO DE GUSANO (Reversa Psicoacústica + Flanger Líquido)
        # Invierte el sentido del sample en vivo y le añade un efecto de barrido espacial flotante.
        # Genera una transición brutal y muy texturada.
        with_fx :flanger, phase: 0.5, wave: 3, feedback: 0.6, mix: 0.7 do
          # Le decimos 'rate: -1' multiplicado por tu variable 'vel' para que se reproduzca hacia atrás.
          sample archivo_completo, rate: (vel * -1), amp: 1.3
        end
        
      when 3
        # 🎸 EFECTO 3: DESTRUCTOR INDUSTRIAL (Bitcrusher + Distorsión de Tubo)
        # Convierte el sample en algo agresivo, roto, digitalizado y con mucho peso.
        with_fx :bitcrusher, bits: 5, sample_rate: 8000, mix: 0.6 do
          with_fx :krush, gain: 4, cutoff: 100, mix: 0.5 do # Distorsión agresiva
            sample archivo_completo, rate: vel, amp: 0.9 # Bajamos amp para que no sature tu salida
          end
        end
      else # Botón 0: SONIDO LIMPIO
        sample archivo_completo, rate: vel, amp: 1.2
      end
    else
      print "⚠️ No se encontraron archivos que coincidan con '#{cuadrante}-*.wav' en tu carpeta."
    end
    
  end
end