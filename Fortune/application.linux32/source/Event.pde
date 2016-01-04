
class Event implements Comparable{
  PVector point;
  
  Event(PVector point){
    this.point = point;   
  }
  
  int compareTo(Object o){
    Event event = (Event)o;
    //blow it up a bit, althought it's unlikely that we're going to have this issue
    int diff = (int)(100*this.point.x - 100*event.point.x); 
    if(diff == 0){
      //we shouldn't really get here, but OK
      diff = (int)(100*this.point.y - 100*event.point.y);
    }
    return diff;   
  }
  
  String toString(){
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

