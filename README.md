# Comp 163
Putterings for Comp 163 - Fall 2015

#Fortune's Algorithm (In Progress)

##Description:

Fortune's algorithm is a sweepline algorithm that is able to efficiently construct the Voronoi Diagram of a set of points. It creates a beachline of parabolas, which are used to determine the location of Voronoi vertices (and link edges to those vertices). Through the use of the beachline and sweepline, we are able to cut down on the number of comparisions each point will need to make in order to determine the bounds of its cell. 

The algorithm stores events in a priority queue, organized by lowest y coordinate (_note that for the implementation with the video/code, the sweep is actually moving horizontally, I just liked the way it looked better, it doesn't actually make a difference_). There are two types of events that can be encountered in the queue, a Site Event or a Circle Event. 

A **Site Event** happens when the line sweeps across one of the input sites. This splits apart the arc currently under the site, and wedges a new parabola into that section of the beachline, using the current site as its focus. 

A **Circle Event** occurs when there is potential for a Voronoi vertex to be formed. _This algorithm generates a large number of false circle events, but they are removed from the queue before they can be processed as a part of handling of other events._ This happens when the middle arc of a triple of adjacent arcs on the beachline is getting squeezed out by its neighbors. The arc will disappear when its neighbors meet, which means that point is equidistance from 3 of the sites, and is thus a Voronoi vertex. Circle Events are organized by their top-most y coordinate (not by the center of the circle). The edges used to find the center of the circle are then added to the cells of the adjacent Voronoi cells. 

##Pseudo Code
**Input** - S, a set of points _we'll refer to these points as sites to avoid confusion_ 

**Output** - the Voronoi Diagram of that point set

```
intialize empty eventQueue
initialize empty beachline

for all sites in S
do:
  event <- create new site event for site S
  add to event to  eventQueue
  
while: eventQueue is not empty
do:
  event <- remove first event from eventQueue
  if(event is a site event){
    processSiteEvent(event)
  }else{//event is a circle event
    processCircleEvent(event)
  }
result will be the Vononoi Diagram of S
```
```
processSiteEvent(SiteEvent e){
  Arc arc <- find arc underneath e.site
  if(arc has generated a circle event){
    remove that circle event from the eventQueue
  }
  split apart arc into arcLeft and arcRight
  insert new arc into wedge
  checkForCircleEvent(arcLeft)
  checkForCircleEvent(arcRight)
}
```
```
processCircleEvent(CircleEvent e){
  Arc arcToBeRemoved <- the arc that is going to get closed out (in this case, the middle arc that generated this circle event)
  remove arcToBeRemoved from the beachline
  Arc left <- arcToBeRemoved's left neighbor
  Arc right <- arcToBeRemoved's right neighbor
  
  if(left has generated a circle event){
    remove that circle event from the queue
  }
  if(right has generated a circle event){
    remove that circle event from the queue 
  }

  Edge e1 = edge(left.site, arcToBeRemoved.site)
  Edge e2 = edge(arcToBeRemoved.site, left.site)
  Edge e3 = edge(left.ste, right.site)
  vertex <- create new vertex at intersection of e1 and e2
  
  e1.endpoint <- vertex
  e2.endpoint <- vertex
  e1.startPoint <- vertex
  
  add e1 to the cell for left.site
  add e2 to the cell for left.site
  
  checkForCircleEvent(left)
  checkForCircleEvent(right)
}
```
```
checkForCircleEvent(Arc arc){
  left = arc's left neighbor
  right = arc's right neighbor
  if(left is null)
    return
  if(right is null)
    return
  if(left and right were spawned from the same site)
    return 
  
  Edge e1 <- bisector of left and arc
  Edge e2 <- bisector of arc and right
  
  if(e1 and e2 converge){
    circle <- circle(left.site, arc.site, right.site)
    if(the highest point of the circle is above the sweepline){
      event <- create a new circle event (stored by highest point of circle, not center)
      add event to eventQueue
    }
  }
}
```

##Analysis
Fortune's Algorithm is considered efficient since it takes O(nlogn) time.

The first reason it is able to achieve that level of efficiency is due to the structure of the beachline. Since the beachline is stored as a balanced binary search tree, we are able to both update and query in O(log b) time (where b is the number of nodes in the tree). If we consider when the beachline is updated, it only increases in size when we encounter a new Site Event, which splits the current arc in two and inserts a new arc, leaving a net gain of 2 arcs. The only time this isn't true is at the beginning, when there are no arcs to split. This means that at most we have 2n-1 arcs present in the beachline at any given time. This allows us to claim that operations like searching and updating the beachline takes only O(log n) instead of O(n).

This leaves our queue as the other place to potentially drive up run time. If we consider the number of events that will be in our queue, we'll find that it is O(n). So if we're able to select a structure that can be modified and queried in O(log n) time, then our interactions with the queue will not exceed O(n log n).  

Other operations, like checking for circle events, or updating pointers can be done in constant time. Overall, this leaves us with an O(n long n) algorithm for finding the Voronoi Diagram of a set of points. 
 
##TODOs:

####Explanations
+ provide images for examples
+ elaborate on event processing in demo

####Functionality
+ fix beachline errors
+ correct high-lighting issues
+ remove false-positives
+ finish edge-work
+ allow user-input (or more randomly generated sequences at a minimum). 
