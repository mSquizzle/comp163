//Cirle utilities
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
  
  PVector getRightmostPoint(){
    return new PVector(center.x + radius, center.y);  
  }
  
  PVector getLowestPoint(){
    return new PVector(center.x, center.y-radius); 
  }
  
  PVector getLeftmostPoint(){
    return new PVector(center.x - radius, center.y);  
  }
  
  PVector getHighestPoint(){
    return new PVector(center.x, center.y + radius); 
  } 
}

float distance(PVector point1, PVector point2){
  float dx = point1.x - point2.x;
  float dy = point1.y - point2.y; 
  float square = dx*dx + dy*dy;
  return sqrt(square);
}

