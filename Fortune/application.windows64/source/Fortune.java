import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Fortune extends PApplet {

 
 
float DEFAULT_DENSITY = 1.0f;
int DEFAULT_SEED = 10; 

int DEFAULT_HEIGHT = 1000;
int DEFAULT_WIDTH = 1000; 

//aka beachfront
ArcNode rootNode;

//sweepline
float lineCoord;
int seed = DEFAULT_SEED;
int margin = 200;

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

//various debugging configurations, don't worry about these.
//int[] debugX = {101, 200, 150/*303*/, 440, 442, 579, 664, 775};
//int[] debugX = {301, 500, 350/*303*/, 640, 642, 779, 864, 975};
//int[] debugY = {30, 500, 500/*650*/,250, 851, 551, 224, 766};

//int[] debugX = {200, 400, 600, 800};
//int[] debugY = {400,400,400, 400};

int[] debugX = {200, 400, 350, 300, 300};
int[] debugY = {400, 400, 200, 300, 300};
Event currentEvent;

boolean drawArcs;
boolean drawCircles;
boolean drawVertices;
boolean record;
boolean drawSiteEllipses;

Set<PVector> points;

public void setup(){
  size(DEFAULT_HEIGHT, DEFAULT_WIDTH);
  drawArcs = false;
  drawCircles = false;
  drawVertices = true; 
  record = false;
  drawSiteEllipses = true; 
  
  //debug = true;
  
  if(debug){
    seed = debugX.length;
  }
 
  points = new HashSet<PVector>(seed);
  sites = new ArrayList<Site>(seed);
  cells = new Cell[seed];
  for(int i = 0; i < seed; i++){
    int x;
    int y;
    if(debug){
      x = debugX[i];
      y = debugY[i];
    }else{
      x = (int)random(margin, height - margin);
      y = (int)random(margin, height - margin); 
    }
    //sloppy, but whatevs 
    
    PVector potentialPoint = new PVector(x,y);
    
    while(points.contains(potentialPoint)){
      x = (int)random(margin, height - margin);
      y = (int)random(margin, height - margin);        
      potentialPoint = new PVector(x,y);
    }
    points.add(potentialPoint); 
    Site site = new Site(potentialPoint, i);
    sites.add(site);
    cells[i] = new Cell(site);
  }
  initialize();
  restart = false;   
}

boolean restart;
boolean debug;  
public void initialize(){ 
  rootNode = null;   
  //println(seed);
  edges = new Edge[seed][seed]; 
  cells = new Cell[seed];
  lineCoord = 0;
  possibleIntersections = new ArrayList<PVector>(); 
  circleEvents = new ArrayList<CircleEvent>();
  voronoi = new ArrayList<VoronoiVertex>();
  createEvents();
  currentEvent = null;
}

public void createEvents(){
  events = new PriorityQueue<Event>(seed*3); 
  for(Site site : sites){
    Event siteEvent = new SiteEvent(site);
    events.add(siteEvent);
    if(debug){
      events.add(new Event(new PVector(site.point.x+10, site.point.y)));
      events.add(new Event(new PVector(site.point.x+20, site.point.y)));
      events.add(new Event(new PVector(site.point.x+30, site.point.y)));
      events.add(new Event(new PVector(site.point.x+40, site.point.y)));
    }
  }
    events.add(new Event(new PVector(width*20, height/2)));   
}

public void drawOthers(){
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

public void updateEndPoints(){
  ArcNode node = rootNode; 
  while(node != null){
    //edge case - the sweepline is currently at a node site
    if(node.site.point.x == lineCoord){          
      node.startY = node.site.point.y;
      node.endY = node.site.point.y;
    }else{
      if(node.previous !=null){
        node.startY = node.previous.endY;
        Edge e1 = getOrCreateEdge(node.previous.site, node.site);
        PVector p = getPoint(node, node.startY);
        if(p !=null){
          e1.end = p;   
        }
      }else{
        node.startY = -MAX_INT;
      }
      if(node.next != null){
        //the lower intersection will be stored at index 0 
        if(node.next.site.point.x == lineCoord){
          node.endY = node.next.site.point.y; 
        }else{
          PVector[] intersections = findArcIntersections(node, node.next);
          //println("Intersections ["+intersections[0]+","+intersections[1]+"]");
          if(node.site.point.x < node.next.site.point.x){
            //this arc was possibly split by the next arc
            //choose the lower endpoint
            node.endY = intersections[0].y;                        
          }else if(node.site.point.x == node.next.site.point.x){
            float dy = node.site.point.y - node.next.site.point.y;
            node.endY = node.site.point.y - dy/2;
          }else{
            //otherwise, this arc did the splitting, choose the upper endpoint
            node.endY = intersections[1].y;
          }  
        }
      }else{
        node.endY = MAX_INT;               
      }
    }
    node = node.next; 
  }  
 // println("===============");
}

//return null, or a pair of PVectors where
public PVector[] findArcIntersections(ArcNode arcNode, ArcNode other){
  fill(255,0,0);
 
  PVector point = arcNode.site.point;
  PVector otherPoint = other.site.point;
  //this is just for consistency
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

    //find x2
    float x2 = y2 - k2;
    x2 *= x2;
    x2 = x2/4;
    x2  = x2/p2;
    x2 += h2; 

   if(y1 > y2){
     points[0] = new PVector(x2,y2);
     points[1] = new PVector(x1,y1);   
   }else{
     points[0] = new PVector(x1,y1);
     points[1] = new PVector(x2,y2);
   }   
  }else{
    println("There is no intersection for "+point+" and "+otherPoint+" when lineCoord is at "+lineCoord);
    println(disc);  
  } 
  return points;
}

//DRAWING STUFF
public void drawCircleEvents(){ 
  fill(0,255,255);
  for(CircleEvent circleEvent : circleEvents){     
    ellipse(circleEvent.circle.getRightmostPoint().x, circleEvent.circle.getRightmostPoint().y, 2,2);
  }
  fill(255);
}
public void drawCircles(){
  noFill(); 
  stroke(150);
  for(CircleEvent circleEvent : circleEvents){
    ellipse(circleEvent.circle.center.x, circleEvent.circle.center.y, circleEvent.circle.radius*2, circleEvent.circle.radius*2);
  }  
  fill(255); 
}

public void drawVertices(){
  fill(0,255,0);
  for(VoronoiVertex v : voronoi){
    ellipse(v.point.x, v.point.y, 10, 10);   
  }
  fill(0); 
}


public Edge getOrCreateEdge(Site site1, Site site2){
  Edge e = edges[site1.index][site2.index];
  if(e == null){              
    e = new Edge(site1, site2);
    edges[site1.index][site2.index] = e;
  }  
  return e;
}

public void drawPossibleIntersections(){ 
  fill(255,0,0);
  stroke(0);
  for(PVector point : possibleIntersections){
    ellipse(point.x, point.y, 5, 5);   
  }
  fill(255,255,255); 
}

public void drawUnderlyingArc(PVector point){
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
    for(float y = startY; y < endY; y+=.2f){
      PVector point1 = getPoint(arcNode, y);
      if(point1 != null){
        point(point1.x, point1.y); 
      }  
    }
    strokeWeight(1);
    stroke(0); 
  }  
}

public boolean isOffScreen(PVector point){
  return point == null || point.x < 0 || point.y < 0 || point.x > width || point.y > height;  
}

public void keyPressed(){
 if(keyCode == RIGHT){
   //todo - implement stacking functionality for events so we can go back and forth
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
          //we've hit a debugging event, so we should only continue to draw our graph
          updateEndPoints(); 
        }
      }
    }else{       
      if(restart){       
        initialize(); 
      }else{         
        background(0); 
        drawSites();  
        if(drawVertices){
          drawVertices();
        }
      }
      restart = !restart;
    }   
 }else if(keyCode == ENTER){
   initialize();
 } else if(keyCode == 'P'){
     drawArcs = !drawArcs;
 } else if(keyCode == 'C'){
    drawCircles = !drawCircles; 
 } else if(keyCode == 'V'){
   drawVertices = !drawVertices;  
 } else if(keyCode == 'R'){
   record = !record;  
   if(record){
     println("Currently recording!"); 
   }else{
     println("Recording has been turned off."); 
   }  
 } else if(keyCode =='E'){
   drawSiteEllipses = !drawSiteEllipses;
 } else if(keyCode == 'I'){
   seed++;
   println("Seed increased to "+seed);
   setup(); 
 } else if(keyCode == 'D'){
   seed--;
   if(seed < 3){
      seed = 3; 
   }
   println("Seed decreased to "+seed);
   setup();
 } else if(keyCode =='Q'){
   setup();  
 } else if(keyCode == 'A'){
   margin -= 10;
   if(margin < 10){
     margin = 10;
   }  
 } else if(keyCode == 'S'){
   margin += 10;
   if(margin > height/2){
     margin = height/4;  
   }
 }
 
 if(record){
   saveFrame();  
 } 
}

public void draw(){  
  background(255);
  stroke(0);
   
 if(drawCircles){  
   drawCircles(); 
   drawCircleEvents();
  }
  drawSites();

  if(drawArcs){
    drawOthers();
  }
  drawArcPoints();

  stroke(150);
  for(int i = 0 ; i < seed; i++){
    for(int j = 0; j < seed; j++){
      Edge edge = edges[i][j];
      if(edge!=null){
        if(edge.start != null && edge.end!=null){
           line(edge.start.x, edge.start.y, edge.end.x, edge.end.y); 
        }
      }
    }  
  }
  stroke(0);
  if(drawVertices){
    drawVertices(); 
  }
  stroke(0);
  strokeWeight(1);
  line(lineCoord, 0, lineCoord, height);
  if(currentEvent!=null){
      if(isOffScreen(currentEvent.point)){
        //println("The current point is off of the screen "+currentEvent.point); 
      }
      else{
        if(currentEvent instanceof SiteEvent){
          fill(200,0,200);
          if(debug){
            drawUnderlyingArc(currentEvent.point);
          }
        }else if (currentEvent instanceof CircleEvent){
          noFill();
          strokeWeight(3);
          CircleEvent circleEvent = (CircleEvent)currentEvent;
          ellipse(circleEvent.circle.center.x, circleEvent.circle.center.y, circleEvent.circle.radius*2, circleEvent.circle.radius*2); 
          line(circleEvent.circle.center.x, circleEvent.circle.center.y, circleEvent.point.x, circleEvent.point.y); 
          fill(0,255,0);
          strokeWeight(1);   
          
        }else{
         if(debug){
           drawUnderlyingArc(currentEvent.point); 
         }
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
}

//EVENT PROCESSING
public void processSiteEvent(SiteEvent event){
  ArcNode arcNode = getUnderlyingArc(event.point);
 
  if(arcNode !=null){
    if(arcNode.circleEvent !=null){
      //remove this event from the queue since it's a false alarm
      events.remove(arcNode.circleEvent);
      circleEvents.remove(arcNode.circleEvent); 
      possibleIntersections.remove(arcNode.circleEvent.circle.center);
      arcNode.circleEvent = null; 
    }
    //split and insert our new arc
    ArcNode   newArcNode = new ArcNode(event.site);
    insertArcNode(arcNode, newArcNode);
    ArcNode lower = newArcNode.previous;
    ArcNode upper = newArcNode.next;
    if(lower != null){  
      Edge e1 = getOrCreateEdge(lower.site, event.site);
      e1.start = getPoint(lower, event.site.point.y); 
      checkForCircleEvent(lower);
    }
    if(upper!=null){
      Edge e2 = getOrCreateEdge(event.site, upper.site);
      e2.start = getPoint(upper, event.site.point.y);
      checkForCircleEvent(upper);
    } 
  }else{
    ArcNode newArcNode = new ArcNode(event.site);
    insertArcNode(arcNode, newArcNode);
  }
}

public void processCircleEvent(CircleEvent event){
  //grab the middle arc 
  ArcNode arcNode = event.middleArc;  
  ArcNode lower = arcNode.previous;
  ArcNode upper = arcNode.next;
  
  if(lower == null || upper == null){
    //this shouldn't happen, but putting it in just in case
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
  e1.end = v.point;
  
  Edge e2 = getOrCreateEdge(arcNode.site, upper.site);
  e2.end = v.point;
  
  Edge edge = getOrCreateEdge(lower.site, upper.site);
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
public void checkForCircleEvent(ArcNode arcNode){
  ArcNode lower = arcNode.previous;
  ArcNode upper = arcNode.next;
  
  //we need to be testing triples, so we're missing something otherwise
  //todo - verify whether the site-matching is actually an issue (will make
  //us miss and potential circle events... probably not?
  if(lower!=null && upper!=null && !lower.site.equals(upper.site)){
    Edge e1 = getOrCreateEdge(lower.site, arcNode.site);
    Edge e2 = getOrCreateEdge(arcNode.site, upper.site);
    
    PVector intersection = getPossibleIntersection(e1, e2);
    if(intersection == null && debug){
      println("no intersection found");  
    }
    //println(intersection);
    if(intersection !=null){
      
     boolean converge = true;  
     
     //if our points are ccw, then they converge
     PVector a = lower.site.point;
     PVector b = arcNode.site.point;
     PVector c = upper.site.point; 
     
     PVector v1 = new PVector(b.x - a.x, b.y - a.y);//b.sub(a);
     PVector v2 = new PVector(c.x - b.x, c.y- b.y);//c.sub(b);
     
     converge = v1.cross(v2).z < 0;
     
     if(!converge){        
         //println("no converge");
         return;  
     }
    
     //will return null if e1 == e2 or e1 || to e2
     Circle circle = new Circle(lower.site, arcNode.site, upper.site);
     if(circle!=null){
       if(circle.getRightmostPoint().x >= lineCoord){
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
       }else if (debug){
         println("circle event is behind the sweepline, do no add"); 
       }  
     }
    }
  }
}
       
public PVector getPossibleIntersection(Edge e1, Edge e2){
  PVector intersection = null;
  if(!e1.equals(e2) && !(e1.isVertical && e2.isVertical) && !(e1.m == e2.m)){
    if(e1.isVertical){
      float m2 = e2.m;
      float x = e1.mid.x;
      float y = e2.m*x + e2.b;
      intersection = new PVector(x,y);
    }else if(e2.isVertical){
      float m1 = e1.m;
      float x = e2.mid.x;
      float y = e1.m*x+e1.b;
      intersection = new PVector(x,y);
    }else{
      float m1 = e1.m;
      float m2 = e2.m;
      float b1 = e1.b;
      float b2 = e2.b;
  
      float x = (b2 - b1) / (m1 - m2);
      float y = m1*x + b1;
      intersection = new PVector(x,y); 
    }    
  }
  //println(intersection);
  return intersection;   
}

public void drawSites(){
  stroke(0);
  if(drawSiteEllipses){
    fill(255,0,255);
  }else{
    strokeWeight(2);  
  }
  for(Site site : sites){
    if(drawSiteEllipses){
      ellipse(site.point.x, site.point.y, 10, 10);
    }else{
      point(site.point.x, site.point.y); 
    } 
  }  
}


public void drawParabola(PVector point, float start, float end){
  //line -> x = 600
  //point -> (400, 400)
  //vertex = (500, 400)
  //p = 200
  //x = (y - k)^2 / 4 * p + h
  
  float p = (point.x - lineCoord)/2;
  float k = point.y;
  float h = point.x - p; 
   
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

//note, don't use this when processing a circle event
public ArcNode getUnderlyingArc(PVector point){
  ArcNode node = rootNode;
  ArcNode bestNode = node;
  float maxX = -MAX_INT;
  while(node != null){     
    if(node.startY <= point.y && node.endY >= point.y){
      bestNode = node;       
    }
    node = node.next;
  }
  return bestNode;
}

class ArcNode{
  ArcNode previous;
  ArcNode next;  
  
  float startY;
  float endY;

  int index; 
  //also need a reference to a circle event when that is implemented
  CircleEvent circleEvent;
  
  //the site that generated this arcnode
  Site site;
  
  ArcNode(Site site){
    this.site = site;  
  }
} 


//INSERTION AND DELETE -> currently set up as static methods, could rework to make depending on instance instead

//this is used to split apart the current arcNode, then insert our new arc ito the beachline
//note that this data structure is one of the reasons that we lose O(n log n) execution
//since it requires O(n) per lookup, as opposed to O(log n), which we would get with a balanced binary tree
public void insertArcNode(ArcNode current, ArcNode nodeToInsert){
  if(current == null){
    //in this case, we're setting the root
    if(rootNode == null){
      rootNode = nodeToInsert;  
    }else{
      //append to our list
      ArcNode node = rootNode;
      while(node.next != null){
        node = node.next;  
      }
      node.next = nodeToInsert;
      nodeToInsert.previous = node;  
    }
  }
  else{
    if(current.site.point.x == nodeToInsert.site.point.x){
    //if these points are at the same x Coordinate, we shouldn't split, just insert in order
    //if we do split, this causes some issues with the beachline, and can trigger some false circle events
    //most importantly, this makes the beachline cross over itself, and it looks uuuuuuuugly
      if(current.next !=null){
        //not sure if this is a case?
        ArcNode temp = current.next;
        temp.previous = nodeToInsert;
        nodeToInsert.next = temp; 

        current.next = nodeToInsert;
        nodeToInsert.previous = current;  
      }else{
        current.next = nodeToInsert;
        nodeToInsert.previous = current;
        
        Edge e = getOrCreateEdge(nodeToInsert.site,current.site);
        if(e.start == null){          
          e.start = e.mid;   
        }
      }            
    }else{
      ArcNode currentRight = new ArcNode(current.site);
      
      //step 1: introduce a clone of the current node and hook it up to the next node   
      currentRight.next = current.next;
      currentRight.previous = nodeToInsert;
      currentRight.startY = nodeToInsert.site.point.y;
      currentRight.endY = current.endY; 
     
      if(current.next != null){
        current.next.previous = currentRight;  
      }
      
      //step 2: hook up current node to the node to be inserted
      current.next = nodeToInsert;
      nodeToInsert.previous = current;
      current.endY = nodeToInsert.site.point.y;
      
      //step 3: hook up clone to the node to be inserted
      nodeToInsert.next = currentRight; 
      nodeToInsert.startY = nodeToInsert.site.point.y;
      nodeToInsert.endY = nodeToInsert.site.point.y;     
    }
  }
}

public void removeArcNode(ArcNode arcNode){
  
  ArcNode prev = arcNode.previous;
  ArcNode next = arcNode.next;
  
  if(prev !=null){
    prev.next = next;  
  }
  if(next!=null){
    next.previous = prev; 
  }
  
  //disconnect our node completely  
  arcNode.previous = null;
  arcNode.next = null; 
}

public PVector getPoint(ArcNode arc, float i){
  PVector calcPoint = null;
  
  PVector arcPoint = arc.site.point;
  float p = (arcPoint.x - lineCoord)/2;
  float k = arcPoint.y;
  float h = arcPoint.x - p; 
  if(p!=0){
    float y = i;
    //x = y - k
    float x = y - k;
    x *= x;
    x = x/4;
    x  = x/p;
    x += h;
    calcPoint = new PVector(x, i); 
  }
  return calcPoint;
}

//Cirlce utilities
class Circle{
  PVector center;
  
  float radius;
  
  PVector p1;
  PVector p2;
  PVector p3;
  
  Site site1;
  Site site2;
  Site site3;
  
  Circle(Site site1, Site site2, Site site3){
     this.p1 = site1.point;
     this.p2 = site2.point;
     this.p3 = site3.point;
    
    this.site1 = site1;
    this.site2 = site2;
    this.site3 = site3; 

     Edge e1 = getOrCreateEdge(site1, site2);
     Edge e2 = getOrCreateEdge(site2, site3);
     
    center = getPossibleIntersection(e1, e2);
     
    radius = distance(center, p1);  
  }  
  
  public PVector getRightmostPoint(){
    return new PVector(center.x + radius, center.y);  
  }
  
  public PVector getLowestPoint(){
    return new PVector(center.x, center.y-radius); 
  }
  
  public PVector getLeftmostPoint(){
    return new PVector(center.x - radius, center.y);  
  }
  
  public PVector getHighestPoint(){
    return new PVector(center.x, center.y + radius); 
  } 
}

public float distance(PVector point1, PVector point2){
  float dx = point1.x - point2.x;
  float dy = point1.y - point2.y; 
  float square = dx*dx + dy*dy;
  return sqrt(square);
}

class Edge{
  
  //TODO - NEED TO PUT IN BETTER HANDLING FOR VERTICAL LINES
  
  Site site1;
  Site site2;
 
  PVector start;
  PVector end; 
 
  PVector mid;
  
  float m;
  float b; 
  
  boolean isVertical; 
  Edge(Site site1, Site site2){
    this.site1 = site1;
    this.site2 = site2;  
    
    float dx = site1.point.x - site2.point.x;
    float dy = site1.point.y - site2.point.y;
    
    float midX = site1.point.x - dx/2;
    float midY = site1.point.y - dy/2 ;
    
    //now need to find b
    //y = mx + b
    //b = mx - y;
    if(dy == 0){
      isVertical = true;   
      m = -MAX_INT;
      mid = new PVector(midX,midY);
    }else{
      isVertical = false;
      m = -dx/dy;
      b = midY - m*midX;
      mid = new PVector(midX, midY); 
    }
  }
  
  public float getY(float x){
    float y;
    y = m*x + b;
    
    return y; 
  }
  
  public float getX(float y){
    float x;
    x = y - b;
    x = x/m;
    
    return x;  
  }
}


class HalfEdge extends Edge{
  HalfEdge twin;
  //direction?
  VoronoiVertex start;
  VoronoiVertex end;
  
  //reference to the cell that contains it? probably
  Cell parent; 
  
  //todo - contructor for this magnificent beast
  HalfEdge(Site site1, Site site2){
    super(site1, site2); 
    //probably need to do other stuff 
  }
  
  public boolean isIncomplete(){
    return start == null || end == null; 
  }
}

class Event implements Comparable{
  PVector point;
  
  Event(PVector point){
    this.point = point;   
  }
  
  public int compareTo(Object o){
    Event event = (Event)o;
    //blow it up a bit, althought it's unlikely that we're going to have this issue
    int diff = (int)(100*this.point.x - 100*event.point.x); 
    if(diff == 0){
      //we shouldn't really get here, but OK
      diff = (int)(100*this.point.y - 100*event.point.y);
    }
    return diff;   
  }
  
  public String toString(){
    return point.toString();  
  }
}


class SiteEvent extends Event{
  //need to determine any other information we need to keep in store
  Site site;
  SiteEvent(Site site){
    super(site.point);
    this.site = site;  
  } 
}

class CircleEvent extends Event{
  Circle circle;
  ArcNode middleArc;
  CircleEvent(PVector point, Circle circle, ArcNode arc){
     super(point);
     this.circle = circle;
     this.middleArc = arc; 
  }
}

//TODO - FINISH IMPLEMENTING
class Cell{
  Site site;
  //list of edges in CCW order
  //list of Voronoi vertices? 
  ArrayList<Edge> edges;
  Cell(Site site){
    this.site = site;
    edges = new ArrayList<Edge>();  
  }
}


//TODO - FINISH IMPLEMENTING
class VoronoiVertex{
  PVector point;
  ArrayList<Edge> connectedEdges;
  VoronoiVertex(PVector point){
    this.point = point;
    this.connectedEdges = new ArrayList<Edge>();  
  } 
}
class Site{
  PVector point; 
  int index;
  Site(PVector point, int i){
    this.point = point;
    this.index = i;
  }  
  
  public boolean equals(Site site){
    return this.point.equals(site.point) && this.index == site.index;  
  }
  
  public int hashCode(){
    return point.hashCode();
  }
  
  public String toString(){
    return index+" - "+point.toString();  
  }
}
public void drawArcPoints(){ 
 int x = 0;
  
 ArcNode node = rootNode;
 int b = 0;
 if(debug){
   b = 255;   
   strokeWeight(3);
 }
 
 while(node!=null){
   stroke(x, b, 0);
   float y = node.startY;
   if(node.startY < 0){
     y = 0;
   }
   float limit = node.endY;
   if(node.endY > height){
     limit = height;  
   }
   while(y < limit){
     PVector point = getPoint(node, y);
     if(point!=null){
        point(point.x, point.y);  
     }
     y+=.2f;
   }
   node = node.next;
  if(debug){ 
     x+=50;  
  } 
 } 
 strokeWeight(1);
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--full-screen", "--bgcolor=#666666", "--stop-color=#cccccc", "Fortune" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
