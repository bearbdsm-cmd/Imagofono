// Hand Pose Detection con ml5.js & Arquitectura de Escenas por Imágenes
let video;
let handPose;
let hands = [];
let hand_r;
let hand_l;
let pick_r = 0;
let pick_l = 0;
let socket;

// Control de Escenas (0 = Intro, 1 = Theremin, 2 = Barras de Color, 3 = Video 3, 4 = Video 4) 🎯
let message = 0; 

// Variables para rastrear posición previa y calcular velocidad
let prevLeftX = 0, prevLeftY = 0;
let prevRightX = 0, prevRightY = 0;
let velLeft = 0;
let velRight = 0;

// Partículas para los efectos visuales
let sistemaParticulas = [];

// Contenedores para los recursos de cada escena
let img0, img1, img2;
let video3, video4; // Contenedores de video 🎥
let recursoActivo;   // Reemplaza a imagenActiva (puede ser p5.Image o p5.MediaElement)

function preload() {
  handPose = ml5.handPose({ flipped: true });
  
  // Cargamos las imágenes fijas para las primeras escenas 🖼️
  img0 = loadImage('0.jpg'); 
  img1 = loadImage('1.jpg'); 
  img2 = loadImage('2.jpg'); 
}

function mousePressed() {
  //console.log(hands);
}

function gotHands(results) {
  hands = results;
}

function setup() {
  createCanvas(640, 480);
  
  // Webcam para HandPose
  video = createCapture(VIDEO, { flipped: true });
  video.hide();
  
  // Inicializamos los videos para los niveles 3 y 4 🎥
  video3 = createVideo(['3.mp4']);
  video3.hide();
  video4 = createVideo(['4.mp4']);
  video4.hide();
   
  handPose.detectStart(video, gotHands);

  socket = io('http://localhost:3333');
  socket.on('connect', () => {
    console.log("✅ Conectado al puente (Socket.io)");
  });

  // Definimos la escena inicial
  cambiarEscena(0);
}

function draw() {
  background(255);
  
  // 1. Dibujamos el fondo correspondiente al recurso activo (Imagen o Video en tiempo real)
  image(recursoActivo, 0, 0, width, height);

  // 2. Procesamos las manos y las partículas en cada frame
  hands_inter();
  hands_select();
  actualizarParticulas();

  // 3. Ejecutamos el renderizado de la interfaz de la escena actual
  escenas(message); 
}

// --- SISTEMA DE ENRUTAMIENTO DE ESCENAS ---
function escenas(msg) {
  if (msg === 0) escena0();
  if (msg === 1) escena1();
  if (msg === 2) escena2();
  if (msg === 3) escena3();
  if (msg === 4) escena4();
}

// --- CAMBIO DE ESCENA POR TECLADO ---
function keyPressed() {
  if (key === '0') cambiarEscena(0);
  if (key === '1') cambiarEscena(1);
  if (key === '2') cambiarEscena(2);
  if (key === '3') cambiarEscena(3);
  if (key === '4') cambiarEscena(4);
}

function cambiarEscena(numEscena) {
  message = numEscena;
  console.log("🎬 PERFORMANCE: Iniciando Sección " + numEscena);
  
  // Limpiamos rastro de partículas anterior
  sistemaParticulas = [];
  
  // DETENER VIDEOS: Pausamos ambos videos por defecto para que no consuman CPU en fondo
  video3.pause();
  video4.pause();
  
  // Asignamos el recurso activo y controlamos la reproducción de los videos 🔄
  if (numEscena === 0) {
    recursoActivo = img0;
  } else if (numEscena === 1) {
    recursoActivo = img1;
  } else if (numEscena === 2) {
    recursoActivo = img2;
  } else if (numEscena === 3) {
    recursoActivo = video3;
    video3.loop(); // Reproducción en bucle para el nivel 3
    video3.volume(0); // Mutear si solo quieres capturar color/movimiento sin interferencias
  } else if (numEscena === 4) {
    recursoActivo = video4;
    video4.loop(); // Reproducción en bucle para el nivel 4
    video4.volume(0);
  }
}

// --- COMPORTAMIENTOS VISUALES EXTRAS POR ESCENA ---
function escena0() {
  push();
  fill(255, 0, 255); noStroke(); textSize(16);
  text("SECCIÓN 0: INTRODUCCIÓN", 20, 35);
  pop();
}

function escena1() {
  push();
  fill(255, 255, 0); noStroke(); textSize(16);
  text("SECCIÓN 1: THEREMIN VIRTUAL", 20, 35);
  pop();
}

function escena2() {
  push();
  fill(0, 255, 0); noStroke(); textSize(16);
  text("SECCIÓN 2: INSTRUMENTO DE COLOR", 20, 35);
  pop();
}

function escena3() {
  push();
  fill(0, 255, 255); noStroke(); textSize(16);
  text("SECCIÓN 3: CONSTRUCTOR DE BEATS (VIDEO)", 20, 35);
  pop();
}

function escena4() {
  push();
  fill(255, 100, 0); noStroke(); textSize(16);
  text("SECCIÓN 4: PERFORMANCE DE VIDEO LÍQUIDO", 20, 35);
  pop();
}

// --- INTERPRETACIÓN DE MANOS Y MOVIMIENTO ---
function hands_inter() {
  if (hands.length > 0) {
    for (let hand of hands) {
      if (hand.confidence > 0.1) {
        let index = hand.index_finger_tip;
        let thumb = hand.thumb_tip;
        let d = dist(index.x, index.y, thumb.x, thumb.y)
        let keypoint = hand.keypoints[8];

        if (hand.handedness == "Left") {  
          hand_l = hand;
          velLeft = dist(keypoint.x, keypoint.y, prevLeftX, prevLeftY);
          prevLeftX = keypoint.x; prevLeftY = keypoint.y;
          pick_l = (d < 30) ? 1 : 0;
        } else {
          hand_r = hand;
          velRight = dist(keypoint.x, keypoint.y, prevRightX, prevRightY);
          prevRightX = keypoint.x; prevRightY = keypoint.y;
          pick_r = (d < 30) ? 1 : 0;
        }

        if (frameCount % 2 === 0) {
          let colChispa = (hand.handedness == "Left") ? color(255, 0, 255) : color(255, 255, 0);
          sistemaParticulas.push(new Particula(keypoint.x, keypoint.y, colChispa, "chispa"));
        }

        if (message === 1 && frameCount % 3 === 0) {
          let currentVel = (hand.handedness === "Left") ? velLeft : velRight;
          let pixBlanco = [255, 255, 255]; 
          enviarDatosOSC(keypoint.x, keypoint.y, pixBlanco, currentVel, hand.handedness, message);
        }
      }
    }
  }
}

function hands_select() {
  if (message === 1) return;

  // Forzamos límites para evitar que .get() tire error si la mano sale de la pantalla
  let posX_l = hand_l ? constrain(floor(hand_l.index_finger_tip.x), 0, width - 1) : 0;
  let posY_l = hand_l ? constrain(floor(hand_l.index_finger_tip.y), 0, height - 1) : 0;
  
  let posX_r = hand_r ? constrain(floor(hand_r.index_finger_tip.x), 0, width - 1) : 0;
  let posY_r = hand_r ? constrain(floor(hand_r.index_finger_tip.y), 0, height - 1) : 0;

  if (pick_l == 1 && hand_l) {
    // CAPTURA MÁGICA: Extrae el píxel del fotograma actual del VIDEO o de la IMAGEN activa 🎯
    let pix = recursoActivo.get(posX_l, posY_l);
    
    for(let i = 0; i < 25; i++) {
      sistemaParticulas.push(new Particula(posX_l, posY_l, color(pix[0], pix[1], pix[2]), "ember"));
    }

    if (frameCount % 10 === 0) { 
      enviarDatosOSC(posX_l, posY_l, pix, floor(velLeft), "Left", message);
    }
    pick_l = 0;
  }
  
  if (pick_r == 1 && hand_r) {
    let pix = recursoActivo.get(posX_r, posY_r);
    
    for(let i = 0; i < 25; i++) {
      sistemaParticulas.push(new Particula(posX_r, posY_r, color(pix[0], pix[1], pix[2]), "ember"));
    }

    if (frameCount % 10 === 0) {
      enviarDatosOSC(posX_r, posY_r, pix, floor(velRight), "Right", message);
    }
    pick_r = 0;
  }
}

function enviarDatosOSC(manoX, manoY, colorPixel, velocidad, manoLabel, msg) {
  if (socket && socket.connected) {
    let manoId = (manoLabel === 'Left') ? 0 : 1;
    let nombreMano = (manoLabel === 'Left') ? "IZQUIERDA 👈" : "DERECHA 👉";
    let Xmano = floor(manoX);
    let Ymano = floor(manoY);
    let vel = floor(velocidad);
    
    let c = color(colorPixel[0], colorPixel[1], colorPixel[2]);
    colorMode(HSB, 360, 100, 100);
    let matiz = floor(hue(c)); 
    colorMode(RGB, 255, 255, 255);

    let text = "/imaginofono/mano/" + msg;
    let paquete = {
      address: text,
      args: [Xmano, Ymano, matiz, vel, manoId]
    };

    socket.emit('message', paquete);
    
    console.log(
      `%c[OSC Sent] %cEscena: ${msg} | Mano: ${nombreMano} | Matiz(H): ${matiz} | Vel: ${vel}`, 
      "color: #00ff00; font-weight: bold;", 
      "color: #ffffff;"                     
    );
  }
}

function actualizarParticulas() {
  for (let i = sistemaParticulas.length - 1; i >= 0; i--) {
    let p = sistemaParticulas[i];
    p.update();
    p.display();
    if (p.isDead()) {
      sistemaParticulas.splice(i, 1);
    }
  }
}

// --- CLASE PARTÍCULA ---
class Particula {
  constructor(x, y, colorBase, tipo) {
    this.x = x; this.y = y; this.colorBase = colorBase; this.tipo = tipo;
    this.alpha = 255;  
    
    if (this.tipo === "chispa") {
      this.vx = random(-1, 1); this.vy = random(-0.5, 1);
      this.tam = random(4, 8); this.decaimiento = random(4, 8); 
    } else {
      let angulo = random(TWO_PI); let fuerza = random(2, 6);
      this.vx = cos(angulo) * fuerza; this.vy = sin(angulo) * fuerza;
      this.tam = random(6, 12); this.decaimiento = random(2, 5); 
    }
  }

  update() {
    this.x += this.vx; this.y += this.vy;
    if (this.tipo === "ember") { this.vy -= 0.1; this.tam *= 0.98; }
    this.alpha -= this.decaimiento;
  }

  display() {
    noStroke();
    fill(red(this.colorBase), green(this.colorBase), blue(this.colorBase), this.alpha);
    if (this.tipo === "chispa") {
      rectMode(CENTER); rect(this.x, this.y, this.tam, this.tam); rectMode(CORNER);
    } else {
      circle(this.x, this.y, this.tam);
    }
  }

  isDead() { return this.alpha <= 0; }
}