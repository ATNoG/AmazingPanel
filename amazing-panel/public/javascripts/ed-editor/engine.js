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
  if (resource.id in this.nodes){
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
  this.properties = {}
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
  $.post("/eds/code.js", { meta : { groups : engine.group_keys, properties : engine.properties }});
}
