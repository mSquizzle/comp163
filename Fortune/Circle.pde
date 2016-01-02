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
     //question - do we even need this math if we have the edges that connect in the center? 
     //http://paulbourke.net/geometry/circlesphere/ for calculations
     this.p1 = site1.point;
     this.p2 = site2.point;
     this.p3 = site3.point;
    
    this.site1 = site1;
    this.site2 = site2;
    this.site3 = site3; 
     
     float deltaY_21 = p2.y - p1.y;
     float deltaX_21 = p2.x - p1.x;
     float deltaY_32 = p3.y - p2.y;
     float deltaX_32= p3.x - p2.x;
     
     float mA = deltaY_21/deltaX_21;
     float mB = deltaY_32/deltaX_32;
     
     float centerX = (mA*mB*(p1.y - p3.y) + mB*(p1.x + p2.x)
        - mA*(p2.x+p3.x) )/(2* (mB-mA));
     float centerY = -1*(centerX - (p1.x+p2.x)/2)/mA +  (p1.y+p2.y)/2;
     
     center = new PVector(centerX, centerY);
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

