int cols, rows;
float[][] z;
float domainMin = -3, domainMax = 7;
int gridSize = 150;  // Grid subdivisions
float minZ = Float.MAX_VALUE;
float maxZ = -Float.MAX_VALUE;

// ======================= FUNCIONES DE CONVERSIÓN ============================
 
float screenToCartesianX(float sx) {
  return map(sx, 0, width, -3, 7);
}
float screenToCartesianY(float sy) {
  return map(sy, 0, height, 7, -3);
}

float cartesianToScreenX(float x) {
  return map(x, -3, 7, 0, width);
}

float cartesianToScreenY(float y) {
  return map(y, -3, 7, height, 0);
}

// ========================= PARTICULA ====================================
PImage surf; // imagen que entrega el fitness
int puntos = 100; // Cantidad de particulas se
Particle[] fl; // arreglo de partículas
float d = 15; // radio del círculo, solo para despliegue
float gbestx, gbesty, gbest; // posición y fitness del mejor global
float w = 1000; // inercia: baja (~50): explotación, alta (~5000): exploración (2000 ok)
float C1 = 30, C2 =  100; // learning factors (C1: own, C2: social) (ok)
int evals = 0, evals_to_best = 0; //número de evaluaciones, sólo para despliegue
float maxv = 3; // max velocidad (modulo)
int altura = 300; int ancho = 300;
// OBS:
// cartesianToScreenX 7 -> 1000
// cartesianToScreenX -3 -> 0
// cartesianToScreenY 7 -> 0
// cartesianToScreenY -3 -> 700

class Particle{
  float x, y, fit; // current position(x-vector)  and fitness (x-fitness)
  float px, py, pfit; // position (p-vector) and fitness (p-fitness) of best solution found by particle so far
  float vx, vy; //vector de avance (v-vector)
  
  // ---------------------------- Constructor
  Particle(){
    // Escogemos un valor aleatorio dentro del dominio ]-3,7[, le restamos algo minimo a -3 ya que random(A,B) incluye a A y excluye a B
    float cartX = random(domainMin + 0.01 , domainMax); float cartY = random(domainMin + 0.01, domainMax);
    
    // Lo transformamos para que sea visible (coherentemente) en pantalla
    x = cartesianToScreenX(cartX); y = cartesianToScreenX(cartY);
    // Hacemos que se mantengan dentro de la ventana
    x = constrain(x, -ancho, ancho); y = constrain(y, -altura, altura);

    vx = random(-1,1) ; vy = random(-1,1);
    pfit = Float.POSITIVE_INFINITY; fit = Float.POSITIVE_INFINITY; // Ya que buscamos MINIMIZAR
  }
  
  // ---------------------------- Evalúa partícula
  float Eval(){ //recibe imagen que define función de fitness
    evals++;
    fit = rastrigin(screenToCartesianX(x), screenToCartesianY(y)); // Buscamos el mejor valor
    if(fit < pfit){ // actualiza local best si es mejor
      pfit = fit;
      px = x;
      py = y;
    }
    if (fit < gbest){ // actualiza global best
      gbest = fit;
      gbestx = x;
      gbesty = y;
      evals_to_best = evals;
      // println(str(gbest));
    };
    return fit; //retorna 
  }
  
  // ------------------------------ mueve la partícula
  void move(){
    //actualiza velocidad (fórmula con factores de aprendizaje C1 y C2)
    //vx = vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    //vy = vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);
    //actualiza velocidad (fórmula con inercia, p.250)
    vx = w * vx + random(0,1)*(px - x) + random(0,1)*(gbestx - x);
    vy = w * vy + random(0,1)*(py - y) + random(0,1)*(gbesty - y);
    
    //actualiza velocidad (fórmula mezclada)
    //vx = w * vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    //vy = w * vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);
    // trunca velocidad a maxv
    float modu = sqrt(vx*vx + vy*vy);
    if (modu > maxv){
      vx = vx/modu*maxv;
      vy = vy/modu*maxv;
    }
    
    // update position
    x = x + vx;
    y = y + vy;

  // Convierte las coordenadas a cartesianas antes de hacer el rebote
  float cartX = screenToCartesianX(x);
  float cartY = screenToCartesianY(y);

    // println("altura", height); 700
    // println("ancho", width); 1000
    // Rebote en los límites de la pantalla
    if (x > ancho || x < -ancho) { // Rebote en el eje X (coordenadas de pantalla)
        vx = -vx;  // Rebote en el eje X
    }
    if (y > altura || y < -altura) { // Rebote en el eje Y (coordenadas de pantalla)
        vy = -vy;  // Rebote en el eje Y
    }


  }
  
  // ------------------------------ despliega partícula
  void display(){
    ellipse (x,y,d,d);
    // dibuja vector
    stroke(#ffffff); // Color del borde de la partícula
    line(x,y,x-10*vx,y-10*vy);
  }
} //fin de la definición de la clase Particle  
 
// dibuja punto azul en la mejor posición y despliega números
void despliegaBest(){
  fill(#0000ff);
  ellipse(gbestx,gbesty,d,d);
  }

// ======================================================================

void setup() {
  size(1000, 700, P3D);  // Use P3D for rendering
  cols = gridSize;
  rows = gridSize;
  z = new float[cols][rows];

  // Compute function values
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float x = map(i, 0, cols - 1, domainMin, domainMax);
      float y = map(j, 0, rows - 1, domainMin, domainMax);
      z[i][j] = rastrigin(x, y);
    }
  }

  // Find min and max Z values
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      minZ = min(minZ, z[i][j]);
      maxZ = max(maxZ, z[i][j]);
    }
  }
  
   // ~~~~~~~~~~~~~~~~~PARTICULAS~~~~~~~~~~~~~~~~~~~~~~~~~
   smooth();
  // crea arreglo de objetos partículas
  fl = new Particle[puntos];
  for(int i =0;i<puntos;i++)
    fl[i] = new Particle();
}

void draw() {
  background(0);
  translate(width / 2, height / 2, 0);
  rotateX(PI);  // Tilt for better visibility

  float cellSize = width / cols;  // Adjust size to fit screen
  
  for (int x = 0; x < cols - 1; x++) {
    for (int y = 0; y < rows - 1; y++) {
      float px = map(x, 0, cols, -width / 2, width / 2);
      float py = map(y, 0, rows, -height / 2, height / 2);
      
      float normZ = map(z[x][y], minZ, maxZ, 0, 1);  // Normalize height
      color c = getHeatColor(normZ);  // Get color based on normalized Z

      fill(c);
      noStroke();
      rect(px, py, cellSize, cellSize);
    }
  }
  // ~~~~~~~~~~~~~~ PARTICULAS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  for(int i = 0;i<puntos;i++){
    fl[i].display();
  }
  despliegaBest();
  //mueve puntos
  for(int i = 0;i<puntos;i++){
    fl[i].move();
    fl[i].Eval();
  }
}

// Function to map values to a heatmap-like gradient
color getHeatColor(float t) {
  return lerpColor(lerpColor(color(0, 0, 255), color(0, 255, 0), t), 
                   color(255, 0, 0), t);
}

// Rastrigin function
float rastrigin(float x, float y) {
  float A = 10;
  return A * 2 + (x * x - A * cos(TWO_PI * x)) + (y * y - A * cos(TWO_PI * y));
}
