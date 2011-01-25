Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

function Resource(id){
  this.id = id;
}

Resource.prototype.getProperties = function(){
  return this.properties;
}

Resource.merge = function merge(obj1, obj2) {
    for(attr in obj1)
        obj2[attr]=obj1[attr];
    return obj2;
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

Group.prototype.removeResource = function(resource) {
  delete this.nodes[resource.id];
  this.ids.remove(resource.id);
}

Group.prototype.getId = function(){
  return this.nid;
}

function Engine() {
  this.groups = { 
    "default" : new Group("default") 
  }
  this.group_keys = ["default"] 
  this.resources = {}
}


Engine.prototype.addResource = function(groupname, resource){  
  return this.groups[groupname].addResource(resource);
}

Engine.prototype.removeGroup = function(name){  
  delete this.groups[name]
  this.group_keys.remove(name);
  return 0;
}

Engine.prototype.addGroup = function(name){
  var g = this.groups[name] 
  this.groups[name] = new Group(name)
  this.group_keys.push(name);
  return 0;
}
