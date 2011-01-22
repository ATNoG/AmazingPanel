function OEDLObject(){
}

OEDLObject.prototype.toRuby = function(){
}

Resource.prototype = new OEDLObject
Resource.prototype.constructor = Node

function Resource(){
  OEDLObject.call(this);
  this.properties = {}
}

Resource.prototype.getProperties = function(){
}

function Group(name, hrn){
  OEDLObject.call(this);
}

Group.prototype.addNode = function(properties) {

}

Group.prototype.toRuby = function() {

}

function EdEditorEngine() {
  this.groups = []
}

EdEditorEngine.prototype.addNode = function(groupname, properties){ 
}

EdEditorEngine.prototype.addGroup = function(name, hrn){
}
