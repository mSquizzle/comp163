# Fortune's Algorithm (Done...ish)

## Application

This project was developed in Processing (version 2.2.1)  and the source files are available under /Fortune. I've provided the exported versions of this application for Windows and Linux. Unfortunately, I do not have access to a Mac, and cannot export to one (this is a known limitation of Processing's export). If you're using a Mac and would like to use the application, you will need to download Processing and perform the export manually. 

The following controls are available:

Key | Action
----|-----
Right Arrow | Moves the simulation forward. Will loop around to restart the simulation with the current points set once all of the events have been processed.
Enter | Restarts the simulation with the current set of points.
P | Toggles drawing the complete parabolas that are in the beach line.
C | Toggles drawing the circle events currently in the event queue.
V | Toggles drawing the completed Voronoi vertices as green circles.
R | Toggles recording. This can be useful for debugging; I've used this to make some of the sample materials. When enabled, this saves a screen shot every time a key is pressed.
E | Toggles drawing the input point set as purple circles.
I | Increases the seed value of the input point set and restarts the simulation. *There is an issue when points are too densely placed, so it is not recommended to make this higher than 50 without increasing the dimensions of the application* (you'll need to edit the code to do this).
D | Decreases the seed value of the input point set and restarts the simulation. This cannot be less than three. 
Q | Creates a new point set and restarts the simulation.
A | Decreases the margin which bounds the points. Must be at least 10.
S | Increases the margin with bounds the points. Will get reset if height/2 is reached. 

Note: this is not an entirely faithful implementation of Fortune's algorithm. I'm currently storing the beach line as a doubly-linked list, whereas the beach line described by Fortune is implemented as a balanced binary tree. I also do not completely construct the data structures that support the cells, since I'm only visualizing them. 

## Description:

### Voronoi Diagrams 
Before a discussion of Fortune’s algorithm can be discussed, we need to quickly explain the goal of the algorithm: finding the Voronoi diagram. Given a set of sites, a Voronoi diagram constructs a cell for each site, where all the points contained in that cell are closer to that site than any other site in the set. 

One of the primary uses of Voronoi diagrams are for planning purposes. For example, if a town wants to add a new school that will cover the most area (reducing areas covered by other schools), it will need to figure out which neighborhoods are closest to the already existing schools. The town will need to place the school at the corner of a cell in order to optimize the number of neighborhoods that will be contained in the new school’s district. 

The boundaries of these cells are formed by bisectors between adjacent sites. Corners are formed by the intersection of one or more of these bisectors.

### Algorithm
Fortune's algorithm is a sweepline algorithm that is able to efficiently construct the Voronoi Diagram of a set of points. It creates a beach line of parabolas, which are used to determine the location of Voronoi vertices (and link edges to those vertices). Through the use of the beach line and sweepline, we are able to cut down on the number of comparisions each point will need to make in order to determine the bounds of its cell. The algorithm generates events based off of sites and the beach line. These are stored in a priority queue, organized by lowest y coordinate\*. The sweep line moves through the plane by jumping from event to event.

The **beach line** is a monotone structure composed of arcs, which are the visible portions (from the sweepline) of the parabolas generated using the sites as foci and the sweepline as the directrix.

At any given time, when two arcs are neighbors in the beachline, the sites that generated those arcs are also neighbors in the Voronoi diagram. The intersections of these arcs (referred to breakpoints in most descriptions of this algorithm), trace along Voronoi edges (which are the bisectors of those two points). This happens because the parabolas that form these arcs are using the same directrix, so not only are the breakpoints equidistant from the sites, they’re also the same distance away from the sweepline. Another way to think about this is that each breakpoint in the beach line is the center of a circle between two sites, and that circle is also tangent to the sweepline. The composition of the beachline is changed by two types of events, Site Events and Circle Events. 

A **Site Event** happens when the sweep line crosses one of the input sites. This splits apart the arc currently under the site, and wedges a new parabola into that section of the beach line, using the current site as its focus. 

A **Circle Event** occurs when there is potential for a Voronoi vertex to be formed. _This algorithm generates a large number of false circle events, but they are removed from the queue before they can be processed as a part of handling of other events._ This happens when the middle arc of a triple of adjacent arcs on the beach line is getting squeezed out by its neighbors, which means that the edges being traced by those arcs are going to converge. The arc will disappear when its neighbors meet, which means that point is equidistance from 3 of the sites, and is thus a Voronoi vertex. Circle Events are organized by their top-most y coordinate (not by the center of the circle). The edges used to find the center of the circle are then added to the cells of the adjacent Voronoi cells.


The underlying structure of the beach line is a balanced binary tree. Any arc currently in the tree is represented as a leaf, containing a reference to the site that generates that arc. Note that multiple leaves can be tied to a single site. This indicates the arc has been split at least once. The internal nodes of the tree contain references to a pair of sites, and represents the Voronoi edge between those sites. The ordering in which the sites appear in the pair matters, as it is used to infer what the left and right breakpoints of a specific arc are. 

When a new point queries the tree to find the which are in the beachline it lines up with, it performs a binary search where the breakpoints between the neighboring arcs it encounters are computed on the fly (since only references to sites are stored in the nodes, not the actual equation of the parabola). 

Whenever an arc is added or removed from the beach line, we add or remove pairs of nodes from our tree, one leaf (our arc) and one internal node (the leaf’s parent). In addition, we must also update any nodes that are impacted by this action and potentially rebalance the tree. 

---

\*_Note that for the implementation with the video/code, the sweep is actually moving horizontally, this was purely a matter of personal preference._

\*\*_There are some edge-cases where this isn’t exactly true, but most of those would require very specific configurations that would violate the assumption of general position. They are also fairly computationally trivial to deal with and do not significantly impact performance_

## Pseudo Code (simplified)
**Input** - S, a set of points _we'll refer to these points as sites to avoid confusion_ 

**Output** - the Voronoi Diagram of that point set

```
intialize empty eventQueue
initialize empty beachLine

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
  currentArc <- find arc underneath e.site
  if(arc has generated a circle event){
    remove that circle event from the eventQueue
  }
  split apart currentArc into arcLeft and arcRight
  insert new arc into wedge
  checkForCircleEvent(arcLeft)
  checkForCircleEvent(arcRight)
}
```
```
processCircleEvent(CircleEvent e){
  Arc arcToBeRemoved <- the arc that is going to get closed out (in this case, the middle arc that generated this circle event)
  remove arcToBeRemoved from the beachLine
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

## Analysis
This algorithm is considered efficient as it is O(n log n) for time and O(n) for space.\* O(n log n ) is an accepted lower bound for this problem, because this problem reduces to other problems that share this same limit. For example, this is also the lower bound for finding a convex hull; finding a Voronoi diagram of a point set would enable you to also  determine the convex hull points, since points on the convex hull would have unbounded cells, and could be found by traversing the edges of the Voronoi diagram. 

The first reason it is able to achieve that level of efficiency is due to the structure of the beach line. Since the beach line is stored as a balanced binary search tree, we are able to both update and query in O(log b) time (where b is the number of nodes in the tree). If we consider when the beach line is updated, it only increases in size when we encounter a new Site Event, which splits the current arc in two and inserts a new arc, leaving a net gain of 2 arcs. The only time this isn't true is at the beginning, when there are no arcs to split, or when we encounter several horizontally collinear points in succession. This means that at most we have 2n-1 arcs present in the beach line at any given time. This allows us to claim that operations like searching and updating the beach line takes only O(log n) instead of O(n).

This leaves our queue as the other place to potentially drive up run time. If we consider the number of events that will be in our queue, we'll find that it is O(n). There will only be n Site Events, and the number of Circle Events that will be processed will be the number of Voronoi vertices. Since the Voronoi diagram is planar, it contains a linear number of vertices, so the number of Circle Events will also be linear. So if we're able to select a structure that can be modified and queried in O(log n) time, then our interactions with the queue will not exceed O(n log n).  

Other operations, like checking for circle events, or updating pointers can be done in constant time. Overall, this leaves us with an O(n long n) algorithm for finding the Voronoi Diagram of a set of points. 
 
---

\*_This current implementation is neither._:broken_heart:
## TODOs:

#### Explanations
+ provide images for examples
+ elaborate on event processing in demo

#### Functionality
+ see if there's a fix for the density issue
+ finish bounding cells
+ add tree implementation
+ get port to JS working (requires removal of the Java libraries)
+ stack implementation for state(allowing moving forwards and backwards)
+ optimize parabola drawing (use Bezier curves)

## Helpful Links
+ http://www.raymondhill.net/voronoi/rhill-voronoi.html - full implementation in Javascript by Raymond Hill
+ http://www.ams.org/samplings/feature-column/fcarc-voronoi - article with a good general overview for how this algorithm works
+ http://www.cescg.org/CESCG99/RCuk/ - set of pages that delves into the data structures necessary for implementing this algorithm
+ http://ect.bell-labs.com/who/sjf/ - Steven Fortune
