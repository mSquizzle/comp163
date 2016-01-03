import java.util.*; 
 
float DEFAULT_DENSITY = 1.0;
int DEFAULT_SEED = 10; 

int DEFAULT_HEIGHT = 1000;
int DEFAULT_WIDTH = 1000; 

//aka beachfront
ArcNode rootNode;

//sweepline
float lineCoord;
int seed;

//event queue (need to implement sorting for this)
PriorityQueue<Event> events;
ArrayList<Site> sites;

//ArrayList of Voronoi Vertices
ArrayList<VoronoiVertex> voronoi;

ArrayList<PVector> possibleIntersections;
ArrayList<CircleEvent> circleEvents;

//our voronoi cells
Cell[] cells;

//our list of discovered edges
Edge[][] edges;

int[] debugX = {101, 200, 150/*303*/, 440, 442, 579, 664, 775};
//int[] debugX = {301, 500, 350/*303*/, 640, 642, 779, 864, 975};
int[] debugY = {301, 500, 700/*650*/,250, 851, 551, 224, 766};
int[] colorX = {0, 50, 100, 150, 200, 250, 0, 180};
int[] colorY = {0, 50, 100, 150, 200, 250, 200, 0};
 
Event currentEvent;

boolean drawArcs;
boolean drawCircles;

void setup(){
  size(DEFAULT_HEIGHT, DEFAULT_WIDTH);
  
  seed = debugX.length;
  sites = new ArrayList<Site>(seed);
  cells = new Cell[seed];
  for(int i = 0; i < seed; i++){
    int x = debugX[i];
    int y = debugY[i];
    //int x = (int)random(200, height - 200);
    //int y = (int)random(200, height - 200); 
    
    //sloppy, but whatevs 
    Site site = new Site(new PVector(x,y), i);
    sites.add(site);
    cells[i] = new Cell(site);
  }
  initialize();
  restart = false;   
}

boolean restart;
boolean debug;  
void initialize(){ 
  rootNode = null; 
  edges = new Edge[seed][seed]; 
  cells = new Cell[seed];
  lineCoord = 0;
  possibleIntersections = new ArrayList<PVector>(); 
  circleEvents = new ArrayList<CircleEvent>();
  voronoi = new ArrayList<VoronoiVertex>();
  createEvents();
  currentEvent = null;
  debug = true;
}

void createEvents(){
  events = new PriorityQueue<Event>(seed*3); 
  for(Site site : sites){
    Event siteEvent = new SiteEvent(site);
    events.add(siteEvent);
    if(debug){
      events.add(new Event(new PVector(site.point.x+70, site.point.y)));
    }
  }
}

ArcNode getUnderArc(PVector point){
    ArcNode node = rootNode;
    ArcNode bestNode = rootNode;
    float y = point.y;
    if(rootNode !=null){
        while(node.next != null){            
          if(y >= node.startY && y <= node.endY){
            bestNode = node; 
            if(bestNode!=null){
              println("Found an extra node");  
            }
          }
          node = node.next;
      }
      if(y >= node.startY && y <= node.endY){
          bestNode = node.next; 
      }
    } 
    return bestNode;
}

void drawOthers(){
  ArcNode node = rootNode;

    while(node!=null){
      for(float y = 0; y < height; y+=1){
        PVector point = getPoint(node, y);
        if(point!=null){
          point(point.x, point.y);
        }  
        
      }
      node = node.next;
    }  
}

//TODO - FIX CONTINUITY ISSUE
void updateEndPoints(){
  ArcNode node = rootNode; 
  println("Line coordinate is currently "+lineCoord);
   String list = "";
    while(node != null){
        //edge case - the sweepline is currently at a node site
        if(node.site.point.x == lineCoord){
          
          println(node.site+"setting startY to "+node.site.point.y);
          println(node.site+"setting endY to "+node.site.point.y);          
          node.startY = node.site.point.y;
          node.endY = node.site.point.y;
        }else{
          if(node.previous !=null){
            node.startY = node.previous.endY;
            
            println(node.site+"setting endY to "+node.previous.endY);
            
          }else{
            node.startY = -MAX_INT;
          }
          if(node.next != null){
            //the lower intersection will be stored at index 0 
            if(node.next.site.point.x == lineCoord){
              node.endY = node.next.site.point.y; 
            }else{
              PVector[] intersections = findArcIntersections(node, node.next);
              if(node.site.point.x < node.next.site.point.x){
                //this arc was possibly split by the next arc
                //choose the lower endpoint
                node.endY = intersections[0].y;
                //println("interesections "+intersections[0]+" "+intersections[1]);              
              }else{
                //otherwise, this arc did the splitting, choose the upper endpoint
                 //println("interesections "+intersections[0]+" "+intersections[1]);  
             
                node.endY = intersections[1].y;
              }  
            }
          }else{
            node.endY = MAX_INT;               
          }
      }
      list+=node.site.point+" -["+node.startY+" to "+node.endY+"]\n";
      node = node.next; 
    }  
    println(list);
    println("======");
}


//return null, or a pair of PVectors where
PVector[] findArcIntersections(ArcNode arcNode, ArcNode other){
  fill(255,0,0);
 
  PVector point = arcNode.site.point;
  PVector otherPoint = other.site.point;
  
  if(point.y > otherPoint.y){
    point = otherPoint;
    otherPoint = arcNode.site.point;   
  }
  
  PVector[] points = null;
   
    float p1 = (point.x - lineCoord)/2;
    float p2 = (otherPoint.x - lineCoord)/2;
    
    float k1 = point.y;
    float k2 = otherPoint.y;
    
    float h1 = point.x - p1;
    float h2 = otherPoint.x - p2;
    
    float a = 4 * (p2 - p1);
    float b = 8 * (k2 * p1 - k1 * p2);
    //float c = 16 * p1 * p2 * (h1 - h2); 
    float cY = 16 * p1 * p2 * (h1 - h2);
    float cZ = 4 * (p2 * k1 * k1 - p1 * k2 *k2 );
    float c = cY+cZ;
    double disc = (double)(b*b - 4*a*c);    
    
    if(disc >= 0){
      points = new PVector[2];
      float rt = (float)Math.sqrt(disc);
      
      float y1 = (-b + rt)/(2*a);
      float y2 = (-b - rt)/(2*a); 
      
        //find x1
        float x1 = y1 - k1;
        x1 *= x1;
        x1 = x1/4;
        x1  = x1/p1;
        x1 += h1;
        //ellipse(x1, y1, 2, 2);
    
        //find x2
        float x2 = y2 - k2;
        x2 *= x2;
        x2 = x2/4;
        x2  = x2/p2;
        x2 += h2; 
        //ellipse(x2, y2, 2, 2);  
    
       if(y1 > y2){
         points[0] = new PVector(x2,y2);
         points[1] = new PVector(x1,y1);   
       }else{
         points[0] = new PVector(x1,y1);
         points[1] = new PVector(x2,y2);
       }
      fill(0,0,150);
      
      ellipse(x1, y1, 5, 5);
      ellipse(x2, y2, 5, 5);
      fill(0);     
    }
    
    return points;
}


//DRAWING STUFF
void drawCircleEvents(){ 
  fill(0,255,255);
  for(CircleEvent circleEvent : circleEvents){
     
    ellipse(circleEvent.circle.getRightmostPoint().x, circleEvent.circle.getRightmostPoint().y, 2,2);

  }
  fill(255);
}
void drawCircles(){
  //fill(255);
  noFill(); 
  stroke(150);
  for(CircleEvent circleEvent : circleEvents){
    
    ellipse(circleEvent.circle.center.x, circleEvent.circle.center.y, circleEvent.circle.radius*2, circleEvent.circle.radius*2);
  }  
  fill(255); 
}

void drawVertices(){
  fill(0,255,0);
  for(VoronoiVertex v : voronoi){
    ellipse(v.point.x, v.point.y, 10, 10);   
  }
  fill(0); 
}

void drawEdges(){
 fill(0,150,0); 
 for(int i = 0; i < seed; i++){
   for(int j = 0; j < seed; j++){
     Edge e = edges[i][j];
     if(e!=null){
      line(0, e.getY(0), width, e.getY(width));    
     }
   }  
 }
}


Edge getOrCreateEdge(Site site1, Site site2){
  Edge e = edges[site1.index][site2.index];
  if(e == null){              
    e = new Edge(site1, site2);
    edges[site1.index][site2.index] = e;
  }  
  return e;
}

void drawPossibleIntersections(){ 
  fill(255,0,0);
  stroke(0);
  for(PVector point : possibleIntersections){
    ellipse(point.x, point.y, 5, 5);   
  }
  fill(255,255,255); 
}

void drawUnderlyingArc(PVector point){
  ArcNode arcNode = getUnderlyingArc(point);
  if(arcNode !=null){
    strokeWeight(2);
    stroke(255,0,0);
    float startY = arcNode.startY;
    if(startY < 0){
      startY = 0;  
    }
    float endY = arcNode.endY;
    if(endY > height){
      endY = height;  
    }
    for(float y = startY; y < endY; y+=.2){
      PVector point1 = getPoint(arcNode, y);
      if(point1 != null){
        point(point1.x, point1.y); 
      }  
    }
    strokeWeight(1);
    stroke(0); 
  }  
}
boolean isOffScreen(PVector point){
  return point == null || point.x < 0 || point.y < 0 || point.x > width || point.y > height;  
}

void keyPressed(){
 if(keyCode == LEFT){
   if(!events.isEmpty()){
      Event event = events.poll();
      currentEvent = event; 
      lineCoord = event.point.x; 
      if((int)lineCoord == (int)event.point.x){
        if(event instanceof SiteEvent){
          updateEndPoints();
          processSiteEvent((SiteEvent)event); 
        }else if(event instanceof CircleEvent){
          processCircleEvent((CircleEvent)event); 
          updateEndPoints();  
        }else{
          
          updateEndPoints(); 
        }
      }
    }else{       
      if(restart){       
        initialize(); 
      }else{         
        background(0); 
        drawSites();  
        drawVertices();
        for(VoronoiVertex v : voronoi){
          println("Vertex at : "+v.point);   
        }
      }
      restart = !restart;
    }
    //saveFrame();   
 }else if(keyCode == ENTER){
   initialize();
 }
  
}

void draw(){

  
  background(255);
  stroke(0);
   
 drawCircles(); 
  drawCircleEvents();
  drawSites();
  drawOthers();
  drawArcPoints();
  /*if(!events.isEmpty()){ 
    drawParabolas();
  }*/
  //drawPossibleIntersections();
  //drawEdges();
  stroke(150);
  for(int i = 0 ; i < seed; i++){
    for(int j = 0; j < seed; j++){
      Edge edge = edges[i][j];
      if(edge!=null){
        if(edge.start != null && edge.end!=null){
           line(edge.start.x, edge.start.y, edge.end.x, edge.end.y); 
        
        }else{
          if(edge.end !=null){
            stroke(0,150,150);
            float y = edge.b;
            line(0, edge.b, edge.end.x, edge.end.y); 
            stroke(0);
          }
          if(edge.start!=null){
            stroke(150,150,0);
            line(width, width*edge.m+edge.b, edge.start.x, edge.start.y); 
          }    
          
        }
      }
    }  
  }
  stroke(0);
  drawVertices(); 
  line(lineCoord, 0, lineCoord, height);
  if(currentEvent!=null){
      
       
      if(isOffScreen(currentEvent.point)){
        //println("The current point is off of the screen "+currentEvent.point); 
      }
      else{
        if(currentEvent instanceof SiteEvent){
          fill(200,0,200);
          drawUnderlyingArc(currentEvent.point);
        }else if (currentEvent instanceof CircleEvent){
          noFill();
          strokeWeight(3);
          CircleEvent circleEvent = (CircleEvent)currentEvent;
          ellipse(circleEvent.circle.center.x, circleEvent.circle.center.y, circleEvent.circle.radius*2, circleEvent.circle.radius*2); 
          line(circleEvent.circle.center.x, circleEvent.circle.center.y, circleEvent.point.x, circleEvent.point.y); 
          fill(0,255,0);
       strokeWeight(1);   
          
        }else{
         drawUnderlyingArc(currentEvent.point); 
        }
       stroke(150);
        line(0, currentEvent.point.y, width, currentEvent.point.y);
         stroke(0);
        
        strokeWeight(5);
        ellipse(currentEvent.point.x, currentEvent.point.y, 15, 15);
        strokeWeight(1);
      }
      stroke(0); 
      fill(255);
  }
  //noLoop(); 
     
}

//EVENT PROCESSING
void processSiteEvent(SiteEvent event){
  ArcNode arcNode = getUnderlyingArc(event.point);
 
  if(arcNode !=null){
    if(arcNode.circleEvent !=null){
      events.remove(arcNode.circleEvent);
      circleEvents.remove(arcNode.circleEvent); 
      possibleIntersections.remove(arcNode.circleEvent.circle.center);
      arcNode.circleEvent = null; 
      //remove this event from the queue since it's a false alarm  
    }
    //split and insert our new arc
    ArcNode   newArcNode = new ArcNode(event.site);
    insertArcNode(arcNode, newArcNode);
    ArcNode lower = newArcNode.previous;
    ArcNode upper = newArcNode.next;
    if(lower != null){  
      Edge e1 = getOrCreateEdge(lower.site, event.site);
      checkForCircleEvent(lower);
    }
    if(upper!=null){
      Edge e2 = getOrCreateEdge(event.site, upper.site);
      checkForCircleEvent(upper);
    } 
  }else{
    ArcNode newArcNode = new ArcNode(event.site);
    insertArcNode(arcNode, newArcNode);
  }
}

void processCircleEvent(CircleEvent event){
  //grab the middle arc 
  ArcNode arcNode = event.middleArc;  
  ArcNode lower = arcNode.previous;
  ArcNode upper = arcNode.next;
  
  if(lower == null || upper == null){
    //i don't think there's ever a case where this could happen, but... 
    println("Something went wrong left or right is null");
    return; 
  }
  if(lower.circleEvent !=null){
    events.remove(lower.circleEvent);
    circleEvents.remove(lower.circleEvent);
    possibleIntersections.remove(lower.circleEvent.circle.center);
    lower.circleEvent = null; 
  }
  if(upper.circleEvent !=null){
    events.remove(upper.circleEvent);
    circleEvents.remove(upper.circleEvent); 
    possibleIntersections.remove(upper.circleEvent.circle.center);
    upper.circleEvent = null; 
  }
    
  //event.center, even.point => rightmost X coordinate
  PVector point = event.circle.center; 
  VoronoiVertex v = new VoronoiVertex(point);
  voronoi.add(v); 
  
  Edge e1 = getOrCreateEdge(lower.site, arcNode.site);
  
  if(e1.end !=null){
    e1.start = e1.end;  
  }
  e1.end = v.point; 
  
  e1 = getOrCreateEdge(arcNode.site, lower.site);
  e1.end = v.point;
  
  Edge e2 = getOrCreateEdge(upper.site, arcNode.site);
  if(e2.end !=null){
    e2.start = e2.end;
  }
  e2.end = v.point;
   
  e2 = getOrCreateEdge(arcNode.site, upper.site);
  e2.end = v.point;
  
  Edge edge = getOrCreateEdge(lower.site, upper.site);
  edge.start = v.point; 
  edge = getOrCreateEdge(upper.site, lower.site);
  edge.start = v.point;
  
  //TODO - implement bounding cell logic, will need half edges to to this
  //need to complete half edges going into vertex (
    //add to head of list for left
    //add to tail of list for right
   
  //new HalfEdge out of the edge;
  //halfedge.start = point;
  
  //check for potential circle events for the remaining parabolas (left and right);
  removeArcNode(arcNode);  
  circleEvents.remove(event); 
  checkForCircleEvent(upper);
  checkForCircleEvent(lower);
}


//checks the triplet where arcNode is the central arc to see if it will potentially be closed out by the surrounding arcs
//adds a circle event to the queue if that is the case
void checkForCircleEvent(ArcNode arcNode){
  ArcNode lower = arcNode.previous;
  ArcNode upper = arcNode.next;
  
  //we need to be testing triples, so we're missing something otherwise
  //todo - verify whether the site-matching is actually an issue (will make
  //us miss and potential circle events... probably not?
  if(lower!=null && upper!=null && !lower.site.equals(upper.site)){
    Edge e1 = getOrCreateEdge(lower.site, arcNode.site);
    Edge e2 = getOrCreateEdge(arcNode.site, upper.site);
    
    PVector intersection = getPossibleIntersection(e1, e2);
    if(intersection !=null){
      
     boolean converge = true;  
     
     PVector mid1 = e1.mid;
     PVector mid2 = e2.mid;
     
     PVector v1 = new PVector(mid1.x-intersection.x, mid1.y-intersection.y);
     PVector v2 = new PVector(intersection.x-mid2.x, intersection.y-mid2.y);
     
     PVector cross = v2.cross(v1);
     
     //converge = cross.z < 0; 
     
     if(!converge){
        
       return;  
     }
    
     //will return if e1 == e2 or e1 || to e2
     Circle circle = new Circle(lower.site, arcNode.site, upper.site);
     if(circle!=null){
       float radius = circle.radius;
       if(circle.center.x + radius > lineCoord){
         CircleEvent circleEvent = new CircleEvent(circle.getRightmostPoint(), circle, arcNode);
         if(arcNode.circleEvent!=null){   
           events.remove(arcNode.circleEvent);
           circleEvents.remove(arcNode.circleEvent); 
         }
         arcNode.circleEvent = circleEvent; 
         events.add(circleEvent); 
         circleEvents.add(circleEvent);
         arcNode.circleEvent = circleEvent;  
         possibleIntersections.add(circle.center); 
       }else{
         println("circle event is behind the sweepline, do no add"); 
       }  
     }
    }
  }
}
   
       
PVector getPossibleIntersection(Edge e1, Edge e2){
  PVector intersection = null;
  if(!e1.equals(e2)){
    float m1 = e1.m;
    float m2 = e2.m;
    float b1 = e1.b;
    float b2 = e2.b;

    float x = (b2 - b1) / (m1 - m2);
    float y = m1*x + b1;
    intersection = new PVector(x,y); 
    ellipse(x, y, 2, 2);    
  }
  return intersection;   
}

void drawSites(){
  stroke(0);
  fill(255,0,255);
  for(Site site : sites){
    fill(colorX[site.index], 0, colorY[site.index]);
    ellipse(site.point.x, site.point.y, 10, 10); 
  }  
}


void drawParabola(PVector point, float start, float end){
  //line -> x = 600
  //point -> (400, 400)
  //vertex = (500, 400)
  //p = 200
  //x = (y - k)^2 / 4 * p + h
  
  float p = point.x - lineCoord;
  float k = point.y;
  float h = point.x - p/2; 
   
  float startY = start;
  if(startY < 0){
    //not worth drawing this portion
    startY = 0;  
  }
  
  float endY = end;
  if(endY > height){
    endY = height;  
  }
   
  if(p!=0){
    for(float j = startY; j <= endY; j++){
      float y = j;
      //x = y - k
      float x = y - k;
      x *= x;
      x = x/4;
      x  = x/p;
      x += h;
      point(x,y);
    }
  }
  
}

ArcNode getUnderlyingArc(PVector point){
  ArcNode node = rootNode;
  ArcNode bestNode = node;
  while(node != null){
    if(point.y == node.site.point.y){
      bestNode = node;  
    }else{
      if(node.startY <= point.y && node.endY >= point.y){
        bestNode = node; 
      }
    }
    node = node.next;
  }
  return bestNode;
}

