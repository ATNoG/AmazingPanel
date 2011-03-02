/**
  * Helper method for creating and showing a dialog
  */
function createDialog(title, options){
  var modal = $(".modal");
  var title = $(".title-box", modal).html(title);
  modal.addClass("dialog-active");  
  return modal;
}

/**
  * Helper method to hide a dialog
  */
function hideDialog(){
  var modal = $(".modal");
  $(".modal-container").empty();
  modal.removeClass("dialog-active");
  modal.hide();  
}

/**
  * IDE Constructor
  */
function EdEditor() {
  var canvas = $(".canvas")
  this.engine = new Engine();
  /*this.graph = new Graph(".canvas")*/
  this.last_id = -1;  
}

/**
  * Context Menu for nodes
  * 'XXX' NOT RECENT
  */
EdEditor.prototype.node_actions = [
  {name:"Choose Application", cb: "selectApplication"}, 
  {name:"Select Group", cb: "selectGroup"}, 
  {name:"Properties", cb: "selectProperties"}
];

/**
  * Tabs for Application Dialog
  */
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

/**
  * Options to show, in according to the various Node click conditions. 
   -> When nodes selected are a group, when multiple nodes without group,
   -> When one node selected are only one,
   -> When multiple nodes are selected
  */
EdEditor.prototype.nodes_selected = {
  single:
    "<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>"+
    "<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>",
  multiple:
    "<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>"+
    "<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>",
//    "",
  group:
    "<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>"+
    "<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>",
}

/**
  * Displayable Resource Properties fields
  */
EdEditor.prototype.resource_fields = [
  "ip", 
  "netmask", 
  "mtu",
  "mode", 
  "type", 
  "essid",
  "channel"
]

/**
  * Templates
  */
EdEditor.prototype.templates = {
  display_info: $.template("display_info","<div class=\"grid-view-row\"><div><b>${key} </b></div><div>${value}</div></div>"),
  display_property: $.template("display_property","<div class=\"grid-view-row\"><div><b>${key}</b></div><div>${value}</div><div><input class=\"{{if v}}{{else}}hidden{{/if}}\" name=\"properties[${key}]\" type=\"text\" value=\"{{if v}}${v}{{/if}}\" /><input name=\"selected\" class=\"prop-check\" type=\"checkbox\" {{if v}}checked=\"true\"{{/if}} value=\"${key}\"/></div></div>"),
  display_measure : $.template("display_measures", "<p><b>${key}<input name=\"selected\" type=\"checkbox\" value=\"${key}\"/></b><ul class=\"list\">{{each(i,m) metrics}} <li>${m.name} : ${m.type}</li>{{/each}} </ul></p>"),
  insert_info: $.template("insert_info","<div class=\"grid-view-row\"><div><b>${key} </b></div><div><input name=\"info[${key}]\" type=\"text\"/>${value}</div></div>"),
  insert_property: $.template("insert_property","<div class=\"grid-view-row\"><div><b> <input name=\"property_name\" type=\"text\"/> </b></div><div> <input name=\"property_description\" type=\"text\"/>  </div><div style=\"width:250px\"><input name=\"property_value\" type=\"text\"/><input name=\"has_value\" type=\"checkbox\"/> <div id=\"add-application-property-button\"class=\"button inline right\">Add</div></div></div>"),
  inserted_info : $.template("inserted_info", "<input name=\"${key}\" type=\"hidden\" value=\"${value}\" />"),
  inserted_property: $.template("inserted_property","<div class=\"grid-view-row\"><div><b>${key}</b><input name=\"properties[${key}][name]\" type=\"hidden\" value=\"${key}\" /></div><div><span>${value}</span><input name=\"properties[${key}][description]\" type=\"hidden\" value=\"${value}\" /></div><div><input class=\"{{if v}}{{else}}hidden{{/if}}\" name=\"properties[${key}][value]\" type=\"text\" value=\"{{if v}}${v}{{/if}}\" /><input name=\"selected\" class=\"prop-check\" type=\"checkbox\" {{if v}}checked=\"true\"{{/if}} value=\"${key}\"/></div></div>")
}

/**
  * JSON Forms for dialogs
  */
EdEditor.prototype.forms = {
  select_exp_properties : {
    "elements" : [{
        "type" : "p",
        "elements" : [{
          "name" : "exp[duration]",
          "caption" : "Duration (s)",
          "type" : "text"
        }]
      }, {
        "type" : "p",
        "elements" : [{
          "name" : "exp[network]",
          "caption" : "Automatically configure all Wireless Interfaces?",
          "type" : "checkbox"
        }]
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
        },{
          "id" : "create_flag",
          "type" : "hidden",
          "name" : "resource[create]",
          "value" : "0"
        }, {
          "id" : "add-application-button",
          "type": "div",
          "class" : "no-float inline pad round button",
          "html" :  "New Application" 
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
  select_inet : {  
    "elements" : 
      [{ "type" : "p",
         "elements" : [{
           "id" : "inet-choose",
           "type" : "select",
           "name" : "inet",
           "caption" : "Network Interface:",
           "options" : {
            "w0" : "Wireless Interface 0",
            "w1" : "Wireless Interface 1",
            "e0" : "Ethernet Interface 0",
            "e1" : "Ethernet Interface 1"
           }
        }]
      }]
  }, 
  _event : {
    "elements" : [{
        "type" : "p",
        "elements" : [{
          "name" : "event[start]",
          "caption" : "Start (Timestamp)",
          "type" : "text"
        }]
      }, {
        "type" : "p",
        "elements" : [{
          "name" : "event[duration]",
          "caption" : "Duration (seconds)",
          "type" : "text"
        }]
      }]
  }
}



/**
  * Create group
  */
EdEditor.prototype.addGroup = function(name) {  
  this.engine.addGroup(name);
}

/**
  * Add nodes to Group
  */
EdEditor.prototype.addNodesToGroup = function(group, nodes) {  
  this.engine.addResources(group, nodes);
}

/**
  * Converts the Applications loaded in engine to an HashTable
  * @used: options in Application Dialog to create form
  */
EdEditor.prototype.getApplicationsFromReference = function(reference) {
  var apps = {}, keys = reference.keys; 
  for (i=0;i<keys.length; ++i){
    var uri = keys[i], name = reference.defs[uri].name;
    apps[uri] = name;
  }
  return apps;
}

/**
  * Displays "Select Application" Dialog
  */
EdEditor.prototype.selectApplication = function(t) {
  var app_selections = this.getApplicationsFromReference(this.engine.reference), prop_selections= {};
  this.forms.select_application.elements[0].elements[0].options = app_selections;
  var modal = createDialog("Select an application for Node");
  // Positioning and size
  modal.css("height", "500px").css("width", "650px").css("left", "30%").css("top", "20%");

  $(".modal-container", modal).prepend("<form id=\"select-application\"></form>");  
  $(".modal-container", modal).css("height", "463px").append(this.html.tabs.application);
  $("#select-application").buildForm(this.forms.select_application);
  $("select#app-name").change(this.onApplicationChange.bind(this));
  modal.addClass("dialog-active");
  $("#modal-tabs > li:eq(0)").click();  
  $("#add-application-button").unbind('click').click( this.onApplicationCreate.bind(this));
  $(".modal > .check-button").unbind('click').click( this.onApplicationAdd.bind(this));
  modal.show();
  $("select#app-name").trigger('change');
}

/**
  * Displays "Select Group" Dialog
  */
EdEditor.prototype.selectGroup = function(t) {
  var engine = this.engine,
    modal = createDialog("Select a Group for the node"), 
    i = 0, total = engine.group_keys.length, groups = [],
    groups_tmpl = $.template("tmpl_groups", "<li class=\"group\"><div class=\"group-color\" style=\"background-color: ${color}\"></div> ${name}</li>");
  for (i=engine.group_keys.length;i>0;--i){
    groups.push( {"color" : engine.group_colors[i-1], "name" : engine.group_keys[i-1]} );
  }
  var container = $(".modal-container", modal).html("<form id=\"add-group\"></form>"+
                                "<div class=\"clear\"></div>"+
                                "<ul id=\"groups\"></ul>");
  $.tmpl("tmpl_groups", groups).appendTo("#groups");
  $("#add-group").buildForm(this.forms.select_group);
  modal.addClass("dialog-active");
  modal.show();
}

/**
  * Displays 'Properties" Dialog
  */
EdEditor.prototype.selectProperties = function(t) {
  var engine = this.engine, modal = createDialog("Select Properties for Node:");
  var container = $(".modal-container", modal).html("<form id=\"inet-select\"></form><form id=\"res-properties\"></form>");
  var node = $(".node-selected");
  var form = this.generateResourceProperties(node);
  $("#inet-select").buildForm(this.forms.select_inet);
  $("select#inet-choose").unbind('change').change(this.onInetChange.bind(this));
  $("#res-properties").buildForm(form);
  $(".modal > .check-button").unbind('click').click( this.onResourceSetProperties.bind(this));
  modal.addClass("dialog-active");
  modal.show();
}

/**
  * Displays "Preferences" Dialog
  */
EdEditor.prototype.loadPreferences = function(t) {
  var modal = createDialog("Experiment Preferences").css("width", "400px").css("left", "30%");

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

/**
  * Displays notification on Design Tab
  */
EdEditor.prototype.showNotification = function(text) {
  var notification = "<p class=\"info\">"+text+"</p>";
  $("#design").prepend(notification).slideDown().delay(5000).slideUp();
}

/**
  * Displays the add event in the applications table
  */
EdEditor.prototype.showAddEvent = function(evt) { 
  var engine = this.engine, modal = createDialog("Event");
  var container = $(".modal-container", modal).html("<form id=\"application-add-event\"></form>");
  $("#application-add-event").buildForm(this.forms._event);  
  $(".modal > .check-button").unbind('click').click(this.onApplicationAddEvent.bind(this));
  modal.show();
}

/**
  * Generate the Resource Properties form
  * @used: Resource Properties Dialog
  */
EdEditor.prototype.generateResourceProperties = function(node,inet) {
  var data = this.engine.resources[node.attr("id")];
  var fields = EdEditor.prototype.resource_fields;
  var validations ={};
  if (inet == undefined) {
   inet = "w0";
   validations = Resource.wlan_inet_parameters;
  } else if (inet.indexOf("w") != -1) {
   validations = Resource.wlan_inet_parameters;   
  } else if (inet.indexOf("e") != -1) {    
   validations = Resource.common_inet_parameters;
  }
  var form = { "elements" : [] }
  for(i=0; i<fields.length; ++i){
    var f = fields[i];
    if (f in validations) {
      var v = validations[f],
          type = "text";
      if (v.options != undefined) {
        type = "select"
      } else if (v.bool != undefined) {
        type = "checkbox"
      }
      var value = ""
      if ((data != undefined) && (data.properties.net[inet] != undefined)) {
        value = data.properties.net[inet][f]
      }
      var e =  {
        "type" : "p", 
        "elements" : [{
          "id": "resource-"+f, 
          "name" : "net["+inet+"]["+f+"]", 
          "caption" : v.caption, 
          "type": type,
          "value": value
        }] 
      }
    
      if (type == "select") {
        e.elements[0].options = {"" : "Nothing" };
        // since options comes in an array change for key-value to create selection
        for(j=0;j<validations[f].options.length; ++j){    
          var _opt = validations[f].options[j];
          e.elements[0].options[_opt] = _opt;
        }
      }
      form.elements.push(e);
    }
  }
  return form;
}

/**
  * Generate the Applications Table on the right sidebar
  */
EdEditor.prototype.generateApplicationsTable = function(groups) {
  // empty table
  $("#table-applications > .grid-view-row:not(.grid-view-header)").remove();
  $(".node-highlight").removeClass("node-highlight");

  var data = new Array(), has_apps = false;
  // generate data set
  for (var gname in groups){
    var group = groups[gname];
    for (var uri in group.applications){
      has_apps = true;
      data.push({ color:group.color, app:uri, group:group.name });
    }
  }
  // create template 'XXX' => move all templates to header
  // insert to tables
  var group_table_tmpl = $.template("tmpl_apps", ""+
    "<div class=\"grid-view-row\">"+
      "<div class=\"sidetable-app-select group-color\" style=\"background-color: ${color}\">"+
        "<input value=\"${group}\" type=\"hidden\"/>"+
      "</div>"+
      "<div>${app}</div>"+
    "</div>");
  $.tmpl("tmpl_apps", data).appendTo("#table-applications");
  if (has_apps) {  
    $("#table-applications").removeClass("hidden");
  } else {
    $("#table-applications").addClass("hidden");
  }
}

/**
  * Generate the Groups Table on the right sidebar
  */
EdEditor.prototype.generateGroupsTable = function(groups) {
  // empty table
  $("#table-groups > .grid-view-row:not(.grid-view-header)").remove();
  $(".node-highlight").removeClass("node-highlight");
  
  var data = new Array(), has_groups = false;
  // generate data set
  for (gname in groups){
    var group = groups[gname];
    if (group.ids.length > 0) {
      has_groups = true;
      var nodes_str = group.ids.join(",").replace(/node-/gi, "");  
      data.push({color: group.color, name : group.name, nodes:nodes_str});
    }
  }
  // create template 'XXX' => move all templates to header
  // insert to tables
  var group_table_tmpl = $.template("tmpl_groups", ""+
    "<div class=\"grid-view-row\">"+
      "<div class=\"sidetable-group-select group-color\" style=\"background-color: ${color}\">"+
        "<input value=\"${name}\" type=\"hidden\"/>"+
      "</div>"+
      "<div>${nodes}</div>"+
    "</div>");
  $.tmpl("tmpl_groups", data).appendTo("#table-groups");

  if (has_groups) {  
    $("#table-groups").removeClass("hidden");
  } else {
    $("#table-groups").addClass("hidden");
  }  
}

/**
  * Generates the Timeline
  */
EdEditor.prototype.generateTimeline = function() {
  var timeline = this.engine.timeline
  $(".events").empty();
  for (var g in timeline.events){
    var group = this.engine.groups[g]
    var evt = timeline.events[g]
    var left = timeline.width * ( evt.start / timeline.interval );
    var width = timeline.width * ( evt.duration / timeline.interval );

    $(".events").append("<li id="+g+"></li>");
    $(".events > #"+g).css("left", left+"%").css("width", width+"%").css("background-color", group.color);
  }
}

/**
  * Event triggered when selecting on of the displayed tables (Groups|Applications)
  */
EdEditor.prototype.selectTableItems = function(table, selected, cb) { 
  var all_sel = $(".grid-view-row-selected", table);
  all_sel.toggleClass("grid-view-row-selected")
  if (cb != undefined) {
    cb();
  }

  if (all_sel.length == 1) {
    var id = $("div:eq(1)", all_sel).html(),
       _id = $("div:eq(1)", $(selected)).html();
    if (id == _id) {
      return false;
    }
  }
  $(selected).toggleClass("grid-view-row-selected");

  return true;
}


/**
  * Event triggered when selecting an item from Groups Table
  */
EdEditor.prototype.onGroupsTableClick = function(evt){
  var n = $(evt.target).parent();
  var same = this.selectTableItems($(n).parent(), n, function(){ 
    $(".node-highlight").toggleClass("node-highlight");
  });  
  var gname = $("#table-groups > .grid-view-row-selected > .group-color > input ").attr("value");
  if (gname != undefined){
    var ids = $(this.engine.groups[gname].ids).map(function(index, elem){ return "#"+elem }).get().join(",");
  }
  if (same) { 
    $("#table-groups-actions").show();
    $(ids).toggleClass("node-highlight")
    return false; 
  }
  var nsel = $(".grid-view-row-selected", $(n).parent()).length;  
  if (nsel>0) {
    $("#table-groups-actions").show();
    $(ids).toggleClass("node-highlight");
  } else {
    $("#table-groups-actions").hide();
    $(".node-highlight").toggleClass("node-highlight");
  }
  return false;
}


/**
  * Event triggered when selecting an item from Applications Table
  */
EdEditor.prototype.onApplicationsTableClick = function(evt){  
  var n = $(evt.target).parent();
  var same = this.selectTableItems($(n).parent(), n);  
  var gname = $("#table-applications > .grid-view-row-selected > .group-color > input ").attr("value");
  if (same) { 
    $("#table-applications-actions").show();
    return false; 
  }
  var nsel = $(".grid-view-row-selected", $(n).parent()).length;  
  if (nsel>0) { $("#table-groups-actions").show(); } 
  else { $("#table-applications-actions").hide(); }
  return false;
}

/**
  * Event triggered when changed the Network Interface, when filling Group/Node Properties Dialog
  */
EdEditor.prototype.onInetChange = function(evt) {  
  var v = evt.currentTarget.value,
      node = $(".node-selected"),
      properties = this.engine.resources[node.attr("id")],
      form = this.generateResourceProperties(node, v);
  $("#res-properties").empty();
  $("#res-properties").buildForm(form);
}

/**
  * Event triggered when clicked the "Confirm" button when filling Group/Node Properties Dialog
  */
EdEditor.prototype.onResourceSetProperties = function(evt){  
  var params = $("#res-properties").formParams();
  var nodes = $(".node-selected");
  var groups = this.engine.findGroups($(".node-selected"));
  var g;
  if ((groups.length == 1) && (groups[0].isEqual(nodes))) {
    g = groups[0];
  } else if (groups.length == 0){
    g = this.engine.groups[this.engine.addGeneratedGroup(nodes)]

  }

  if (g != undefined){
    this.engine.setResourceGroupProperties( g, params);
    this.engine.setResourceProperties(nodes.attr("id"), params);
    nodes.css("background-color", g.color);
    this.generateGroupsTable(this.engine.groups);
    closeDialog("#modal-dialog");
    nodes.trigger("click");
  }
}

/**
  * Event triggered when clicked the "Confirm" button when filling Application Dialog
  */
EdEditor.prototype.onApplicationAdd = function(evt){
  var application = $("#select-application").formParams(),
      properties = $("#select-properties").formParams(),
      measures = $("#select-measures").formParams(),
      has_create = ($("#create_flag").attr("value") == 1),  
      nodes = $(".node-selected"),  
      gname = this.engine.addGeneratedGroup(nodes), 
      color = this.engine.groups[gname].color,
      app = { 
        "uri" : application.resource.application, 
        "options" : properties, 
        "measures" : measures 
      };

  if (has_create){
    var info = $("#select-info").formParams().info,
        uri = (info.uri == "" || info.uri == undefined) ? info.name : info.uri;
    var eproperties = {};
    for (p in properties.properties){
      var _p = properties.properties[p];
      eproperties[p] = _p.value;
    }

    app = { 
      "uri" : info.uri,  
      "options" : {
        "selected" : properties.selected,
        "properties": eproperties
      }
    };
    this.engine.saveApplication(info, properties.properties);
  }

  // modify groups
  this.engine.addApplication(gname, app);

  //modify tables
  this.generateGroupsTable(this.engine.groups);
  this.generateApplicationsTable(this.engine.groups);

  // testbed group styling
  nodes.css("background-color", color);
  closeDialog("#modal-dialog");
  nodes.trigger("click");
}

/**
  * Event triggered when clicked the "Add" button from Groups Dialog
  */
EdEditor.prototype.onGroupAdd = function(evt) {  
  var params = $("#add-group").formParams();
  // add to engine
  evt.data.editor.addGroup(params.group.name);
  hideDialog();
  return false;
}


/**
  * Event triggered when it clicked remove group near table
  */
EdEditor.prototype.onGroupRemove = function(evt) {
  var groups = $("#table-groups > .grid-view-row-selected > .group-color > input ");
  for(i=0;i<groups.length;++i){
    var g = $(groups[0]).attr("value");
    this.engine.removeGroup(g);
  }
  $(".node-highlight").css("background-color", "");
  $(".sidetable-group-select").click();
  this.generateApplicationsTable(this.engine.groups);
  this.generateGroupsTable(this.engine.groups);
  //evt.preventDefault();
  return false;
}

/**
  * Event triggered when selecting a group
  */
EdEditor.prototype.onGroupSelection = function(evt) {
  var text = $(evt.target).text().trim(), 
      color = $(".group-color", evt.target).css("background-color"), 
      nodes = $(".node-selected");
  // add to engine
  evt.data.editor.addNodesToGroup(text, nodes);  
  this.generateGroupsTable(this.engine.groups);
  nodes.css("background-color", color);
  //nodes.toggleClass("node-selected");  
  hideDialog();
  nodes.trigger("click");
  return false;
}

/**
  * Event triggered when "Preferences" button is clicked
  */
EdEditor.prototype.onPreferencesOpen = function(evt) {  
  evt.data.editor.loadPreferences();
}

/**
  * Event Triggered on all nodes click
  */ 
EdEditor.prototype.onNodeClick = function(e) {
    $(e.target).toggleClass("node-selected");
    var nodes = $(".node-selected");
    var n_nodes = nodes.length;
    $(".oedl-action-button").remove();
    if (n_nodes >= 1) {
      var check_all_group = false;
      var groups = this.engine.findGroups(nodes);
      if (groups.length==1){
        if (groups[0].isEqual(nodes)) {
          check_all_group = true;
        }
      }

      if (check_all_group) {
        $(".oedl-actions").prepend(this.nodes_selected.group)
      } else if (n_nodes == 1 && groups.length == 0) {
        $(".oedl-actions").prepend(this.nodes_selected.single)
      } else if (n_nodes > 1 && groups.length == 0) {
        $(".oedl-actions").prepend(this.nodes_selected.multiple)
      }
    }
}

/**
  * Event triggered when it clicked add event near table
  */
EdEditor.prototype.onApplicationAddEvent = function(evt) {
  var gname = $("#table-applications > .grid-view-row-selected > .group-color > input ").attr("value");
  var p = $("#application-add-event").formParams();
  e = this.engine.timeline.addEvent(gname, p.event.start, p.event.duration);
  hideDialog();
  this.generateTimeline();
  return false;
}

/**
  * Event triggered when it clicked remove application near table
  */
EdEditor.prototype.onApplicationRemove = function(evt) {  
  var groups = $("#table-applications > .grid-view-row-selected > .group-color > input"),
      uri = $("#table-applications > .grid-view-row-selected > div:eq(1)").html();
  for(i=0;i<groups.length;++i){
    var g = $(groups[0]).attr("value");
    this.engine.groups[g].removeApplication(uri);
  }
  $(".sidetable-app-select").click();
  this.generateApplicationsTable(this.engine.groups);
  return false;
}

EdEditor.prototype.fillApplicationForms = function(defs,pp,ms,mode) {
    var defs_ct = $("#content-application").empty(), 
        pp_ct = $("#select-properties").empty(),
        ms_ct = $("#select-measures").empty(),    
        defs_data = [], pp_data = [], ms_data = [];
    if (mode==undefined) {
      pp_ct.append("<div class=\"grid-view-row grid-view-header\">"+
        "<div>Name</div>"+
        "<div>Description</div>"+
        "<div>Value</div>"+
      "</div>");
    } else if (mode=="insert") {
      pp_ct.append("<div class=\"grid-view-row grid-view-header\"><div>Name</div><div>Description</div><div style=\"min-width:80px;max-width:250px\">Value</div></div>");
    }

    for(d in defs) { defs_data.push({ key: d, value: defs[d]}); }
    for(d in pp) { pp_data.push({ key: d, value: pp[d].description }); }
    for(d in ms) { 
      ms_data.push({ 
        key: d, 
        metrics: (function() {
            var values=[];
            var measurement = ms[d];
            for(m in measurement){ 
              values.push({ name: m, type : measurement[m]["type"] })
            }
            return values;
          })()
      }); 
    }
    if (mode==undefined){
      $.tmpl("display_info", defs_data).appendTo("#content-application");
      $.tmpl("display_property", pp_data).appendTo("#select-properties");
      $.tmpl("display_measures", ms_data).appendTo("#select-measures");
    } else if(mode=="insert") {
      $("#content-application").html("<form id=\"select-info\"></form>");
      $.tmpl("insert_info", defs_data).appendTo("#select-info");
      $.tmpl("insert_property", [{}]).appendTo("#select-properties");      
    }    
    pp_ct.html("<div class=\"grid-view\">"+pp_ct.html()+"</div>");    
}

EdEditor.prototype.onApplicationPropertyAdd = function(evt) {
  var params = $("#select-properties").formParams(),
      property = { key : params.property_name, value : params.property_value, description: params.property_description },
      display = { key:property.key, value:property.description };
  if (params.has_value=="on") {
    property['has_value'] = true;
    display['v'] = property.value;
  }
  var item = $.tmpl("inserted_property", display),
      context = $("#select-properties");
  $(".grid-view > .grid-view-row:last", context).before(item);  
  $("input[name=property_name]", context).val("");
  $("input[name=property_description]", context).val("");
  $("input[name=property_value]", context).val("");
  $("input[name=has_value]", context).attr('checked', false); 
}

/**
  * Event triggered when "New application" button is clicked
  */
EdEditor.prototype.onApplicationCreate = function(evt) {  
    $("#create_flag").attr("value", "1");  
    var defs = this.engine.reference.default.defs,
        pp = this.engine.reference.default.properties,
        ms = this.engine.reference.default.measures;
    this.fillApplicationForms(defs,pp,ms, "insert");
    $("a[href=#content-measures]").parent().addClass("hidden");
    $("#add-application-property-button").unbind('click').click(this.onApplicationPropertyAdd.bind(this));
}

EdEditor.prototype.onApplicationChange = function(evt) {  
    $("#create_flag").attr("value", "0");  
    var v = evt.currentTarget.value,
        defs = this.engine.reference.defs[v],
        pp = this.engine.reference.properties[v],
        ms = this.engine.reference.measures[v];
    this.fillApplicationForms(defs,pp,ms);
    $("a[href=#content-measures]").parent().removeClass("hidden");
}

EdEditor.prototype.bindEvents = function() {
  var editor = this;

  // Node events click and context menu
  $(".node").live("click",this.onNodeClick.bind(editor));
  //$(".node").contextMenu('nodeCtxMenu', { 
  //  onContextMenu : function(e) {
  //    $(e.target).addClass("node-selected");
  //    return true;
  //  }, bindings : {
  //    'application' : editor.selectApplication.bind(editor),
  //    'group' : editor.selectGroup.bind(editor),
  //    'properties' : editor.selectProperties.bind(editor)
  //  }
  //});

  // Table actions
  $(".sidetable-app-select").live('click', this.onApplicationsTableClick.bind(editor));
  $(".sidetable-group-select").live('click', this.onGroupsTableClick.bind(editor)); 
  $(".remove-group-item").live('click', this.onGroupRemove.bind(editor));
  $(".remove-application-item").live('click', this.onApplicationRemove.bind(editor));
  $(".addevent-application-item").live('click', this.showAddEvent.bind(editor));
  
  // Dialog open events
  $("#btn_properties").live('click', this.selectProperties.bind(editor));
  $("#btn_group").live('click',this.selectGroup.bind(editor));
  $("#btn_application").live('click', this.selectApplication.bind(editor));
  $(".preferences-view-action").live("click", {editor : this}, this.onPreferencesOpen)
  
  // In-Dialog
  $("#groups > li.group").live("click", {editor : this}, this.onGroupSelection.bind(editor))
  $(".group-add-action").live("click", {editor : this}, this.onGroupAdd)
  $(".prop-check").live("change", function(evt){
      var p = $(evt.target).parent();
      $(p).children("input[type='text']").toggleClass("hidden");
  });
  // generated code
  $("li > a[href=#source]").click({editor:this}, function(evt){
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

  // Sidetabs from source view
  $(".sidetabs:not(#modal-tabs) li").live('click', function(evt){        
    var href = $(this).find("a").attr("href").replace("#",""),
        active_tab = $($(this).find("a").attr("href"));
    $(".sidetab").hide();
    $(".sidetabs li").removeClass("sidetab-active");
    $(this).addClass("sidetab-active");    
    active_tab.fadeIn().focus();
    $(".CodeMirror-wrapping").remove();
    CodeMirror.fromTextArea(href+"_code", {
        parserfile: ["../tokenizeruby.js", "../parseruby.js"],
        stylesheet: "/stylesheets/codemirror/rubycolors.css",
        path: "/javascripts/codemirror/base/",
        lineNumbers: false,
        textWrapping: true,
        indentUnit: 2,
        parserConfig: {},
        readOnly: false,
        height: "400px",
        width: "100%"
    });

    return false;
  });  
}

