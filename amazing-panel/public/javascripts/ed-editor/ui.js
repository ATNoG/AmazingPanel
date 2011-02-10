function createDialog(title, options){
  var modal = $(".modal");
  var title = $(".title-box", modal).html(title);
  modal.addClass("dialog-active");
  return modal;
}

function confirmDialog(id){
  
}

function hideDialog(){
  var modal = $(".modal");
  $(".modal-container").empty();
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

EdEditor.prototype.html = {
  tabs : {
    application : 
      "<ul id=\"modal-tabs\" class=\"tabs\">"+
       "<li class=\"tab-active\"><a href=\"#content-application\">Information</a></li>"+
        "<li><a href=\"#content-properties\">Properties</a></li>"+
        "<li><a href=\"#content-measures\">Measures</a></li>"+
      "</ul>"+
      "<div id=\"content-application\" class=\"modal-tab tab\">"+
      "</div>"+
      "<div id=\"content-properties\" class=\"modal-tab tab\">"+
        "<form id=\"select-properties\" name=\"properties\"></form>"+
      "</div>"+
      "<div id=\"content-measures\" class=\"modal-tab tab\">"+
        "<form id=\"select-measures\" name=\"measures\"></form>"+
      "</div>"
  }
}

EdEditor.prototype.nodes_selected = {
  single:
    "<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>"+
    "<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>"+
    "<div id=\"btn_group\" class=\"oedl-action-button button\">Group</div>",
  multiple:
    "<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>"+
    "<div id=\"btn_group\" class=\"oedl-action-button button\">Group</div>"
}

EdEditor.prototype.forms = {
  select_exp_properties : {
    "elements" : [{
        "name" : "exp[duration]",
        "caption" : "Duration (s)",
        "type" : "text",
      }]
  },
  select_application: {
    "elements" : 
      [{ "type" : "p",
         "elements" : [{
           "id" : "app-name",
           "type" : "select",
           "name" : "resource[application]",
           "caption" : "Application:",
           "options" : {}
        }]
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
}

EdEditor.prototype.addGroup = function(name) {  
  this.engine.addGroup(name);
}

EdEditor.prototype.addNodesToGroup = function(group, nodes) {  
  this.engine.addResources(group, nodes);
}

EdEditor.prototype.selectApplication = function(t) {
  var app_selections = {}, prop_selections= {}, keys = this.engine.reference.keys;
  for (i=0;i<keys.length; ++i){
    var uri = keys[i];
    var name = this.engine.reference.defs[uri].name;
    app_selections[uri] = name;
  }  
  this.forms.select_application.elements[0].elements[0].options = app_selections;
  var modal = createDialog("Select an application for Node").css("height", "500px").css("width", "600px").css("left", "30%").css("top", "20%");
  $(".modal-container", modal).prepend("<form id=\"select-application\"></form>");  

  $(".modal-container", modal).css("height", "463px").append(this.html.tabs.application);
  $("#select-application").buildForm(this.forms.select_application);
  $("select#app-name").change(function(evt){
    var v = evt.currentTarget.value,
        defs = this.engine.reference.defs[v],
        pp = this.engine.reference.properties[v],
        ms = this.engine.reference.measures[v],
        defs_ct = $("#content-application").empty(), 
        pp_ct = $("#select-properties").empty(),
        ms_ct = $("#select-measures").empty();
    
    var tables = "<div class=\"grid-view-row grid-view-header\">"+
          "<div>Name</div>"+
          "<div>Description</div>"+
          "<div>Value</div>"+
        "</div>";
    pp_ct.append(tables);
    for(d in defs){
      defs_ct.append("<div class=\"grid-view-row\"><div><b>"+d.underscore().humanize()+" </b></div><div>"+defs[d]+"</div></div>");
    }
    for(d in pp){
      html_safe_d = d.replace(':', '__');
      pp_ct.append("<div class=\"grid-view-row\"><div><b>"+d+"</b></div><div>"+pp[d].description+"</div><div>"+
        "<input class=\"hidden\" name=\"properties["+d+"]\" type=\"text\"/>"+
        "<input name=\"selected \"class=\"prop-check\" type=\"checkbox\" value=\""+d+"\"/></div></div>");
    }
    var html = pp_ct.html()    
    pp_ct.html("<div class=\"grid-view\">"+html+"</div>");
    $(".prop-check").change(function(evt){
      var p = $(evt.target).parent();
      $(p).children("input[type='text']").toggleClass("hidden");
    });
    for(d in ms){
      var metrics = "", measurement = ms[d];
      for(m in measurement){ metrics += "<li>"+m+" : "+measurement[m]["type"]+"</li>"; }
      ms_ct.append("<p><b>"+d+"<input name=\"selected\" type=\"checkbox\" value=\""+d+"\"/></b><ul class=\"list\">"+metrics+"</ul></p>");
    }
  }.bind(this));
  modal.addClass("dialog-active");
  $("#modal-tabs > li:eq(0)").click();  
  $(".modal > .check-button").unbind('click').click(function(evt){
    var application = $("#select-application").formParams();
    var properties = $("#select-properties").formParams();
    var measures = $("#select-measures").formParams();
    var nodes = $(".node-selected");
    this.engine.addApplication({ "uri" : application.resource.application, "options" : properties, "measures" : measures }, nodes);
    closeDialog("#modal-dialog");
  }.bind(this));
  
  modal.show();
}

EdEditor.prototype.selectGroup = function(t) {
  var engine = this.engine,
    modal = createDialog("Select a Group for the node"), 
    i = 0, total = engine.group_keys.length, groups = [],
    groups_tmpl = $.template("tmpl_groups", "<li class=\"group\"><div class=\"group-color\" style=\"background-color: ${color}\"></div> ${name}</li>");
  for (i=engine.group_keys.length;i>0;--i){
    groups.push( {"color" : rgb_color(i/total), "name" : engine.group_keys[i-1]} );
  }
  var container = $(".modal-container", modal).html("<form id=\"add-group\"></form>"+
                                "<div class=\"clear\"></div>"+
                                "<ul id=\"groups\"></ul>");
  $.tmpl("tmpl_groups", groups).appendTo("#groups");
  $("#add-group").buildForm(this.forms.select_group);
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
  var container = $(".modal-container", modal).html("<form id=\"exp-properties\" class=\"attr-choose\"></form>");
  $("#exp-properties").buildForm(this.forms.select_exp_properties);
  modal.addClass("dialog-active");
  $(".modal > .check-button").unbind('click').click(function(evt){
    var params = $("#exp-properties").formParams();
    var t_id = $("#testbed_id").attr("value");
    var t_name = $("#testbed_name").attr("value");
    params.exp["testbed"] = { id: t_id, name: t_name }
    this.engine.setExperimentProperties(params.exp);
    closeDialog("#modal-dialog");
  }.bind(this));
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

EdEditor.prototype.onNodeClick = function(e) {
    $(e.target).toggleClass("node-selected");
    var n_nodes = $(".node-selected").length;
    $(".oedl-action-button").remove();
    if (n_nodes == 1){
      $(".oedl-actions").prepend(this.nodes_selected.single)
    } else if (n_nodes > 1) {
      $(".oedl-actions").prepend(this.nodes_selected.multiple)
    }
}

EdEditor.prototype.bindEvents = function() {
  var editor = this;
  $(".node").live("click",this.onNodeClick.bind(editor));
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
  $("#btn_properties").live('click', this.selectProperties.bind(editor));
  $("#btn_group").live('click',this.selectGroup.bind(editor));
  $("#btn_application").live('click', this.selectApplication.bind(editor));
  $("#groups > li.group").live("click", {editor : this}, this.onGroupSelection)
  $(".preferences-view-action").live("click", {editor : this}, this.onPreferencesOpen)
  $("#source").focus({editor:this}, function(evt){
    evt.data.editor.engine.getGeneratedCode();
  });
  // Configure tabbed env
  $("#modal-tabs > li").live('click', function(evt){
    var active_tab = $($(this).find("a").attr("href"));
    $(".modal-tab").hide();
    $("#modal-tabs > li").removeClass("tab-active");
    $(this).addClass("tab-active");
    active_tab.fadeIn();
    active_tab.focus();
    return false;
  });
}

