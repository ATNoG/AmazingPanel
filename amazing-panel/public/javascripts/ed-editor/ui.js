function EdEditor() {
  var canvas = $(".canvas")
  this.engine = EdEditorEngine();
  /*this.paper = new Raphael(canvas[0], canvas.css("width"), canvas.css("height"))
  this.graph = this.paper.graph;*/
  this.graph = new Graph(".canvas") 
  this.last_id = -1;
}

EdEditor.NODE_COORD = 10;
EdEditor.NODE_INTERVAL_X = 75;
EdEditor.NODE_INTERVAL_Y = 75;
EdEditor.NODE_SIZE = 30;
EdEditor.prototype.node_actions = [
  {name:"Choose Application", cb: "selectApplication"}, 
  {name:"Select Group", cb: "selectGroup"}, 
  {name:"Properties", cb: "selectProperties"}
];

EdEditor.prototype.ctxRender = function(evt) {
  $(".node-context-menu, .node-link").show();
}

EdEditor.prototype.ctxClose = function(evt) { 
  $(".node-context-menu, .node-link").hide();
}
/*
EdEditor.prototype.renderNode = function(r, n) {
  text.addClass("node-label");
  circle.addClass("node");
  ctx_menu.addClass("node-context-menu");
  return set;
}
*/

EdEditor.prototype.addNode = function(x,y) {
  var node = this.graph.node();  
  node.g.circle.contextMenu('nodeCtxMenu', node);
  node.bindings.application = this.selectApplication.bind({id:node.id});
  node.bindings.group = this.selectGroup.bind({id:node.id});
  node.bindings.properties = this.selectProperties.bind({id:node.id});
}

EdEditor.prototype.selectApplication = function(t) {
  var modal = $(".modal");
  var title = $(".title-box", modal).html("Select an application for Node");
  var container = $(".modal-container", modal).html("<form id=\"add-application\"></form>");
  $("#add-application").buildForm(
  {
    "elements" : 
      [{
        "type" : "select",
        "name" : "application",
        "caption" : "Application",
        "options" : {
          "otr2" : "OMF Traffic Receiver",
          "otg2" : "OMF Traffic Generator",
          "iperf" : "IPerf",
          "trace_oml2" : "Trace",
          "wlan_oml2" : "WLAN Config"
        }
      }]
  });
  modal.addClass("dialog-active");
  modal.show();
}

EdEditor.prototype.selectGroup = function(t) {
  var modal = $(".modal");
  var title = $(".title-box", modal).html("Select a Group for the node");
  modal.addClass("dialog-active");
  modal.show();
}

EdEditor.prototype.selectProperties = function(t) {
  var modal = $(".modal");
  var title = $(".title-box", modal).html("Properties");
  modal.addClass("dialog-active");
  modal.show();
}

EdEditor.prototype.loadPreferences = function(t) {
  var modal = $(".modal");
  var title = $(".title-box", modal).html("Experiment Definition Properties");
  modal.addClass("dialog-active");
  modal.show();
}

EdEditor.prototype.onNodeAdd = function(evt) {  
  evt.data.editor.addNode();
}

EdEditor.prototype.onGroupAdd = function(evt) {
  evt.data.editor.addGroup();
}

EdEditor.prototype.onPreferencesOpen = function(evt) {  
  evt.data.editor.loadPreferences();
}

EdEditor.prototype.bindEvents = function(editor) {
  $(".node-add-action").live("click", {editor : this}, this.onNodeAdd)
  $(".group-add-action").live("click", {editor : this}, this.onGroupAdd)
  $(".preferences-view-action").live("click", {editor : this}, this.onPreferencesOpen)
}

