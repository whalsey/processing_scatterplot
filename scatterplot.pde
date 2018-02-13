/*
scatterplot.pde written by William Halsey
whalsey@vols.utk.edu

Project 1 for DSE 512
Data Science and Engineering PhD
Bredesen Center
University of Tennesse - Knoxville

Due Monday 12 February 2018
*/

// Global variables
String file = null;

int xvar = -1;
float xmax = -1;
float xmin = -1;
float[] xdat = null;
float[] xnorm = null;
int yvar = -1;
float ymax = -1;
float ymin = -1;
float[] ydat = null;
float[] ynorm = null;
int zvar = -1;
float zmax = -1;
float zmin = -1;
float[] zdat = null;
float[] znorm = null;

int numVar = -1;
int numSample = -1;

String[] labels = null;
Table data = null;

Boolean first = false;
Boolean zFlag = true;
Boolean flag = true;
Boolean mouse = false;
Boolean info = false;

int plotWidth = 500;
int plotHeight = 500;
int plotOriginX = -1;
int plotOriginY = -1;
int drawOriginX = -1;
int drawOriginY = -1;
int drawWidth = -1;
int drawHeight = -1;

float buffer = 0.07;
int radMax = 25;
int radMin = 3;
int radDefault = 10;

int keyOriginX = -1;
int keyOriginY = -1;
int keyWidth = -1;
int keyHeight = -1;

color[] colorMin = {color(250, 250, 250), color(255, 245, 245), color(245, 255, 245), color(245, 245, 255), color(137, 130, 118), color(118, 137, 30)};
color[] colorMax = {color(5, 5, 5), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 165, 0), color(0, 255, 165)};
int colourThemes = 6;
int colour = 0;

// Callback function used to choose file
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    file = "\0";
  } else {
    println("User selected " + selection.getAbsolutePath());
    file = selection.getAbsolutePath();
  }
}

// Function called to open a file
// todo - may try to call this fn again from inside the vis so user can change files to explore
void selectNewFile() {
  selectInput("Select a file to process:", "fileSelected");
  first = true;
}

// Function to pull headers from first line a table for lables
// ASSUMES THAT THE TABLE HAS A HEADER ROW
void processHeader(Table table) {
  labels = new String[numVar];
  
  TableRow head = table.getRow(0);
  
  // read in the headers from the first row
  for (int i = 0; i < numVar; i++) {
    labels[i] = head.getString(i).trim();
  }

  // delete header row from the data
  table.removeRow(0);
}

float findPercentile(float percent, float[] dat) {
  sort(dat);
  
  return dat[int(percent * numSample)];
}
  
int headerToIdx(String header) {
  int idx = -1;
  
  for (int i = 0; i < numVar; i++) {
    if (labels[i] == header) {
      idx = i;
      break;
    }
  }
  
  return idx;
}
    
String idxToHeader(int idx) {
  return labels[idx];
}

// Function pulls all the data for a particular column and returns them as an array of floats
// ASSUMES THAT ALL DATA IS NUMERIC
float[] getColData(int idx) {
  String[] tmp = data.getStringColumn(idx);
  
  float[] dat = new float[numSample];
  
  for (int i = 0; i < numSample; i++) {
    dat[i] = Float.parseFloat(tmp[i]);
  }
  
  return dat;
}

float findMax(int idx) {
  float[] dat = getColData(idx);
  float max = dat[0];
  
  for (int i = 0; i < numSample; i++) {
    max = (max < dat[i]) ? dat[i] : max;
  }
  
  return max;
}

float findMin(int idx) {
  float[] dat = getColData(idx);
  float min = dat[0];
  
  for (int i = 0; i < numSample; i++) {
    min = (min > dat[i]) ? dat[i] : min;
  }
  
  return min;
}

// Function removes all samples that have 'NA' values and returns updated table
Table removeNA(Table table) {
  TableRow row = null;
  String elem = null;
  int end = table.getRowCount();
  
  for (int i = 0; i < end; i++) {
    row = table.getRow(i);
    for (int j = 0; j < numVar; j++) {
      elem = row.getString(j);
      
      if (elem.contains("NA")) {
        table.removeRow(i);
        i--;
        end = table.getRowCount();
        break;
      }
    }
  }
  
  return table;
}

// Function takes in valid filepath and returns a Table of the data
// THIS FUNCTION WILL GET RID OF ANY ROWS THAT HAVE NA VALUES
Table readInTable(String file) {
  Table tmp = loadTable(file);
  
  numVar = tmp.getColumnCount();
  
  processHeader(tmp);
      
  if (numVar < 3) {
     zFlag = false;
  } else if (numVar < 2) {
     println("Error: The file selected does not contain enough variables to produce a scatterplot!");
     exit();
  } else {
    tmp = removeNA(tmp);
  }
  
  return tmp;
}

float[] standardize(float[] dat, float max, float min) {
  float[] tmp = new float[numSample];
  
  for (int i = 0; i < numSample; i++) {
    tmp[i] = (dat[i] - min) / (max - min);
  }
  
  return tmp;
}

// Translates a normalized x, y coordinate to a screen coordinate
// todo
int[] pointToScreen(float x, float y) {
  int[] point = new int[2];
  
  point[0] = int(drawOriginX + drawWidth * x);
  point[1] = int(drawOriginY + drawWidth * (1-y));
  return point;
}

float[] screenToPoint(int x, int y, float xmin, float xmax, float ymin, float ymax) {
  float[] point = new float[2];
  
  point[0] = (x - drawOriginX) / float(drawWidth) * (xmax - xmin) + xmin;
  point[1] = (1 - (y - drawOriginY) / float(drawHeight)) * (ymax - ymin) + ymin;
  
  return point;
}

void processData() {
    
    // find max and min of data
    xmax = findMax(xvar);
    xmin = findMin(xvar);
    ymax = findMax(yvar);
    ymin = findMin(yvar);
    zmax = findMax(zvar);
    zmin = findMin(zvar);
    
    xdat = getColData(xvar);
    ydat = getColData(yvar);
    zdat = getColData(zvar);
    
    // normalize data
    xnorm = standardize(xdat, xmax, xmin);
    ynorm = standardize(ydat, ymax, ymin);
    znorm = standardize(zdat, zmax, zmin);
}

// Function will take the chosen data and will draw the scatterplot
void drawScatterplot() {
  background(200);
  // Draw background of scatterplot (want size to 500x500)
  fill(255);
  stroke(0);
  strokeWeight(1);
  rect(plotOriginX, plotOriginY, plotWidth, plotHeight);
  
  int[] point = null;
  
  for (int i = 0; i < numSample; i++) {
    point = pointToScreen(xnorm[i], ynorm[i]);
    
    if (flag) {
      fill(colorMax[colour], 50);
      ellipse(point[0], point[1], int(radMax * znorm[i]) + radMin, int(radMax * znorm[i]) + radMin);
    } else {
      fill(lerpColor(colorMin[colour], colorMax[colour], znorm[i]));
      ellipse(point[0], point[1], radDefault, radDefault);
    }
  }
}

// Function will handle the text and axis lables for chosen data
void formatText() {
  // clear title
  noStroke();
  fill(200);
  rect(plotOriginX, plotOriginY - 50, plotWidth, 50);
  
  // Draw title
  fill(30);
  stroke(15);
  String title = idxToHeader(xvar) + " vs. " + idxToHeader(yvar) + " vs. " + idxToHeader(zvar);
  
  textSize(18);
  textAlign(CENTER, BOTTOM);
  text(title, plotWidth / 2 + plotOriginX, plotOriginY - 20);
  
  // Draw tooltip
  if (mouse) {
    textSize(11);
    float[] tmp = screenToPoint(mouseX, mouseY, xmin, xmax, ymin, ymax);
    
    String tt = Float.toString(tmp[0]) + ", " + Float.toString(tmp[1]);
    textAlign(CENTER, TOP);
    int x = (mouseX < drawOriginX + 45) ? drawOriginX + 45 : ((mouseX > drawOriginX + drawWidth - 45) ? drawOriginX + drawWidth - 45 : mouseX);
    text(Float.toString(tmp[0]), x, plotOriginY + plotHeight + 3);
    rect(mouseX, plotOriginY, 1, plotHeight);
    textAlign(RIGHT, CENTER);
    int y = (mouseY < drawOriginY + 15) ? drawOriginY + 15 : ((mouseY > drawOriginY + drawHeight - 15) ? drawOriginY + drawHeight - 15 : mouseY);
    text(Float.toString(tmp[1]), plotOriginX - 3, y);
    rect(plotOriginX, mouseY, plotWidth, 1);
  }
  
  // Draw Axes
  textSize(13);
  textAlign(CENTER, TOP);
  rect(drawOriginX, plotOriginY + plotHeight, 1, 5);
  text(Float.toString(xmin), drawOriginX, plotOriginY + plotHeight + 5);
  rect(drawOriginX + drawWidth, plotOriginY + plotHeight, 1, 5);
  text(Float.toString(xmax), drawOriginX + drawWidth, plotOriginY + plotHeight + 5);
  textAlign(RIGHT, CENTER);
  rect(plotOriginX - 5, drawOriginY, 5, 1);
  text(Float.toString(ymax), plotOriginX - 5, drawOriginY);
  rect(plotOriginX - 5, drawOriginY + drawHeight, 5, 1);
  text(Float.toString(ymin), plotOriginX - 5, drawOriginY + drawHeight);
  
  int[] t1 = pointToScreen(findPercentile(0.25, xnorm), 0);
  int[] t2 = pointToScreen(findPercentile(0.5, xnorm), 0);
  int[] t3 = pointToScreen(findPercentile(0.75, xnorm), 0);
  fill(150);
  rect(t1[0], plotOriginY + plotHeight - 5, t2[0] - t1[0], 10);
  rect(t2[0], plotOriginY + plotHeight - 5, t3[0] - t2[0], 10);
  
  t1 = pointToScreen(0, findPercentile(0.25, ynorm));
  t2 = pointToScreen(0, findPercentile(0.5, ynorm));
  t3 = pointToScreen(0, findPercentile(0.75, ynorm));
  rect(plotOriginX - 5, t1[1], 10, t2[1] - t1[1]);
  rect(plotOriginX - 5, t2[1], 10, t3[1] - t2[1]);
  
  fill(0);
  textSize(15);
  textAlign(CENTER, TOP);
  text(idxToHeader(xvar), plotWidth/2+plotOriginX, plotOriginY+plotHeight + 60);
  
  translate(plotOriginX, plotHeight/2+plotOriginY);
  textAlign(CENTER, BOTTOM);
  rotate(-PI/2);
  text(idxToHeader(yvar), 0, -60);
  rotate(PI/2);
  translate(-plotOriginX, -plotHeight/2-plotOriginY);
}

void drawKey() {
  fill(225);
  stroke(100);
  strokeWeight(1);
  
  rect(keyOriginX, keyOriginY, keyWidth, keyHeight);
  
  fill(50);
  textSize(15);
  textAlign(CENTER, BOTTOM);
  text(idxToHeader(zvar), keyWidth/2+keyOriginX, keyOriginY-2);
  
  for (int i = 0; i < 3; i++) {
    
    stroke(0);
    fill(colorMax[colour], 50);
    ellipse(int(2*keyWidth/3.0) + keyOriginX, keyOriginY + 50 +(keyHeight * i / 3.0), int(radMax * i/2.0) + radMin, int(radMax * i/2.0) + radMin);
  
    fill(lerpColor(colorMin[colour], colorMax[colour], i/2.0));
    ellipse(int(keyWidth/3.0) + keyOriginX, keyOriginY + 50 + (keyHeight * i / 3.0), radDefault, radDefault);
  }
  
  textSize(13);
  fill(50);
  textAlign(CENTER, TOP);
  text(Float.toString(zmin), keyWidth/2 + keyOriginX, keyOriginY + 50 - 30);
  text(Float.toString((zmax + zmin) / 2), keyWidth/2 + keyOriginX, keyOriginY + 50 +(keyHeight * 1 / 3.0) - 30);
  text(Float.toString(zmax), keyWidth/2 + keyOriginX, keyOriginY + 50 +(keyHeight * 2 / 3.0) - 30);
  
  textSize(11);
  fill(100);
  textAlign(CENTER, BOTTOM);
  text("Press 'SPACE' to \ntoggle between modes", keyWidth/2 + keyOriginX, keyOriginY + keyHeight);
}


// Code used to set up the scatterplot window and call the initial filechooser
void setup() {
  selectNewFile();
  size(800, 700);
  background(200);
  plotOriginX = (width - plotWidth)/2;
  plotOriginY = (height - plotHeight)/2;
  drawWidth = int((1 - buffer) * plotWidth);
  drawHeight = int((1 - buffer) * plotHeight);
  drawOriginX = (width - drawWidth)/2;
  drawOriginY = (height - drawHeight)/2;
  keyOriginX = plotOriginX + plotWidth + 5;
  keyOriginY = plotHeight/2 + plotOriginY - 150;
  keyWidth = width - keyOriginX - 8;
  keyHeight = 300;
  ellipseMode(CENTER);
}

// Code that processing calls in a loop in order to draw data
void draw() {
  
  // test to see if a file is chosen
  if (file == "\0") {
    println("Error: No file chosen! Exiting.");
    exit();
  }
  
  // test to see if file has valid extension
  if (file != null && !file.contains(".csv")) {
    println("Error: Invalid file chosen! Filetype must be '.csv'.");
    file = null;
    selectNewFile();
    return;
  } else if (file != null && first && file.contains(".csv")) {
    first = false;
    data = readInTable(file);
    
    xvar = 0;
    yvar = 1;
    zvar = 2;
    
    numSample = data.getRowCount();
  }
  
  // At this point we should have all of the data that we need
  // LET'S GET DRAWING!
  // todo - add logic exclude z direction if zFlag == false
  if (data != null){
    processData();
    drawScatterplot();
    formatText();
    drawKey();
  }
  
  stroke(0);
  fill(100);
  strokeWeight(1);
  ellipse(width - 30, height - 30, 30, 30);
  textSize(20);
  fill(0);
  textAlign(CENTER, CENTER);
  text("?", width - 30, height - 30);
  
  if (info) {
    fill(255);
    stroke(0);
    strokeWeight(3);
    rect(width / 2 - 200, height / 2 - 100, 400, 200);
    
    textSize(15);
    fill(0);
    textAlign(CENTER, CENTER);
    String s = "LEFT / RIGHT -- Change 'x' variable\nUP / DOWN -- Change 'y' variable\n'U' / 'D' -- Change 'z' variable\n'C' -- Change color map";
    text(s, width / 2, height / 2);
  }
}

void keyPressed() {  
  if (keyCode == UP) {
    yvar = (yvar + 1) % numVar;
  } else if (keyCode == DOWN) {
    yvar = (yvar - 1 < 0) ? numVar - 1 : yvar - 1;
  } else if (keyCode == RIGHT) {
    xvar = (xvar + 1) % numVar;
  } else if (keyCode == LEFT) {
    xvar = (xvar - 1 < 0) ? numVar - 1 : xvar - 1;
  } else if (key == 'u') {
    zvar = (zvar + 1) % numVar;
  } else if (key == 'd') {
    zvar = (zvar - 1 < 0) ? numVar - 1 : zvar - 1;
  } else if (key =='c') {
    colour = (colour + 1) % colourThemes;
  } else if (key == ' ') {
    flag = !flag;
  }
}

void mouseMoved() {
  if (plotOriginX < mouseX && plotOriginX + plotWidth > mouseX && plotOriginY < mouseY && plotOriginY + plotHeight > mouseY) {
    mouse = true;
  } else {
    mouse = false;
  }
  
  if (mouseX < width - 15 && width - 45 < mouseX && mouseY < height - 15 && height - 45 < mouseY) {
    info = true;
  } else {
    info = false;
  }
}