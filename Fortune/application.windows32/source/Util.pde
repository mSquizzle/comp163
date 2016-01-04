void drawArcPoints(){ 
 int x = 0;
  
 ArcNode node = rootNode;
 int b = 0;
 if(debug){
   b = 255;   
   strokeWeight(3);
 }
 
 while(node!=null){
   stroke(x, b, 0);
   float y = node.startY;
   if(node.startY < 0){
     y = 0;
   }
   float limit = node.endY;
   if(node.endY > height){
     limit = height;  
   }
   while(y < limit){
     PVector point = getPoint(node, y);
     if(point!=null){
        point(point.x, point.y);  
     }
     y+=.2;
   }
   node = node.next;
  if(debug){ 
     x+=50;  
  } 
 } 
 strokeWeight(1);
}
