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
  var same = this.selectTableItems($(n).parent(), n, null);  
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
    var defs = this.engine.reference.d.defs,
        pp = this.engine.reference.d.properties,
        ms = this.engine.reference.d.measures;
    this.fillApplicationForms(defs,pp,ms, "insert");
    $("a[href=#content-measures]").parent().addClass("hidden");
    $("#add-application-property-button").unbind('click').click(this.onApplicationPropertyAdd.bind(this));
}

/**
 * Event triggered when choose application in the dropdown inside Application Dialog
 */
EdEditor.prototype.onApplicationChange = function(evt) {  
    $("#create_flag").attr("value", "0");  
    var v = evt.currentTarget.value,
        defs = this.engine.reference.defs[v],
        pp = this.engine.reference.properties[v],
        ms = this.engine.reference.measures[v];
    this.fillApplicationForms(defs,pp,ms,null);
    $("a[href=#content-measures]").parent().removeClass("hidden");
}

/**
 * Event triggered when hovering on the timeline
 */
EdEditor.prototype.onTimelineSelector = function(evt) {
  if (evt.layerX != 0){
    $(".oedl-timeline-selector").css("visibility", "visible").css("left", (evt.layerX - 16).toString() + "px");
  }
}

/**
  * Event triggered when selecting on of the displayed tables (Groups|Applications)
  */
EdEditor.prototype.selectTableItems = function(table, selected, cb) { 
  var all_sel = $(".grid-view-row-selected", table);
  all_sel.toggleClass("grid-view-row-selected")
  if (cb) {
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

EdEditor.prototype.bindEvents = function() {
  var editor = this;

  // Node events click and context menu
  $(".node").live("click",this.onNodeClick.bind(editor));

  // Timeline selector
  $(".oedl-timeline").live("mouseover", this.onTimelineSelector.bind(editor));
  $(".oedl-timeline").live("mouseleave", function(evt){ 
      $(".oedl-timeline-selector").css("visibility", "hidden").css("left", "0px");
  });

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

