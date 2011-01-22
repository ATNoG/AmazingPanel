(function(){

Raphael.fn.arrow = function (cx, cy, r) {
  return this.path("M".concat(cx - r * .7, ",", cy - r * .4, "l", [r * .6, 0, 0, -r * .4, r, r * .8, -r, r * .8, 0, -r * .4, -r * .6, 0], "z"));
};

Raphael.fn.square = function (cx, cy, r) {
  r = r * .7;
  return this.rect(cx - r, cy - r, 2 * r, 2 * r);
};

Raphael.fn.connection = function (obj1, obj2, line, bg) {
    if (obj1.line && obj1.from && obj1.to) {
        line = obj1;
        obj1 = line.from;
        obj2 = line.to;
    }
    var bb1 = obj1.getBBox(),
        bb2 = obj2.getBBox(),
        p = [{x: bb1.x + bb1.width / 2, y: bb1.y - 1},
        {x: bb1.x + bb1.width / 2, y: bb1.y + bb1.height + 1},
        {x: bb1.x - 1, y: bb1.y + bb1.height / 2},
        {x: bb1.x + bb1.width + 1, y: bb1.y + bb1.height / 2},
        {x: bb2.x + bb2.width / 2, y: bb2.y - 1},
        {x: bb2.x + bb2.width / 2, y: bb2.y + bb2.height + 1},
        {x: bb2.x - 1, y: bb2.y + bb2.height / 2},
        {x: bb2.x + bb2.width + 1, y: bb2.y + bb2.height / 2}],
        d = {}, dis = [];
    for (var i = 0; i < 4; i++) {
        for (var j = 4; j < 8; j++) {
            var dx = Math.abs(p[i].x - p[j].x),
                dy = Math.abs(p[i].y - p[j].y);
            if ((i == j - 4) || (((i != 3 && j != 6) || p[i].x < p[j].x) && ((i != 2 && j != 7) || p[i].x > p[j].x) && ((i != 0 && j != 5) || p[i].y > p[j].y) && ((i != 1 && j != 4) || p[i].y < p[j].y))) {
                dis.push(dx + dy);
                d[dis[dis.length - 1]] = [i, j];
            }
        }
    }
    if (dis.length == 0) {
        var res = [0, 4];
    } else {
        res = d[Math.min.apply(Math, dis)];
    }
    var x1 = p[res[0]].x,
        y1 = p[res[0]].y,
        x4 = p[res[1]].x,
        y4 = p[res[1]].y;
    dx = Math.max(Math.abs(x1 - x4) / 2, 10);
    dy = Math.max(Math.abs(y1 - y4) / 2, 10);
    var x2 = [x1, x1, x1 - dx, x1 + dx][res[0]].toFixed(3),
        y2 = [y1 - dy, y1 + dy, y1, y1][res[0]].toFixed(3),
        x3 = [0, 0, 0, 0, x4, x4, x4 - dx, x4 + dx][res[1]].toFixed(3),
        y3 = [0, 0, 0, 0, y1 + dy, y1 - dy, y4, y4][res[1]].toFixed(3);
    var path = ["M", x1.toFixed(3), y1.toFixed(3), "C", x2, y2, x3, y3, x4.toFixed(3), y4.toFixed(3)].join(",");
    if (line && line.line) {
        line.bg && line.bg.attr({path: path});
        line.line.attr({path: path});
    } else {
        var color = typeof line == "string" ? line : "#000";
        return {
            bg: bg && bg.split && this.path(path).attr({stroke: bg.split("|")[0], fill: "none", "stroke-width": bg.split("|")[1] || 3}),
            line: this.path(path).attr({stroke: color, fill: "none"}),
            from: obj1,
            to: obj2
        };
    }
};

Raphael.fn.graph = {
  nid : 0
}

Raphael.fn.graph._createNode = function(x, y, id){
  var g = this.graph;
  var sq = this.square(x,y,80);
  var cl = this.circle(x,y,40);
  var txt = this.text(x,y,id);
  sq.node.setAttribute("class", "node-box");
  cl.node.setAttribute("class", "node");
  cl.mouseout(function(evt){ 
    sq.show(); 
    sq.toFront();
  });
  sq.hover(function(evt){ 
    sq.show();
    sq.toFront();
  }, function(evt){
    sq.toBack();
    sq.hide();
  });
  sq.hide();
  txt.node.setAttribute("class", "node-label");
  return this.set().push(sq,cl,txt);
}

Raphael.fn.graph.node = function(render){
  var graph = this.graph;
  var id = graph.nid
  var node = (render == undefined) ? graph._createNode(100,100,id) : render(100,100,id);
  
 var  start = function(){
    this.ox = this.attr("cx");
    this.oy = this.attr("cy");
    this.attr({opacity: 0.1});  
  }, move = function (dx, dy) {
      this.attr({cx: this.ox + dx, cy: this.oy + dy});
  }, up = function(){
    this.attr({opacity: 1});
  };  
  node.id = id;
  nid = id + 1;
  if (graph.nodes == undefined){
    graph.nodes = []
  }  
  node.drag(move,start,up);
  graph.nodes.push(node);
}

Raphael.fn.graph.node.drag = {
}

Raphael.fn.graph.edge = function(src, dest, label, render){
  var graph = this.graph;
  var label = label
  var node = (render == undefined) ? graph._createNode(0,0,id) : render(0,0,id);
  node.id = id;
  nid = id + 1;
  if (graph.nodes == undefined){
    graph.nodes = []
  }
  graph.nodes.push(node);
}

})();
