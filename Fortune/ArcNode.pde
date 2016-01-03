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
void insertArcNode(ArcNode current, ArcNode nodeToInsert){
  if(current == null){
    //in this case, we're setting the root
    rootNode = nodeToInsert;
  }
  else{
    if(current.site.point.x == nodeToInsert.site.point.x){
    //if these points are at the same x Coordinate, we shouldn't split, just insert in order
    //if we do split, this causes some issues with the beachline, and can trigger some false circle events
    //most importantly, this makes the beachline cross over itself, and it looks uuuuuuuugly
      println("FOUND TWO POINTS THAT SHARE THE SAME X AND ARE NEIGHBORS"); 
      if(current.site.point.y < current.site.point.y){
      //insert in order  
        
      }else{
      //insert in the other order
        
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
      
      //getOrCreateEdge(current.site, nodeToInsert.site); 
    }
  }
}

void removeArcNode(ArcNode arcNode){
  
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

PVector getPoint(ArcNode arc, float i){
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

