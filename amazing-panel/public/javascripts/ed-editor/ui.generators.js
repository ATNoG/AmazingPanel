/**
  * Generate the Resource Properties form
  * - used: Resource Properties Dialog
  */
EdEditor.prototype.generateResourceProperties = function(node,inet) {
  var data = this.engine.resources[node.attr("id")];
  var fields = EdEditor.prototype.resource_fields;
  var validations ={};
  if (!inet) {
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
      if (v.options) {
        type = "select"
      } else if (v.bool) {
        type = "checkbox"
      }
      var value = ""
      if ((data) && (data.properties.net[inet])) {
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
  // insert to tables
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
  // insert to tables
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
EdEditor.prototype.generateTimeline = function(min, max, scale) {  
  var timeline = this.engine.timeline;
  timeline.scale(min, max, scale);
  $(".intervals").empty();

  // Generate intervals
  for(var i=0; i<timeline.intervals; ++i){
    $(".intervals").append("<li><span>"+timeline.labelize(i*timeline.raw_interval, scale)+"</span></li>");
  }
  $(".intervals > li").css("width", timeline.width+"%");

  // Generate events
  // 'XXX' add support when it only has duration, with no events
  $(".events").empty();
  for (var g in timeline.events){
    var group = this.engine.groups[g]
    var evt = timeline.events[g]
    var left = timeline.width * ( evt.start / timeline.interval );
    var width = timeline.width * ( evt.duration / timeline.interval );

    $(".events").append("<li id="+g+"><span>"+evt.duration+"</span></li>");
    $(".events > #"+g).css("left", left+"%").css("width", width+"%").css("background-color", group.color);
  }
}

/**
  * Generates the Timeline Event Actions
  */
EdEditor.prototype.generateEventActions = function(del) {
  if (del){ $(".oedl-timeline-actions").empty(); } 
  else {
    $(".oedl-timeline-actions").html("<a href=\"#\" class=\"cduration-timeline-item\">Change Duration</a><a href=\"#\" class=\"removeevent-timeline-item\">Remove Event</a>");
  }
}
