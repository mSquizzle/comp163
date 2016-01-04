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
  
  float getY(float x){
    float y;
    y = m*x + b;
    
    return y; 
  }
  
  float getX(float y){
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
  
  boolean isIncomplete(){
    return start == null || end == null; 
  }
}
