class Site{
  PVector point; 
  int index;
  Site(PVector point, int i){
    this.point = point;
    this.index = i;
  }  
  
  boolean equals(Site site){
    return this.point.equals(site.point) && this.index == site.index;  
  }
  
  int hashCode(){
    return point.hashCode();
  }
  
  String toString(){
    return index+" - "+point.toString();  
  }
}
