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
  var timeline = this.engine.timeline,
      nevt = $.keys(timeline.events).length,
      duration = this.engine.properties.duration;
  if (nevt == 0 && duration) {
    timeline.addEvent("_all_", 0, duration, null);
  }
  timeline.scale(min, max, scale);
  
  // Generate intervals
  $(".intervals").empty();
  for(var i=0; i<timeline.intervals; ++i){
    $(".intervals").append("<li><span>"+timeline.labelize(i*timeline.raw_interval, scale)+"</span></li>");
  }
  $(".intervals > li").css("width", timeline.width+"%");


  // Generate events
  $(".events").empty();
  for (var g in timeline.events){
    var group = this.engine.groups[g],
        evts = timeline.events[g],
        exec_evts = timeline.events[g].exec,
        app_evt = timeline.events[g].applications;

    if (app_evt && app_evt.id) {
      this.addTimelineEvent.bind({timeline : timeline})(g, evts.applications, group);
    }

    for (var eevt in exec_evts){
      this.addTimelineEvent.bind({timeline : timeline})(g, exec_evts[eevt], group);
    }
  }
  timeline.removeEvent("_all_");
}

EdEditor.prototype.addTimelineEvent = function(g, evt, group) {  
  var timeline = this.timeline,
      has_command = (evt.duration == -1),
      duration = (has_command ? 1 : evt.duration),
      left = timeline.width * ( evt.start / timeline.interval ),
      width = timeline.width * ( duration / timeline.interval ),
      id = g + "-" +evt.id;

  $(".events").append("<li class=\"" + (has_command ? "oedl-command-event" : "") + "\"" +
        " id=\""+id+"\"><span>"+duration+"</span></li>");
  
  var jevt = $(".events > #"+id).css("left", left+"%").css("width", width+"%")
  if (group) { jevt.css("background-color", group.color); }
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

EdEditor.prototype.fillApplicationForms = function(defs,pp,ms,mode) {
    var defs_ct = $('#content-application').empty(),
        pp_ct = $('#select-properties').empty(),
        ms_ct = $('#select-measures').empty(),
        defs_data = [], pp_data = [], ms_data = [];
    if (mode == undefined) {
      pp_ct.append('<div class=\"grid-view-row grid-view-header\">'+
        '<div>Name</div>'+
        '<div>Description</div>'+
        '<div>Value</div>'+
      '</div>');
    } else if (mode == 'insert') {
      pp_ct.append('<div class=\"grid-view-row grid-view-header\"><div>Type</div><div>Name</div><div>Description</div><div style=\"min-width:80px;max-width:250px\">Value</div></div>');
    }

    for (d in defs) { defs_data.push({ key: d, value: defs[d]}); }
    for (d in pp) { pp_data.push({ key: d, value: pp[d].description }); }
    for (d in ms) {
      ms_data.push({
        key: d,
        metrics: (function() {
            var values = [];
            var measurement = ms[d];
            for (m in measurement) {
              values.push({ name: m, type: measurement[m]['type'] });
            }
            return values;
          })()
      });
    }
    if (!mode) {
      $.tmpl('display_info', defs_data).appendTo('#content-application');
      $.tmpl('display_property', pp_data).appendTo('#select-properties');
      $.tmpl('display_measures', ms_data).appendTo('#select-measures');
    } else if (mode == 'insert') {
      $('#content-application').html('<form id=\"select-info\"></form>');
      $.tmpl('insert_info', defs_data).appendTo('#select-info');
      $.tmpl('insert_property', [{}]).appendTo('#select-properties');
    }
    pp_ct.html('<div class=\"grid-view\">'+ pp_ct.html() + '</div>');
    //$.uniformize("#content-application");
    //$.uniformize("#select-properties");
    //$.uniformize("#select-measures");
};
