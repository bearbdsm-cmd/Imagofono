
# =====================================================================
#   SECCIÓN 1: EL THEREMIN VIRTUAL
# =====================================================================
live_loop :receptor_theremin do
  use_real_time
  x, y, matiz, vel, mano_id = sync "/osc*/imaginofono/mano/1"
  
  set :escena_actual, 1
  
  if !get[:theremin_nodo].nil?
    kill get[:theremin_nodo]
    set :theremin_nodo, nil
  end
  
  vol_theremin = get[:theremin_vol_global] || 0.7
  pan_actual = get[:paneo_actual] || 0.0
  
  if mano_id == 1
    # --- MANO DERECHA: TONO DULCE (Rango calibrado de 35 a 65 para evitar chillidos) ---
    nota_base = 35 + (x / 440.0) * 30
    vibrato_humano = Math.sin(vt * 40) * 0.25
    nota_final = nota_base + vibrato_humano
    
    use_synth :sine
    play nota_final,
      attack: 0.05,
      release: 1.2,       # CORREGIDO: Bajamos el release para que las notas no se amontonen masivamente
      amp: vol_theremin * 0.35, # CORREGIDO: Volumen atenuado manualmente para proteger tus parlantes 🛠️
      pan: 0.5
    
    print "👉 THEREMIN DER (Nota segura):", nota_final, "Amp:", vol_theremin * 0.35
    
  else
    # --- MANO IZQUIERDA: CALIBRACIÓN DE VOLUMEN ---
    nuevo_vol = (y / 400.0)
    nuevo_vol = [[nuevo_vol, 1.0].min, 0.0].max
    
    set :theremin_vol_global, nuevo_vol
    
    use_synth :tri
    play 38, attack: 0.01, release: 0.1, amp: nuevo_vol * 0.15, pan: -0.5
    
    print "👈 THEREMIN IZQ (Volumen por Y):", nuevo_vol
  end
end

# =====================================================================
#   SECCIÓN 2: INSTRUMENTO DE COLOR
# =====================================================================
live_loop :intro_imaginofono do
  use_real_time
  x, y, matiz, vel, mano_id = sync "/osc*/imaginofono/mano/2"
  
  set :escena_actual, 2
  if !get[:theremin_nodo].nil?
    kill get[:theremin_nodo]
    set :theremin_nodo, nil
  end
  
  escala = scale(:e2, :minor_pentatonic, num_octaves: 4)
  indice = line(0, 360, steps: escala.length)[matiz]
  nota_musical = escala[indice]
  tiempo_release = vel > 10 ? 3 : 0.2
  
  if mano_id == 1
    use_synth :tb303
    play nota_musical, attack: 0.1, release: tiempo_release, amp: 0.5, pan: 0
  else
    use_synth :gabberkick
    play nota_musical, attack: 0.1, release: tiempo_release, cutoff: 100, amp: 0.5, pan: 0
  end
end

