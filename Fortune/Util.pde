
void updateParabolaIntersections(){
  if(rootNode !=null){
    ArcNode arcNode = rootNode;
    while(arcNode != null){
      updateArcEndpoints(arcNode);
      arcNode = arcNode.next;
    }
  }
}

//operates under the assumption we're always performing an upwards 
//sweep in our beachfront in order to avoid double calculations
void updateArcEndpoints(ArcNode arcNode){
  if(arcNode.previous == null){
    arcNode.startY = 0;  
  }else{
    arcNode.startY = arcNode.previous.endY;  
  }
  if(arcNode.next == null){
    arcNode.endY = height; 
  }else{
    //note, this is not the correct logic for updates
    float y = findParabolaIntersections(arcNode, arcNode.next);
    if(y > 0){
      //arcNode.endY// = findParabolaIntersections(arcNode, arcNode.next);  
      arcNode.endY = y;
    }
  }
}

float findParabolaIntersections(ArcNode arcNode, ArcNode other){
  fill(255,0,0);
    
  PVector point = arcNode.site.point;
  PVector otherPoint = other.site.point;
  
  float p1 = point.x - lineCoord;
  float p2 = otherPoint.x - lineCoord;
    
  float k1 = point.y;
  float k2 = otherPoint.y;
    
  float h1 = point.x - p1/2;
  float h2 = otherPoint.x - p2/2;
    
  float a = 4 * (p2 - p1);
  float b = 8 * (k2 * p1 - k1 * p2);
  //float c = 16 * p1 * p2 * (h1 - h2); 
  float cY = 16 * p1 * p2 * (h1 - h2);
  float cZ = 4 * (p2 * k1 * k1 - p1 * k2 *k2 );
  float c = cY+cZ;
  double disc = (double)(b*b - 4*a*c); 
    
  if(disc >= 0){
    float rt = (float)Math.sqrt(disc);
      
    float y1 = (-b + rt)/(2*a);
    float y2 = (-b - rt)/(2*a); 
      
    if(y1 > 0 && y1 < height){
        //find x1
       float x1 = y1 - k1;
       x1 *= x1;
       x1 = x1/4;
       x1  = x1/p1;
       x1 += h1;
        ellipse(x1, y1, 2, 2);
        return y1;
      }
      if(y2 > 0 && y2 < height){
        //find x2
        float x2 = y2 - k2;
        x2 *= x2;
        x2 = x2/4;
        x2  = x2/p2;
        x2 += h2; 
        ellipse(x2, y2, 2, 2);
        //we need to return this part
        //arcNode.endY = y2;   
      } 
      //return y1;
    }
    return -MAX_INT;
}


void drawArcPoints(){ 
 int x = 0;
 strokeWeight(3); 
 ArcNode node = rootNode;
 
 while(node!=null){
   stroke(x, 255, 0);
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
     y+=.2;
   }
   node = node.next; 
   x+=100;   
 } 
 strokeWeight(1);
}
