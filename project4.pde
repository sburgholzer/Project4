//###########################################
//# Authors:   Thomas Swed                  #
//#            Brandon Schabell             #
//#            Patrick Tran                 #
//#            Scott Burgholzer             #
//# Class:    CPSC 53000 Data Visualization #
//# Semester: Summer I 2018                 #
//# Project:  4                             #
//# Date:     06/19/18                     #
//###########################################

//############ Global Variables #############
// vars for data
FloatTable data;
float dataMin, dataMax;
int yearMin, yearMax;
int[] years;
int currentColumn = 0;
int columnCount;
int rowCount = 0;
int volumeInterval = 250;
Integrator[] interpolators;
int currentYear = 0;
int[] numOfEachYear;
int[] xNumber;

// vars for plotting
float plotX1, plotY1;
float plotX2, plotY2;
PFont plotFont;
float labelX, labelY;
int toggleLine = 0;

// vars for zooming
float xTrans = 0;
float yTrans = 0;
float zoom = 1;

//################ Functions ################

void setup() {
  size(720,405);
  
  // get the data
  data = new FloatTable("data/StockPrices.csv");
  columnCount = data.getColumnCount();
  years = int(data.getRowNames());
  yearMax = years[years.length-1];
  yearMin = years[0];
  dataMax = data.getTableMax();
  dataMin = 0;
  
  // This will determine how many data points for each year this are
  // This is to make the graph more realistic
  numOfEachYear = new int[years.length-1];
  int prevYear = years[0];
  int count = 0;
  int newIndex = 0;
  for(int index = 0; index < years.length; index++){
    if (prevYear == years[years.length - 1]) {
      count += 1;
    } else {
      if (years[index] == prevYear) {
        count += 1;
      } else {
        numOfEachYear[newIndex] = count;
        newIndex += 1;
        count = 1;
        prevYear = years[index];
      }
    }
  }
  numOfEachYear[newIndex + 1] = count;
  
  // This will tell us how many X axis points we will have
  int totalPoints = 0;
  for (int index = 0; index < numOfEachYear.length; index++) {
    if (numOfEachYear[index] != 0) {
      totalPoints = totalPoints + numOfEachYear[index];
    }
  }
  // This just creates an array of values 0 to the total number of points
  // This is so we can display all the points at the appropriate location
  xNumber = new int[totalPoints];
  for (int i = 0; i < totalPoints; i++) {
    xNumber[i] = i;
  }
  
  
  // Create the boundaries for the visualization window
  plotX1 = 120; 
  plotX2 = width - 80;
  plotY1 = 50;
  plotY2 = height - 70;
  labelY = height - 25;
  labelX =  50;
  rowCount = data.getRowCount();
  
  // create the font
  plotFont = createFont("SansSerif",20);
  textFont(plotFont);
   

   // initial data loaded
   interpolators = new Integrator[rowCount];
   for ( int row= 0 ; row < rowCount; row++ ) {
     float initialValue = data.getFloat(row,0); 
     interpolators[row] = new Integrator(initialValue);
     interpolators[row].attraction = 0.5; 
   }
   smooth();
   
   frameRate(24); // Slowing the frame rate for a more aesthetically pleasing transition
   surface.setTitle("Stock Prices"); // Setting window title
}

void draw() {  
  background(224); // Offwhite background
   
  // Draw the visualization window 

  fill(255);
  rectMode(CORNERS);
  rect(plotX1,plotY1,plotX2,plotY2);
   
  // this is for the zoom cababilities
  translate(xTrans,yTrans);
  scale(zoom);
   
  // functions to draw everything
  drawTitle();
  drawGridlineBlurb();
  drawAxisLabels();
  drawTitleTabs();
  drawDataArea(currentColumn);
  fill(0);
  drawXDataLabels();
  drawYDataLabels();
  rollover(currentColumn);
  //drawDataBars(currentColumn);
   
  // update the data
  for (int row = 0; row < rowCount; row++) { 
     interpolators[row].update( );
  }
}

void drawTitle() {
  fill(0);
  textSize(20);
  textAlign(LEFT);
  String title = data.getColumnName(currentColumn);
  text(title, plotX1 + 10, plotY1 + 25);
}

void drawGridlineBlurb() {
  fill(150);
  textSize(12);
  textAlign(LEFT);
  text("Grid can be toggled on/off by pressing the space bar.", plotX1 + 10, plotY1 + 50);
}

void drawAxisLabels() {
  fill(0);
  textSize(13);
  textLeading(15);
  textAlign(CENTER,CENTER);
  
  // The X label
  text("Year", (plotX1 + plotX2) / 2, labelY);
  // The Y label
  text("Stock \n close \n price",labelX, (plotY1 + plotY2) / 2);  
}

void drawXDataLabels() {
  textSize(10);
  textAlign(CENTER,TOP);
  
  // Use thin, gray lines to draw the grid.
  stroke(224);
  strokeWeight(1);
  for (int i = 0; i < xNumber.length; i++) {
    if (years[i] != currentYear){
      float x = map(xNumber[i], xNumber[0], xNumber[xNumber.length - 1], plotX1, plotX2);
      text(years[i], x, plotY2 + 10);
      // only display gridlines when user tells us to
      if (toggleLine == 1) {
          line(x, plotY1, x, plotY2);
      }
      currentYear = years[i];
    }
  }
}

void drawYDataLabels() {
  fill(0);
  textSize(10);
  stroke(224);
  strokeWeight(1);
  
  for (float v = dataMin; v <= dataMax; v += volumeInterval) {
    float y = map(v, dataMin, dataMax, plotY2, plotY1);
    if (v % volumeInterval == 0) {
      textAlign(RIGHT, CENTER); // Center vertically
      text("$" + floor(v), plotX1 - 10, y);
      strokeWeight(1);
      // only display the grid lines when the user tells us to
      if (toggleLine == 1) {
        line(plotX1 -4, y, plotX2, y); // Draw major tick mark  
      }
    }  //<>//
  }
}

float tabTop, tabBottom;
float[] tabLeft, tabRight;
float tabPad = 10;

void drawTitleTabs() {
  rectMode(CORNERS);  //<>//
  noStroke( ); 
  textSize(20); 
  textAlign(LEFT);
  
  // On first use of this method, allocate space for an array
  // to store the values for the left and right edges of the tabs.
  if (tabLeft == null) {
    tabLeft = new float[columnCount];
    tabRight = new float[columnCount];
  }
  float runningX = plotX1;
  tabTop = plotY1 - textAscent() - 15; 
  tabBottom = plotY1;
  for (int col = 0; col < columnCount; col++) {
    String title = data.getColumnName(col);
    tabLeft[col] = runningX;
    float titleWidth = textWidth(title);
    tabRight[col] = tabLeft[col] + tabPad + titleWidth + tabPad;
    // If the current tab, set its background white; otherwise use pale gray.
    fill(col == currentColumn ? 255 : 224);
    rect(tabLeft[col], tabTop, tabRight[col], tabBottom);
    // If the current tab, use black for the text; otherwise use dark gray.
    fill(col == currentColumn ? 0 : 64);
    text(title, runningX + tabPad, plotY1 - 10);
    runningX = tabRight[col];
  }
}

void mousePressed() {
  // zoom back to nromal
  xTrans = 0;
  yTrans = 0;
  zoom = 1;
  
  // select the graph
  if (mouseY > tabTop && mouseY < tabBottom) {
    for (int col = 0; col < columnCount; col++) {
      if (mouseX > tabLeft[col] && mouseX < tabRight[col]) {
        setColumn(col);
      }
    }
  }
}

// we decided to toggle grid lines by pressing the space bar
void keyPressed(){
  if (key == ' ') {
    if (toggleLine == 0) {
      toggleLine = 1;
    } else {
      toggleLine = 0;
    }
  }
}

void setColumn(int col) {  
  if (col != currentColumn) {
    currentColumn = col;
  }
   
  for (int row = 0; row < rowCount; row++) {
    interpolators[row].target(data.getFloat(row, col));
  }   
}

// stock data is drawn with the area filled in
// so we use this method
void drawDataArea(int col) {  
  fill(#0000FF);
  beginShape();
  

  for (int i = 0; i < xNumber.length; i ++) {
    if (data.isValid(i,col)){
      float value = interpolators[i].value;
      float x = map(xNumber[i], xNumber[0], xNumber[xNumber.length - 1], plotX1, plotX2);
      float y = map(value, dataMin, dataMax, plotY2, plotY1);
      vertex(x,y);
    }
  }
    
  // Draw the lower-right and lower-left corners.
  vertex(plotX2, plotY2); //<>//
  vertex(plotX1, plotY2);
  endShape(CLOSE);
}

/*
float barWidth = 4;

void drawDataBars(int col) {
  noStroke( ); //<>//
  rectMode(CORNERS);
  for (int row = 0; row < rowCount; row++) {
    if (data.isValid(row, col)) {
      float value = interpolators[row].value;
      float x = map(row, 0, rowCount - 1, plotX1, plotX2); 
      float y = map(value, dataMin, dataMax, plotY2, plotY1); 
      rect(x-barWidth/2, y, x+barWidth/2, plotY2);
    }
  }
}
*/

// display the data in rollover (doesn't work as nicely when zoomed in)
void rollover(int col) {
  for (int i = 0; i < xNumber.length; i ++) {
    if (data.isValid(i,col)) {
      float value = interpolators[i].value;
      float x = map(xNumber[i], xNumber[0], xNumber[xNumber.length - 1], plotX1, plotX2);
      float y = map(value, dataMin, dataMax, plotY2, plotY1);
      // if (dist(mouseX, mouseY, x, y) < 2) {
      if (abs(mouseX - x) < 3) {
        strokeWeight(10);
        point(x,y);
        fill(0);
        textSize(10);
        textAlign(CENTER);
        text( "$" + nf(value, 0, 2) + " (" + data.getMonth(i) + "/" + data.getYear(i) + ")", x, y-8);
      }
    }
  }
}

// get the zoom data
void mouseWheel( MouseEvent event) {
  xTrans = xTrans-event.getCount()*(mouseX)/100;
  yTrans = yTrans-event.getCount()*(mouseY)/100;
  zoom += event.getAmount() / 100;
}
