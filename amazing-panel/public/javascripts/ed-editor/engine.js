// Some Array and String utilities
Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

String.prototype.trim = function() {
  return this.replace(/^\s+|\s+$/g, '');
};
String.prototype.ltrim = function() {
  return this.replace(/^\s+/, '');
};
String.prototype.rtrim = function() {
  return this.replace(/\s+$/, '');
};

/**
 * Resource
 * @constructor
 */
function Resource(id, properties) {
  this.id = id;
  this.properties = properties;
}

Resource.merge = function merge(obj1, obj2) {
    for (attr in obj2)
        obj1[attr] = obj2[attr];
    return obj1;
};

Resource.prototype.getProperties = function() {
  return this.properties;
};

Resource.common_inet_parameters = {
  ip: {
    value: '',
    caption: 'IP Address'
  },
  netmask: {
    value: '',
    caption: 'Network Mask'
  }, state: {
    value: true,
    caption: 'State',
    bool: false
  }, mtu: {
    caption: 'MTU',
    value: ''
  }, mac: {
    caption: 'MAC',
    value: ''
  }, route: {
    op: { value: '', options: ['add', 'del'] },
    net: { value: '' },
    gw: { value: '' },
    mask: { value: '' }
  }, filter: {
    op: {
      value: '',
      options: ['add', 'del', 'clear']
    }, chain: {
      value: '',
      options: ['input']
    }, target: {
      value: '',
      options: ['drop']
    }, proto: {
      value: '',
      options: ['mac', 'tcp'],
      needed: [['src'], ['src', 'dst', 'sport', 'dport']]
    }, src: '', sport: '', dst: '', dport: ''
  }
};

Resource.wlan_inet_parameters = Resource.merge({
  mode: {
    caption: 'Mode',
    value: '',
    options: ['ad-hoc', 'managed', 'master']
  }, type: {
    caption: 'Type',
    value: '',
    options: ['a', 'b', 'g']
  },
  rts: { value: '', options: ['add', 'clear', ''] },
  rate: { value: '' },
  essid: {
    caption: 'ESSID',
    value: ''
  },
  channel: {
    caption: 'Channel',
    value: ''
  },
  tx_power: {
    caption: 'Transmission Power',
    value: ''
  }
}, Resource.common_inet_parameters);


Resource.inet_type_parameter = ['e0', 'e1', 'w0', 'w1'];

Resource.prototype.properties = {
  id: 0,
  group: '',
  properties: {}
};

/**
 * @constructor
 */
function Group(name, color) {
  this.name = name;
  this.color = color;
  this.nodes = {};
  this.ids = [];
  this.nid = 0;
  this.applications = {};
  this.properties = {};
}

Group.prototype.addResource = function(resource) {
  this.nodes[resource.id] = resource;
  this.ids.push(resource.id);
  ++this.nid;
};

Group.prototype.addResources = function(resources) {
  for (i = 0; i < resources.length; ++i) {
    this.addResource(resources[i]);
  }
};

Group.prototype.removeResource = function(resource) {
  var id = resource;
  if (resource.id != undefined) {
    id = resource.id;
  }
  if (id in this.nodes) {
    // 'XXX' double check delete - don't apply to native hash tables
    delete this.nodes[resource];
    this.ids.remove(this.ids.indexOf(resource.id), null);
  }
};

Group.prototype.removeResources = function(resources) {
  for (i = 0; i < resources.length; ++i) {
    this.removeResource(resources[i]);
  }
};

Group.prototype.getId = function() {
  return this.nid;
};

Group.prototype.getResource = function(id) {
  return this.nodes[id];
};

Group.prototype.addApplication = function(application) {
  this.applications[application.uri] = application;
};

Group.prototype.removeApplication = function(uri) {
  delete this.applications[uri];
};

Group.prototype.setResourceProperties = function(properties) {
  this.properties = Resource.merge(this.properties, properties);
};

Group.prototype.isEqual = function(nodes) {
  var nodes_sel_str = nodes.map(function() { return this.id; }).get().join(','),
      group_nodes_str = this.ids.join(',');

  return (nodes_sel_str == group_nodes_str);
};

/**
 * @constructor
 */
function Timeline(width) {
  this.interval = 20;
  this.raw_interval = 20; // always in seconds
  this.width = 14.17;
  this.intervals = 7;
  this.events = {};
  this.unit = 's';
  this.size = width;
  this.max = 120;
}

Timeline.prototype.getIntervalNumber = function(size) {
  if (size && !intervals) {
    return size / this.width;
  } else {
    return this.invertals;
  }
};

Timeline.prototype.setIntervalNumber = function(size, intervals) {
  if (size && intervals) {
    this.width = size / intervals;
  }
};

Timeline.prototype.scale = function(min, max, unit) {
  this.findMax();
  if (!min && !max) { min = 0; max = this.convertToSeconds('seconds', this.max); }
  if (!unit) { unit = 'seconds' }
  this.raw_interval = Math.round(max / (this.intervals - 1));
  this.interval = this.convertSecondsToUnit(unit, this.raw_interval);
};

Timeline.prototype.labelize = function(value, unit) {
  var d = new Date(value * 1000);
  if (unit == 'hours' || unit == 'h') { return d.getHours() + 'h'+ d.getMinutes() + 'm'; }
  if (unit == 'minutes' || unit == 'm') { return d.getMinutes() + 'm'+ d.getSeconds(); }
  return d.getMinutes() * 60 + d.getSeconds() + 's';
};

Timeline.prototype.convertSecondsToUnit = function(unit, value) {
  if (unit == 'minutes' || unit == 'm') { return value / 60; }
  if (unit == 'hours' || unit == 'h') { return value / 3600; }
  if (unit == 'seconds') { return value; }
};

Timeline.prototype.convertToSeconds = function(unit, value) {
  if (unit == 'minutes' || unit == 'm') { return value * 60; }
  if (unit == 'hours' || unit == 'h') { return value * 3600; }
  if (unit == 'seconds') { return value; }
};

Timeline.prototype.fromWidth = function(width, unit) {
  var st_width = (this.width / 100) * this.size;
  return Math.round((width * 20) / st_width);
};

Timeline.prototype.findMax = function() {
  var current = this.max, events = this.events;
  for (g in events) {
    var evt = events[g];
    if (evt.stop > current) { current = evt.stop }
  }

  if (current > this.max) {
    this.max = current;
    return true;
  } else {
    return false;
  }
};

Timeline.prototype.changeDuration = function(group, duration) {
  var evt = this.events[group];
  evt.stop = evt.start + duration;
  evt.duration = duration;
  this.events[group] = evt;
};

Timeline.prototype.createEvent = function(start, duration) {
  var stop = (duration > 0 ? start + duration : -1),
      evt = {
        id : "default",
        start: start,
        stop: stop,
        duration: duration,
      };
  return evt
}

Timeline.prototype.removeEvent = function(group) {
  var ret = false;
  if (group == "_all_") {
    delete this.events[group]
    return true
  }
  var tks = group.split("-"),
      g = tks[0], evt_id = tks[1],
      evt = {};
  if (evt_id == "default"){
    delete this.events[g].applications; 
    ret = true;
  } else {
    delete this.events[g].exec[evt_id]; 
    ret = true;
  }
  this.removeEventGroup(g);
  return ret;
};

Timeline.prototype.removeEventGroup = function(group){
  var n_exec_evts = $.keys(this.events[g].exec).length,
      app_event = this.events[g].applications;
  if (n_exec_evts == 0 && (!app_event || app_event != {})){
    delete this.events[g];
    return true
  }
  return false
}

Timeline.prototype.addEvent = function(group, start, duration, command) {
  // Accept UTC dates and convert them to seconds
  var evt = this.createEvent(start, duration);

  if (!this.events[group]){
    this.events[group] = { exec : {}, applications : {} }
  }

  if (command) {
    evt.command = command;
    evt.id = $.keys(this.events[group].exec).length + "";
    this.events[group].exec[evt.id] = evt;
  } else {
    this.events[group].applications = evt;
  }
  return this.events[group];
};

/**
 * @constructor
 */
function Engine(tm_size) {
  var color = 'rgb(255,0,0)';
  this.groups = { 'default' : new Group('default', color) };
  this.group_keys = ['default'];
  this.group_colors = [color];
  this.resources = {};
  this.reference = {
    keys: [],
    defs: {},
    properties: {},
    measures: {},
    my: {
      applications: {}
    },
    d: {
      defs: { uri: '', shortDescription: '', path: '', description: '', name: '', version: '' },
      properties: {},
      measures: {}
    }
  };
  this.properties = { duration: 120 };
  this.timeline = new Timeline(tm_size);


  $.getJSON('/eds/doc.json?type=all', function(data) {
    this.loadOEDLReference(data);
  }.bind(this));
}

Engine.prototype.setExperimentProperties = function(properties) {
  this.properties = properties;
};

Engine.prototype.getExperimentProperties = function() {
  return this.properties;
};

Engine.prototype.addResources = function(groupname, resources) {
  //for (j=0; j<this.group_keys.length; ++j){
  //  var g = this.group_keys[j];
  //  this.groups[g].removeResources(resources);
  //}
  var group = this.groups[groupname];
  group.addResources(resources);
};

Engine.prototype.addResource = function(groupname, resource) {
  return this.groups[groupname].addResource(resource);
};

Engine.prototype.removeGroup = function(name) {
  var index = this.group_keys.indexOf(name);
  delete this.groups[name];
  this.group_keys.remove(index, null);
};

Engine.prototype.setResourceGroupProperties = function(group, properties) {
  var gname = group.name;
  this.groups[gname].setResourceProperties(properties);
};

Engine.prototype.setResourceProperties = function(id, properties) {
  this.resources[id] = new Resource(id, properties);
};

Engine.prototype.addGroup = function(name) {
  this.group_keys.push(name);
  var g = this.groups[name], color = rgb_color(1 / this.group_keys.length);
  this.groups[name] = new Group(name, color);
  this.group_colors.push(color);
  return 0;
};

Engine.prototype.generateGroupName = function(nodes) {
  var gname = '__group_';
  var id;
  for (i = 0; i < nodes.length; ++i) {
    id = nodes[i].id.replace('node-', '');
    gname = gname + 'n'+ id + '_';
  }
  return gname;
};

Engine.prototype.findGroups = function(nodes) {
  var __groups = new Array();
  var __group;
  for (i = 0; i < nodes.length; ++i) {
    var node = nodes[i];
    for (var gname in this.groups) {
      var g = this.groups[gname];
      if ((g.ids.indexOf($(node).attr('id')) != -1) && (__groups.indexOf(g) == -1)) {
        __groups.push(g);
      }
    }
  }
  return __groups;
};

Engine.prototype.addGeneratedGroup = function(nodes) {
  var __groups = this.findGroups(nodes);
  if (__groups.length == 1 && __groups[0].isEqual(nodes)) {
    return __groups[0].name;
  }
  var gname = this.generateGroupName(nodes);
  for (i = 0; i < __groups.length; ++i) {
    var gn = __groups[i];
    gn.removeResources(nodes);
    //if (__groups[i] != "default"){
      //this.removeGroup(__groups[i]);
    //}
  }
  this.addGroup(gname);
  this.addResources(gname, nodes);
  return gname;
};

Engine.prototype.addApplication = function(gname, application) {
    this.groups[gname].addApplication(application);
};

Engine.prototype.saveApplication = function(info, properties) {
  var app = {
    name: info.name,
    options: $.extend(info, { properties: {} })
  };
  for (p in properties) {
    var prop = properties[p];
    app.options.properties[p] = {
      description: prop.description,
      mnemonic: '',
      options: $.extend(prop.options, {
        dynamic: 'false'
      })
    };
  }
  this.reference.my.applications[info.uri] = app;
};

// 'XXX' double check delete - don't apply to native hash tables
Engine.prototype.loadOEDLReference = function(data) {
  var tmp = this.reference;
  for (uri in data) {

    tmp.keys.push(uri);
    tmp.properties[uri] = data[uri].properties;
    tmp.measures[uri] = data[uri].measures;
    delete data[uri].properties;
    delete data[uri].measures;
    // only app description remaining
    tmp.defs[uri] = data[uri];
  }
  this.reference = tmp;
};

Engine.prototype.getApplicationDefinition = function(uri, cb) {
  $.getJSON('/eds/doc.json?type=app&name='+ uri, function(data) {
    cb(data);
  }.bind(this));
};


Engine.prototype.getGeneratedCode = function() {
  var engine = this, events = engine.timeline.events;
  var groups_data = new Array();
  var group_events = new Array();
  for (var g in engine.groups) {
    var group = engine.groups[g];
    var _nodes = new Array();
    for (var node in group.nodes) {
      _nodes.push(node.replace('node-', ''));
    }
    groups_data.push({ name: g, nodes: _nodes, applications: group.applications, properties: group.properties });
  }

  // generate data to get timeline from server
  for (var g in events) {
    var default_evt = events[g].applications;
    group_events.push({ group: g, start: default_evt.start, stop: default_evt.stop, command: default_evt.command });  
    for (var eevt in events[g].exec){
      var evt = events[g].exec[eevt];
      group_events.push({ group: g, start: evt.start, stop: evt.stop, command: evt.command });  
    }
  }

  var data = {
    apps: this.reference.my,
    meta: {
      groups: groups_data,
      properties: engine.properties
    },
    timeline: group_events
  };
  $.post('/eds/code.js', data);
};
