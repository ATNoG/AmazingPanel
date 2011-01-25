function createDialog(title, options){
  var modal = $(".modal");
  var title = $(".title-box", modal).html(title);
  modal.addClass("dialog-active");
  return modal;
}

function EdEditor() {
  var canvas = $(".canvas")
  this.engine = new Engine();
  /*this.graph = new Graph(".canvas")*/
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

EdEditor.prototype.addNode = function(x,y) {
  var id = this.engine.groups.default.getId();
  var resource = new Resource(id);
  this.engine.addResource('default', resource);
  /*
  var node = this.graph.node(id);  
  */

  node.bindings.application = this.selectApplication.bind({id:node.id});
  node.bindings.group = this.selectGroup.bind({id:node.id, groups : this.engine.group_keys});
  node.bindings.properties = this.selectProperties.bind({id:node.id});
}

EdEditor.prototype.addGroup = function(name) {  
  this.engine.addGroup(name);
}

EdEditor.prototype.selectApplication = function(t) {
  var modal = createDialog("Select an application for Node");
  var container = $(".modal-container", dialog).html("<form id=\"application\"></form>");  
  $("#application").buildForm(
  {
    "elements" : 
      [{
        "type" : "select",
        "name" : "resource[application]",
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
  var modal = createDialog("Select a Group for the node");
  var groups = ""
  var i = 0;
  var total = this.groups.length;
  for (i=this.groups.length;i>0;--i){
    groups = groups + "<li class=\"group\"><div class=\"group-color\" style=\"background-color: "+rgb_color(i/total)+"\"></div>  "+this.groups[i-1]+"</li>";
  }
  var container = $(".modal-container", modal).html("<form id=\"add-group\"></form><div class=\"clear\"></div><ul id=\"groups\">"+groups+"</ul>");
  $("#add-group").buildForm(
  { "elements" : [{
        "name" : "group[name]",
        "caption" : "Group",
        "type" : "text"
      }, {
        "type" : "div",
        "class" : "clear",
      }, {
        "type" : "div",
        "class" : "group-add-action button",
        "html" : "Add"
      }]
  });  
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
  var params = $("#add-group").formParams();
  evt.data.editor.addGroup(params.group.name);
  var modal = $(".modal");
  modal.removeClass("dialog-active");
  modal.hide();  
}

EdEditor.prototype.onGroupSelection = function(evt) {
  
}

EdEditor.prototype.onPreferencesOpen = function(evt) {  
  evt.data.editor.loadPreferences();
}

EdEditor.prototype.bindings = {
  application : this.selectApplication.bind(this), 
  group : this.selectGroup.bind(this), 
  properties : this.selectProperties.bind(this)
}

EdEditor.prototype.bindEvents = function() {
  $(".node").contextMenu('nodeCtxMenu', this.bindings);
  $(".node-add-action").live("click", {editor : this}, this.onNodeAdd)
  $(".group-add-action").live("click", {editor : this}, this.onGroupAdd)
  $("li.group").live("click", {editor : this}, this.onGroupSelection)
  $(".preferences-view-action").live("click", {editor : this}, this.onPreferencesOpen)
  
}

