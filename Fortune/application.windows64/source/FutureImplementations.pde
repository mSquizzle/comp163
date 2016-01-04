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
