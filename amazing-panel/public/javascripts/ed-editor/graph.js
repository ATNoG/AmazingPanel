Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

function Node(g, id){
  this.id = id;
  this.graph = g;
}

Node.prototype.render = function(x,y){
  var id = this.id;
  var svg = this.graph.paper;
  var g = svg.group({id : id+"", transform: 'translate(0, 0)'});
  g.id = id;
  var gbbox = svg.group(g);
  $(gbbox).addClass("node-box");
  var close_cross_path = svg.createPath().move(x+40, y/2).line(x+50, y/2 + 10).move(x+40, y/2 + 10).line(x+50, y/2);
  var node = {
    bbox : $(svg.rect(gbbox,x-55,y-55,110,110)).attr("rx",10),
    close_cross : $(svg.path(gbbox, close_cross_path)).addClass("node-box-close-button"),
    circle : $(svg.circle(g,x,y,40)).addClass("node"),
    label : $(svg.text(g,x,y+5,svg.createText().span(id+""))).addClass("node-label"),
    cb : {
      del_node: function(evt){
        var svg = $(evt.target).parents('svg');
        var el = $("#"+evt.data.id, svg)
        el.remove();
        this.graph.nodes.remove(id);
      }, 
      show_bbox: function(evt){    
        var svg = $(evt.target).parents('svg');
        var el = $("#"+evt.data.id+" > .node-box", svg)
        el.show();
      }, 
      hide_bbox: function(evt){    
        var svg = $(evt.target).parents('svg');
        var el = $("#"+evt.data.id+" > .node-box", svg)
        el.hide();
      },
    }
  }

  node.close_cross.click({id:id},node.cb.del_node.bind(this));
  node.circle.mouseout({id:id},node.cb.show_bbox.bind(this));
  node.close_cross.mouseenter({id:id},node.cb.show_bbox.bind(this));
  $(gbbox).mouseout({id:id},node.cb.hide_bbox);
  $(gbbox).bind('drag',function(evt,o){
    var p_move = g.getAttribute('transform').replace(/\(|\)|[a-z ]/g,"");        
    var coords = p_move=="0"? ["0","0"] : p_move.split(","), 
      x = parseInt(coords[0]), y = parseInt(coords[1]), 
      ox = g.getAttribute('cx'), oy = g.getAttribute('cy');
    if ((x==0) && (y==0)) {
      g.setAttribute('cx', o.originalX);       
      g.setAttribute('cy', o.originalY);
      ox = o.originalX;
      oy = o.originalY;
    }
    g.setAttribute('transform','translate('+Math.round(o.offsetX - ox)+','+Math.round(o.offsetY - oy)+')');       
  }, { which: 1, distance: 5 }).hide();
  node.gbbox = gbbox;
  this.g = node; 
}

Node.prototype.bindings = {
  application : {}, 
  group : {}, 
  properties : {}
}

function Graph(selector){
  this.nid = 0;
  this.nodes = [];
  this.edges = [];
  $(selector).svg();
  this.paper = $(selector).svg('get');
}

Graph.prototype = {
  nid : 0
}

Graph.prototype._createNode = function(x, y, id){
  var node = new Node(this, id)
  node.render(x,y);
  return node;
}

Graph.prototype.node = function(id, render){
  var graph = this;
  graph.nid = id;
  var node = (render == undefined) ? graph._createNode(100,100,id) : render(100,100,id);  
  nid = id + 1;
  if (graph.nodes == undefined){
    graph.nodes = {}
  }  
  graph.nodes[node.id] = node;
  graph.nid = id + 1;
  return node;
}
