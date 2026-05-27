// Hand Pose Detection with ml5.js
// https://thecodingtrain.com/tracks/ml5js-beginners-guide/ml5/hand-pose

let video;
let handPose;
let hands = [];
let hand_r;
let hand_l;
let pick_r = 0;
let pick_l = 0;
let socket;

function preload() {
  // Initialize HandPose model with flipped video input
  handPose = ml5.handPose({ flipped: true });
}

function mousePressed() {
  console.log(hands);
}

function gotHands(results) {
  hands = results;
}

function setup() {
  createCanvas(640, 480);
  video = createCapture(VIDEO, { flipped: true });
  video.hide();
  img = loadImage('prueba2.jpg');

  
  // Start detecting hands
  handPose.detectStart(video, gotHands);

  socket = io('http://localhost:3333');
  socket.on('connect', () => {
    console.log("✅ Conectado al puente (Socket.io)");
  });}

function draw() {
  background(255);
  //image(video, 0, 0);
  image(img, 0, 0);
  //circle(300,100,100);
  hands_inter();
  hands_select();
}

function hands_inter(){
  // Ensure at least one hand is detected
  if (hands.length > 0) {
    for (let hand of hands) {
      if (hand.confidence > 0.1) {
        // Loop through keypoints and draw circles            
        index=hand.index_finger_tip;
        thumb=hand.thumb_tip;
        let d = dist(index.x,index.y,thumb.x, thumb.y)
        let keypoint = hand.keypoints[8];
        // Color-code based on left or right hand
        if (hand.handedness == "Left")
        {  
          hand_l=hand;
          fill(255, 0, 255);
          let d = dist(index.x,index.y,thumb.x, thumb.y)
          if (d<30)
          {
            pick_l = 1;
            fill(255, 255, 255);
          }
          else
          {
            pick_l = 0;
          }
        }
        else
        {
          hand_r=hand;
          fill(255, 255, 0);
          stroke(100);
          if (d<30)
          {
            pick_r= 1; 
            fill(0, 0, 0);
          }
          else
          {
            pick_r=0;
          }
        }
        noStroke();
        circle(keypoint.x, keypoint.y, 16);
      }
    }
  }
  
}

function hands_select()
{
  if(pick_l==1)
  {
    index=hand_l.index_finger_tip;
    thumb=hand_l.thumb_tip;
    let pix = img.get(index.x,index.y);
    stroke(100);
    fill(pix[0],pix[1], pix[2]);
    circle(index.x,index.y,50);
    if (frameCount % 20 === 0)
    {
        enviarDatosOSC(pix[0], pix[1], pix[2],"Left");
        console.log(`red: ${pix[0]}, green: ${pix[1]}, blue: ${pix[2]}, alpha: ${pix[3]}`);
    }
    
  // array
        pick_l = 0;

    
  }
  if(pick_r==1)
  {
    index=hand_r.index_finger_tip;
    thumb=hand_r.thumb_tip;
    let pix = img.get(index.x,index.y);
    fill(pix[0],pix[1], pix[2]);
    circle(index.x,index.y,40);
    if (frameCount % 20 === 0)
    {
        enviarDatosOSC(pix[0], pix[1], pix[2],"Right");
        console.log(`red: ${pix[0]}, green: ${pix[1]}, blue: ${pix[2]}}`);
    }
    

  console.log(`red: ${pix[0]}, green: ${pix[1]}, blue: ${pix[2]}`);
    pick_r = 0;

  }

}

function enviarDatosOSC(r, g, b, manoLabel) {
  if (socket && socket.connected) {
    let manoId = (manoLabel === 'Left') ? 0 : 1;
    let nombreMano = (manoLabel === 'Left') ? "IZQUIERDA 👈" : "DERECHA 👉";
    
    let paquete = {
      address: '/imaginofono/mano',
      args: [
        floor(r), 
        floor(g), 
        floor(b), 
        manoId
      ]
    };

    // Enviar el paquete al puente Node
    socket.emit('message', paquete);

    // Texto en consola para monitoreo
    // Usamos %c para darle un poco de color a la consola y que sea fácil de leer
    console.log(
      `%c[OSC Sent] %cMano: ${nombreMano} | RGBA: (${floor(r)}, ${floor(g)}, ${floor(b)})`, 
      "color: #00ff00; font-weight: bold;", // Estilo para [OSC Sent] en verde
      "color: #ffffff;"                     // Estilo para los datos en blanco
    );
  } else {
    // Esto te avisará si el bridge se cae mientras la app corre
    console.warn("⚠️ Intento de envío fallido: Socket no conectado.");
  }
}