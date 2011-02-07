function createDialog(title, options){
  var modal = $(".modal");
  var title = $(".title-box", modal).html(title);
  modal.addClass("dialog-active");
  return modal;
}

function hideDialog(){
  var modal = $(".modal");
  modal.removeClass("dialog-active");
  modal.hide();  
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

EdEditor.prototype.forms = {
  select_application: {
    "elements" : [{
        "id" : "app-name",
        "type" : "select",
        "name" : "resource[application]",
        "caption" : "Application",
        "options" : {}
      }, {
        "id" : "app-container",
        "type" : "div"
      }, {
        "id" : "app-prop-container",
        "type" : "div"
      }]
  },
  select_group: { 
    "elements" : [{
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
  },
  select_properties: {}
}

EdEditor.prototype.addNode = function(x,y) {
  var id = this.engine.groups.default.getId();
  var resource = new Resource(id);
  this.engine.addResource('default', resource);
  /*
  var node = this.graph.node(id);  
  node.bindings.application = this.selectApplication.bind({id:node.id});
  node.bindings.group = this.selectGroup.bind({id:node.id, groups : this.engine.group_keys});
  node.bindings.properties = this.selectProperties.bind({id:node.id});
  */

}

EdEditor.prototype.addGroup = function(name) {  
  this.engine.addGroup(name);
}

EdEditor.prototype.addNodesToGroup = function(group, nodes) {  
  this.engine.addResources(group, nodes);
}

EdEditor.prototype.selectApplication = function(t) {
  var app_selections = {}, keys = this.engine.reference.keys;
  for (i=0;i<keys.length; ++i){
     var uri = keys[i];
     var name = this.engine.reference.defs[uri].name;
     app_selections[uri] = name;
  }
  this.forms.select_application.elements[0].options = app_selections;
  var modal = createDialog("Select an application for Node");
  modal.css("height", "500px");
  modal.css("width", "500px");
  modal.css("left", "30%"); 
  modal.css("top", "20%");
  $(".modal-container").css("height", "463px");
  var container = $(".modal-container", modal).html("<form id=\"select-application\"></form>");  
  $("#select-application").buildForm(this.forms.select_application);
  $("select#app-name").change(function(evt){
    var v = evt.currentTarget.value,
        defs = this.engine.reference.defs[v],
        pp = this.engine.reference.properties[v],
        ms = this.engine.reference.measures[v],
        container = $("#app-container");
    container.html("");
    for(d in defs){
      container.append("<p><b>"+d+":</b>"+defs[d]+"</p>");
    }
  }.bind(this));
  modal.addClass("dialog-active");
  modal.show();
}

EdEditor.prototype.selectGroup = function(t) {
  var engine = this.engine,
    modal = createDialog("Select a Group for the node"), 
    i = 0, total = engine.group_keys.length, groups = [],
    groups_tmpl = $.template("tmpl_groups", "<li class=\"group\">"+
      "<div class=\"group-color\" style=\"background-color: ${color}\"></div>"+
      " ${name}</li>");
  for (i=engine.group_keys.length;i>0;--i){
    groups.push( {"color" : rgb_color(i/total), "name" : engine.group_keys[i-1]} );
  }
  var container = $(".modal-container", modal).html("<form id=\"add-group\"></form>"+
                                "<div class=\"clear\"></div>"+
                                "<ul id=\"groups\"></ul>");
  $.tmpl("tmpl_groups", groups).appendTo("#groups");
  $("#add-group").buildForm(this.engine.forms.select_group);
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

EdEditor.prototype.showNotification = function(text) {
  var notification = "<p class=\"info\">"+text+"</p>";
  $("#design").prepend(notification).slideDown().delay(5000).slideUp();
}

EdEditor.prototype.onNodeAdd = function(evt) {  
  evt.data.editor.addNode();
}

EdEditor.prototype.onGroupAdd = function(evt) {  
  var params = $("#add-group").formParams();
  evt.data.editor.addGroup(params.group.name);
  hideDialog();
}

EdEditor.prototype.onGroupSelection = function(evt) {
  var text = $(evt.target).text().trim(), 
      color = $(".group-color", evt.target).css("background-color"), 
      nodes = $(".node-selected");
  evt.data.editor.addNodesToGroup(text, nodes);
  nodes.css("background-color", color);
  nodes.toggleClass("node-selected");
  hideDialog();
}

EdEditor.prototype.onPreferencesOpen = function(evt) {  
  evt.data.editor.loadPreferences();
}

EdEditor.prototype.bindings =
EdEditor.prototype.bindEvents = function() {
  var editor = this;
  $(".node").live("click", function(e){
      $(e.target).toggleClass("node-selected");
  });
  $(".node").contextMenu('nodeCtxMenu', { 
    onContextMenu : function(e) {
      $(e.target).addClass("node-selected");
      return true;
    }, bindings : {
      'application' : editor.selectApplication.bind(editor),
      'group' : editor.selectGroup.bind(editor),
      'properties' : editor.selectProperties.bind(editor)
    }
  });
  /*
  $(".node-add-action").live("click", {editor : this}, this.onNodeAdd)
  */
  $(".group-add-action").live("click", {editor : this}, this.onGroupAdd)
  $("#groups > li.group").live("click", {editor : this}, this.onGroupSelection)
  $(".preferences-view-action").live("click", {editor : this}, this.onPreferencesOpen)
  $("#source").focus({editor:this}, function(evt){
    evt.data.editor.engine.getGeneratedCode();
  });
}

