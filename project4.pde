FloatTable data;

float dataMin, dataMax;
int yearMin, yearMax;
int[] years;
float plotX1, plotY1;
float plotX2, plotY2;


// REFINE AND INTERACT VARIABLES
int currentColumn = 0;
int columnCount;

PFont plotFont;
int yearInterval = 10;
int rowCount = 0;


int volumeInterval = 10;


float labelX, labelY;
int toggleLine = 0;

Integrator[] interpolators;

void setup() {
  size(720,405);
  data = new FloatTable("data/milk-tea-coffee.tsv");
  columnCount = data.getColumnCount();
  years = int(data.getRowNames());
  yearMax = years[years.length-1];
  yearMin = years[0];
  dataMax = data.getTableMax();
  dataMin = 0;
  
  // Create theboundaries for the visualization window
  plotX1 = 120; 
  plotX2 = width - 80;
  plotY1 = 50;
  plotY2 = height - 70;
  labelY = height - 25;
  labelX =  50;
  rowCount = data.getRowCount();
  
  plotFont = createFont("SansSerif",20);
  textFont(plotFont);
   
   interpolators = new Integrator[rowCount];
   for ( int row= 0 ; row < rowCount; row++ ) {
     float initialValue = data.getFloat(row,0); 
     interpolators[row] = new Integrator(initialValue);
     interpolators[row].attraction = 0.5; 
   }
   smooth();
}

void draw() {
  
   background(224); // Offwhite background
   
   // Draw the visualization window 
   fill(255);
   rectMode(CORNERS);
   rect(plotX1,plotY1,plotX2,plotY2);
   
   
   // fill(#5679C1);
    
   drawTitle(); 
   drawAxisLabels();
   drawXDataLabels();
   drawYDataLabels();
   drawTitleTabs();
  //  drawDataArea(currentColumn);
   drawDataBars(currentColumn);
   
   for (int row = 0; row < rowCount; row++) { 
    interpolators[row].update( );
  }
  
  
}

void drawTitle() {
   fill(0);
  textSize(20);
  textAlign(LEFT);
  String title = data.getColumnName(currentColumn);
  text(title, plotX1, plotY1 - 10);
}

void drawAxisLabels() {
  
  textSize(13);
  textLeading(15);
  textAlign(CENTER,CENTER);
  
  // The X label
  text("Year", (plotX1 + plotX2) / 2, labelY);
  
  
  // The Y label
  text("Gallons \n consumed \n per capita",labelX, (plotY1 + plotY2) / 2);
  
}

void drawXDataLabels() {
  textSize(10);
  textAlign(CENTER,TOP);
  
    // Use thin, gray lines to draw the grid.
  stroke(224);
  strokeWeight(1);


  for (int row = 0; row < rowCount; row++) {
    if (years[row] % yearInterval == 0) {
      float x = map(years[row], yearMin, yearMax, plotX1, plotX2);
      text(years[row], x, plotY2 + 10);
      line(x, plotY1, x, plotY2);
    }
  }
  
}


void drawYDataLabels() {
   fill(0);
  textSize(10);

  stroke(128);
  strokeWeight(1);
  for (float v = dataMin; v <= dataMax; v += volumeInterval) {
    float y = map(v, dataMin, dataMax, plotY2, plotY1);
    if (v % volumeInterval == 0) {
      if (v == dataMin) {
        textAlign(RIGHT); // Align by the bottom
      
      } else if (v == dataMax) {
        textAlign(RIGHT, TOP); // Align by the top
      } else {
        textAlign(RIGHT, CENTER); // Center vertically
      }
      text(floor(v), plotX1 - 10, y);
    
     // strokeWeight(2);
      line(plotX1 -4, y, plotX1, y); // Draw major tick mark
    
    } else {
      line(plotX1 -2, y, plotX1, y); 
      
    }
    
  }
}

void drawYTickMarks() {
  
  
  
}


float tabTop, tabBottom;
float[] tabLeft, tabRight;
float tabPad = 10;


void drawTitleTabs() {
 
  rectMode(CORNERS); 
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
   if (toggleLine == 0) toggleLine = 1;
  else toggleLine = 0;


  if (mouseY > tabTop && mouseY < tabBottom) {
    for (int col = 0; col < columnCount; col++) {
      if (mouseX > tabLeft[col] && mouseX < tabRight[col]) {
        setColumn(col);
      }
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


void drawDataArea(int col) {
  
  
  fill(#0000FF);
  beginShape();
  
    for ( int row = 0; row < rowCount; row++ ) {
      if (data.isValid(row,col) ) {
          float value = interpolators[row].value;
          float x = map(years[row], yearMin, yearMax, plotX1, plotX2);
          float y = map(value, dataMin, dataMax, plotY2, plotY1);
          vertex(x,y);
      }
    }
    
    // Draw the lower-right and lower-left corners.
  vertex(plotX2, plotY2);
  vertex(plotX1, plotY2);
  endShape(CLOSE);
  
  
}

float barWidth = 4;

void drawDataBars(int col) {
    noStroke( );
  rectMode(CORNERS);
  for (int row = 0; row < rowCount; row++) {
    if (data.isValid(row, col)) {
      float value = interpolators[row].value;
     // float value = data.getFloat(row, col);
      float x = map(years[row], yearMin, yearMax, plotX1, plotX2); 
      float y = map(value, dataMin, dataMax, plotY2, plotY1); 
      rect(x-barWidth/2, y, x+barWidth/2, plotY2);
    }
  }
  
}