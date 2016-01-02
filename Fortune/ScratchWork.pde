
void drawParabolas(){
 //draw yer points
 //update color to light grey
 int myColor = 0;
 stroke(myColor);
 strokeWeight(7);
 float y = 0;  
  ArcNode arcNode = rootNode;
  if(arcNode !=null){
    while(arcNode.next!=null){
      stroke(myColor);
      //drawParabola(arcNode.site.point,1);
      ArcNode next = arcNode.next;
      boolean keepGoing = true;
      while(keepGoing && y < height){
        PVector here = getPoint(arcNode,y);
        PVector nextPoint = getPoint(next,y);
        if(here == null){
          here = nextPoint; 
        }
        if(nextPoint == null){
          nextPoint = here;   
        }
        if(here != null){
          point(here.x, here.y); 
          keepGoing = here.x > nextPoint.x;  
        }
        y+=.2;  
      }
      arcNode = next;
       myColor = myColor + 40;     
    }
    while(y < height){
      
      PVector point = getPoint(arcNode, y);
      if(point!=null){
        point(point.x, point.y);   
      }
      y++;
    }
  }
  strokeWeight(1); 
}

void updateEndPoints1(){
  ArcNode node = rootNode; 
    while(node != null){
        //edge case - the sweepline is currently at a node site
        if(node.site.point.x == lineCoord){
          node.startY = node.site.point.y;
          node.endY = node.site.point.y;
        }else{
          if(node.previous !=null){
            node.startY = node.previous.endY;
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
                node.endY = intersections[0].y;              
              }else{
                node.endY = intersections[1].y;
              }  
            }
          }else{
            node.endY = MAX_INT;               
          }
      }
      println(node.site.point+" -["+node.startY+" to "+node.endY+"]");
      node = node.next; 
    }  
    println("======");
}

