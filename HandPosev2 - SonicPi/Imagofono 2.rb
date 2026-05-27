# =====================================================================
# CONFIGURACIÓN DE LA MATRIZ (16x4) Y VARIABLES GLOBALES
# =====================================================================

set :matriz, [
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # Línea 0: Drums
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # Línea 1: Claps
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # Línea 2: Synth
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]  # Línea 3: Bass
]

set :bpm, 120
set :linea_seleccionada, -1 # -1 = Ninguna línea activa para grabar
set :pasos_por_linea, [0, 0, 0, 0] # Rastrea el paso actual (0-15) de cada canal

# =====================================================================
# 1. MOTOR DEL SECUENCIADOR (Igual que antes, lee la matriz)
# =====================================================================
live_loop :motor_secuenciador do
  use_bpm get(:bpm)
  matriz_actual = get(:matriz)
  
  16.times do |paso|
    # Canal 0: Drums
    sample :bd_haus, amp: 1.2 if matriz_actual[0][paso] > 0
    
    # Canal 1: Claps
    sample :sn_generic, amp: 0.2 if matriz_actual[1][paso] > 0
    
    # Canal 2: Synth
    if matriz_actual[2][paso] > 0
      escala = scale(:c3, :minor_pentatonic, num_octaves: 3)
      synth :prophet, note: escala[matriz_actual[2][paso] % escala.length], release: 0.25, amp: 0.5
    end
    
    # Canal 3: Bass
    if matriz_actual[3][paso] > 0
      escala_b = scale(:c1, :minor_pentatonic, num_octaves: 2)
      synth :fm, note: escala_b[matriz_actual[3][paso] % escala_b.length], release: 0.2, amp: 0.7
    end
    
    sleep 0.25
  end
end

# =====================================================================
# 2. ESCUCHA OSC CENTRALIZADA (PROCESA COORDENADAS X e Y)
# =====================================================================
live_loop :procesador_escena3_osc do
  use_real_time
  datos = sync "/osc*/imaginofono/mano/3"
  
  posX  = datos[0]
  posY  = datos[1]
  matiz = datos[2]
  
  # -----------------------------------------------------------------
  # ZONA A: BOTONES INFERIORES (Y > 352)
  # -----------------------------------------------------------------
  if posY > 352
    boton_presionado = (posX / 160).to_i # Rango X (0-640) a botón 0, 1, 2 o 3
    linea_activa = get(:linea_seleccionada)
    
    if linea_activa == boton_presionado
      # SEGUNDO CLICK: Borrar la línea de la matriz
      matriz_actual = get(:matriz).dup
      matriz_actual[boton_presionado] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      set :matriz, matriz_actual
      
      # Resetear el contador de pasos para este canal
      pasos_actuales = get(:pasos_por_linea).dup
      pasos_actuales[boton_presionado] = 0
      set :pasos_por_linea, pasos_actuales
      
      set :linea_seleccionada, -1 # Deseleccionar canal
      print "🗑️ Canal #{boton_presionado} reseteado a silencio y deseleccionado."
      
      # 🎯 CUE DE BORRADO: Genera una señal visual clara en la ventana de Cues
      cue "/canal_#{boton_presionado}/borrado"
      
    else
      # PRIMER CLICK: Seleccionar línea para grabar y emitir sonido de referencia
      set :linea_seleccionada, boton_presionado
      print "🎵 Canal #{boton_presionado} seleccionado. Listo para grabar en el video."
      
      # 🎯 CUE DE SELECCIÓN/GRABACIÓN: Avisa que el canal entra en modo escucha
      cue "/canal_#{boton_presionado}/grabando"
      
      case boton_presionado
      when 0 then sample :bd_haus, rate: 1.5, amp: 0.5
      when 1 then sample :sn_generic, rate: 1.5, amp: 0.2
      when 2 then synth :prophet, note: :c4, release: 0.1, amp: 0.5
      when 3 then synth :fm, note: :c2, release: 0.1, amp: 0.4
      end
    end
    
    # -----------------------------------------------------------------
    # ZONA B: SLIDER LATERAL (X >= 540 e Y <= 352)
    # -----------------------------------------------------------------
  elsif posX >= 540 && posY <= 352
    nuevo_bpm = 60 + ((posY - 352) * (180 - 60) / (0 - 352)).to_i
    
    set :bpm, nuevo_bpm
    print "🎛️ Slider detectado -> BPM actualizado a: #{nuevo_bpm}"
    
    # -----------------------------------------------------------------
    # ZONA C: EL VIDEO (X < 540 e Y <= 352)
    # -----------------------------------------------------------------
  elsif posX < 540 && posY <= 352
    linea_activa = get(:linea_seleccionada)
    
    if linea_activa != -1
      pasos_actuales = get(:pasos_por_linea).dup
      paso_a_grabar = pasos_actuales[linea_activa]
      
      matriz_actual = get(:matriz).dup
      linea_editable = matriz_actual[linea_activa].dup
      
      linea_editable[paso_a_grabar] = matiz
      matriz_actual[linea_activa] = linea_editable
      
      set :matriz, matriz_actual
      
      print "📌 Grabado en Canal: #{linea_activa} | Paso: #{paso_a_grabar} | Matiz: #{matiz}"
      
      # 🎯 CUE DE PASO GRABADO: Avisa qué casillero específico de los 16 se acaba de llenar
      cue "/canal_#{linea_activa}/paso_#{paso_a_grabar}"
      
      # Avanzar el paso secuencialmente (0 al 15)
      pasos_actuales[linea_activa] = (paso_a_grabar + 1) % 16
      set :pasos_por_linea, pasos_actuales
    else
      print "⚠️ Clic en video ignorado: Debes seleccionar un botón inferior primero."
    end
  end
  
end