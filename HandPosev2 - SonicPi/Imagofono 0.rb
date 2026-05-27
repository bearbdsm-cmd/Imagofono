# =====================================================================
#   IMAGINÓFONO - PERFORMANCE COMPLETA (CORREGIDO CONTRA FROZEN ERROR)
# =====================================================================
use_debug false
use_cue_logging false

use_osc "localhost", 4560

# --- INICIALIZACIÓN DE VARIABLES DE MEMORIA ---
set :escena_actual, 0
set :paneo_actual, 0.0
set :theremin_nodo, nil

# Inicializamos el secuenciador
set :bombo,   [0, 0, 0, 0]
set :clap,    [0, 0, 0, 0]
set :platillo, [0, 0, 0, 0]
set :sintetizador,   [0, 0, 0, 0]

# =====================================================================
#   ESCENA 0: DISPARADOR GEOMÉTRICO CON FX Y PANEO (DOS MANOS)
# =====================================================================

# Inicializamos los faders de la mano izquierda por seguridad
set :paneo_actual, 0.0
set :reverb_actual, 0.2

live_loop :intro_performance do
  use_real_time
  x, y, matiz, vel, mano_id = sync "/osc*/imaginofono/mano/0"
  
  set :escena_actual, 0
  if !get[:theremin_nodo].nil?; kill get[:theremin_nodo]; set :theremin_nodo, nil; end
  
  # ===================================================================
  #  1. MODO CONTROLADOR: LA MANO IZQUIERDA MODULA LOS EFECTOS 🎛️
  # ===================================================================
  if mano_id == 0
    # Eje X: Controla el Paneo (-1.0 Izquierda a 1.0 Derecha)
    pan_calculado = (x / 500.0) - 1.0
    set :paneo_actual, pan_calculado
    
    # Eje Y: Controla el Mix de la Reverb (Arriba = Seco, Abajo = Eco gigante)
    reverb_calculada = (y / 480.0) * 0.85
    set :reverb_actual, reverb_calculada
    
    print "👈 MANO IZQ ACTUALIZA EFECTOS -> Paneo:", pan_calculado, "Mix Reverb:", reverb_calculada
    
    # ===================================================================
    #  2. MODO DISPARADOR: LA MANO DERECHA TOCA LAS GEOMETRÍAS 🎯
    # ===================================================================
  else
    
    # Recuperamos el estado actual del espacio dictado por la mano izquierda
    pan_actual = get[:paneo_actual] || 0.0
    mix_reverb = get[:reverb_actual] || 0.2
    
    # Tratamiento de velocidad
    vel_cruda = vel / 40.0
    vel_normalizada = [[vel_cruda, 1.5].min, 0.1].max
    tiempo_release  = vel > 10 ? 2.0 : 0.3
    fuerza_ataque   = vel > 10 ? 0.005 : 0.05
    
    # Envolvemos toda la salida en una Reverb controlada por la mano izquierda
    with_fx :reverb, mix: mix_reverb, room: 0.8 do
      
      # --- 1. CUADRADO MAGENTA ---
      if matiz > 280 && matiz <= 330
        use_synth :dsaw
        nota_industrial = 40 + ((150 - y) / 10.0)
        desafinacion = (x / 200.0) * 0.5
        factor_saturacion = vel > 15 ? 0.8 : 0.1
        
        with_fx :distortion, mix: factor_saturacion, distort: 0.5 do
          play nota_industrial, attack: fuerza_ataque, release: tiempo_release, detune: desafinacion, cutoff: 85, amp: 0.7, pan: pan_actual
        end
        print "🟩 CUADRADO MAGENTA -> Pan Activo:", pan_actual
        
        # --- 2. TRIÁNGULO CYAN ---
      elsif matiz > 160 && matiz <= 200
        use_synth :fm
        nota_cristal = 55 + (x / 640.0) * 25
        timbre_metal = (1 + ((150 - y) / 120.0)).to_i
        profundidad_fm = vel_normalizada * 5
        
        play nota_cristal, attack: fuerza_ataque, decay: 0.1, sustain: 0.05, release: tiempo_release * 1.2, divisor: timbre_metal, depth: profundidad_fm, amp: 0.6, pan: pan_actual
        print "🔺 TRIÁNGULO CYAN -> Pan Activo:", pan_actual
        
        # --- 3. CÍRCULO AMARILLO ---
      elsif matiz > 40 && matiz <= 90
        use_synth :tb303
        nota_circulo = 38 + (x / 640.0) * 36
        filtro_cutoff = 50 + ((480 - y) / 480.0) * 60
        resonancia_gomosa = 0.4 + ((480 - y) / 480.0) * 0.55
        
        play nota_circulo, attack: fuerza_ataque, release: tiempo_release * 0.7, cutoff: filtro_cutoff, res: resonancia_gomosa, wave: 1, pulse_width: 0.5, env_curve: 2, amp: (vel > 10 ? 0.85 : 0.55), pan: pan_actual
        print "🟡 CÍRCULO AMARILLO -> Pan Activo:", pan_actual
      end
      
    end # Fin Reverb
  end # Fin Condición Mano Derecha
end