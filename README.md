# comp163
Putterings for Comp 163

#Fortune's Algorithm (In Progress)

##Description:

Fortune's algorithm is a sweepline algorithm that is able to efficiently construct the Voronoi Diagram of a set of points.

##Psuedo Code
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
}
```
```
processCircleEvent(CircleEvent e){
  Arc arcToBeRemoved <- the arc that is going to get closed out (in this case, the middle arc that generated this circle event)
  remove arcToBeRemoved from the beachline
  Arc left <- arcToBeRemoved's left neighbor
  Arc right <- arcToBeRemoved's right neighbor
  
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
