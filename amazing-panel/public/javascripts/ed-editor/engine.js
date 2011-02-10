// Some Array and String utilities
Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

String.prototype.trim = function() {
  return this.replace(/^\s+|\s+$/g,"");
}
String.prototype.ltrim = function() {
  return this.replace(/^\s+/,"");
}
String.prototype.rtrim = function() {
  return this.replace(/\s+$/,"");
}

/**
 * Designer engine
 */
function Resource(id){
  this.id = id;
}

Resource.merge = function merge(obj1, obj2) {
    for(attr in obj1)
        obj2[attr]=obj1[attr];
    return obj2;
}

Resource.prototype.getProperties = function(){
  return this.properties;
}

Resource.common_inet_parameters = { 
  ip : "",
  netmask : "",
  down : "",
  up : "",
  mtu : "",  
  mac : "",
  route : { op : "", net : "", gw : "", mask : "" },
  filter: { op : "", chain : "", target : "",  src : "", sport : "", dst : "", dport : "" },
}

Resource.wlan_inet_parameters = Resource.merge({ 
  mode : "",
  type : "",
  rts : "",
  rate : "",
  essid : "",
  channel : "",
  tx_power : "",
  enforce_link : ""
}, Resource.common_inet_parameters)


Resource.inet_type_parameter = {
  e0 : Resource.common_inet_parameters,
  e1 : Resource.common_inet_parameters,
  w0 : Resource.wlan_inet_parameters,
  w1 : Resource.wlan_inet_parameters
}

Resource.resource_properties = {
  net : Resource.inet_type_parameter 
}

Resource.prototype.properties = {
  id: 0,
  group: "",
  application: "",
  properties : Resource.resource_properties
}

function Group(name){
  this.name = name
  this.nodes = {}
  this.ids = []
  this.nid = 0
  this.applications = []
}

Group.prototype.addResource = function(resource) {
  this.nodes[resource.id] = resource
  this.ids.push(resource.id);
  ++this.nid;
}

Group.prototype.addResources = function(resources) {
  for (i = 0; i<resources.length; ++i) {
    this.addResource(resources[i]);
  }
}

Group.prototype.removeResource = function(resource) {
  var id = resource;
  if (resource.id != undefined) {
    id = resource.id;
  }
  if (id in this.nodes){
    delete this.nodes[resource.id];
    this.ids.remove(this.ids.indexOf(resource.id));
  }
}

Group.prototype.removeResources = function(resources) {
  for (i = 0; i<resources.length; ++i) {
    this.removeResource(resources[i]);
  }
}

Group.prototype.getId = function(){
  return this.nid;
}

Group.prototype.getResource = function(id){
  return this.nodes[id];
}

Group.prototype.addApplication = function(application) {
  this.applications.push(application);
}

function Engine() {
  this.groups = { "default" : new Group("default") }
  this.group_keys = ["default"];
  this.resources = {};
  this.reference = {
    keys: [],
    defs: {},
    properties: {},
    measures: {},
  }
  this.properties = { duration : 30 }
  $.getJSON("/eds/doc.json?type=all", function(data){
    this.loadOEDLReference(data);
  }.bind(this));
}

Engine.prototype.setExperimentProperties = function(properties){
  this.properties = properties;
}

Engine.prototype.getExperimentProperties = function(){
  return this.properties;
}

Engine.prototype.addResources = function(groupname, resources){ 
  for (i=0; i<this.group_keys.length; ++i){
    this.groups[this.group_keys[i]].removeResources(resources);
  }
  var group = this.groups[groupname]; 
  group.addResources(resources);
}

Engine.prototype.addResource = function(groupname, resource){  
  return this.groups[groupname].addResource(resource);
}

Engine.prototype.removeGroup = function(name){  
  delete this.groups[name];
  this.group_keys.remove(name);
  return 0;
}

Engine.prototype.addGroup = function(name){
  var g = this.groups[name] 
  this.groups[name] = new Group(name)
  this.group_keys.push(name);
  return 0;
}

Engine.prototype.generateGroupName = function(nodes){
  var gname = "__group_"
  var id;
  for(i=0; i<nodes.length; ++i){
    id = nodes[i].id.replace("node-", "");
    gname = gname + "n"+id+"_";
  }
  return gname;
}

Engine.prototype.findGroups = function(nodes){
  var __groups = new Array();
  var __group;
  for(i=0; i<nodes.length; ++i){
    var node = nodes[i];
    for(var gname in this.groups){
      var g = this.groups[gname];
      if (__groups.indexOf(gname) != -1){
        __groups.push(g)
      }
    }
  }
  return __groups;
}
Engine.prototype.addApplication = function(application, nodes){
  var __groups = this.findGroups(nodes);
  var gname = this.generateGroupName(nodes);
  if (__groups.length == 1) {
    gname = __groups[0];
  } else {
    for(i=0; i<__groups.length; ++i) {
      this.groups[__groups[i]].removeResources(nodes);
      if (__groups[i] != "default"){
        this.removeGroup(__groups[i]);
      }
    }
  }
  this.addGroup(gname);
  this.groups[gname].addResources(nodes)
  this.groups[gname].addApplication(application);
}

Engine.prototype.loadOEDLReference = function(data){
  var tmp = this.reference;
  for(uri in data) {

    tmp.keys.push(uri);
    tmp.properties[uri] = data[uri].properties;
    tmp.measures[uri] = data[uri].measures;
    delete data[uri].properties;
    delete data[uri].measures;
    // only app description remaining
    tmp.defs[uri] = data[uri];
  }
  this.reference = tmp;
}

Engine.prototype.getApplicationDefinition = function(uri, cb){
  $.getJSON("/eds/doc.json?type=app&name="+uri, function(data){
    cb(data);
  }.bind(this));
}


Engine.prototype.getGeneratedCode = function(){
  var engine = this;
  var groups_data = new Array();
  for(var g in engine.groups){
    var group = engine.groups[g];
    var _nodes = new Array();    
    for(var node in group.nodes) {
      _nodes.push(node.replace("node-", ""))
    }
    groups_data.push({ name : g, nodes : _nodes, applications: group.applications  });
  }
  var data =  { meta : { groups : groups_data, properties : engine.properties }};
  $.post("/eds/code.js", data);
}
