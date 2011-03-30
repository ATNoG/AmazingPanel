/**
  * IDE Constructor
  * @constructor
  */
function EdEditor() {
  var canvas = $('.canvas');
  this.engine = new Engine($('.oedl-timeline').width());
  /*this.graph = new Graph(".canvas")*/
  this.last_id = -1;
}

/**
  * Tabs for Application Dialog
  */
EdEditor.prototype.html = {
  tabs: {
    application:
      '<ul id=\"modal-tabs\" class=\"tabs\">'+
       '<li class=\"tab-active\"><a href=\"#content-application\">Information</a></li>'+
        '<li><a href=\"#content-properties\">Properties</a></li>'+
        '<li><a href=\"#content-measures\">Measures</a></li>'+
      '</ul>'+
      '<div id=\"content-application\" class=\"modal-tab tab\">'+
      '</div>'+
      '<div id=\"content-properties\" class=\"modal-tab tab\">'+
        '<form id=\"select-properties\" name=\"properties\"></form>'+
      '</div>'+
      '<div id=\"content-measures\" class=\"modal-tab tab\">'+
        '<form id=\"select-measures\" name=\"measures\"></form>'+
      '</div>'
  }
};

EdEditor.prototype.messages = {
  topbar_info: "<p id=\"topbar-info\" class=\"info no-icon\">Click on the colors to select the group/application</p>",
  toppar_show_info: "<p id=\"show-info\" class=\"info no-icon\">Click on \"Show\" to see your groups/applications</p>",
  nodes_info: "<p id=\"nodes-info\" class=\"info no-icon\">Click on the nodes to see the available options </p>"
}

/**
  * Options to show, in according to the various Node click conditions.
   -> When nodes selected are a group, when multiple nodes without group,
   -> When one node selected are only one,
   -> When multiple nodes are selected
  */
EdEditor.prototype.nodes_selected = {
  single:
    '<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>'+
    '<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>',
  multiple:
    '<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>'+
    '<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>',
//    "",
  group:
    '<div id=\"btn_properties\" class=\"oedl-action-button button\">Properties</div>'+
    '<div id=\"btn_application\" class=\"oedl-action-button button\">Application</div>',
  none:
    '<p id=\"topbar-show-info\" class=\"info no-icon\"> Click on \"Show\" to see your groups/applications</p>'+
    '<p id=\"show-info\" class=\"info no-icon\"> Click on the nodes to see the available options</p>',
};

/**
  * Displayable Resource Properties fields
  */
EdEditor.prototype.resource_fields = [
  'ip',
  'netmask',
  'mtu',
  'mode',
  'type',
  'essid',
  'channel'
];

/**
  * Create group
  */
EdEditor.prototype.addGroup = function(name) {
  this.engine.addGroup(name);
};

/**
  * Add nodes to Group
  */
EdEditor.prototype.addNodesToGroup = function(group, nodes) {
  this.engine.addResources(group, nodes);
};

/**
  * Converts the Applications loaded in engine to an HashTable
  * - used: options in Application Dialog to create form
  */
EdEditor.prototype.getApplicationsFromReference = function(reference) {
  var apps = {}, keys = reference.keys;
  for (i = 0; i < keys.length; ++i) {
    var uri = keys[i], name = reference.defs[uri].name;
    apps[uri] = name;
  }
  return apps;
};

/**
  * Displays "Select Application" Dialog
  */
EdEditor.prototype.selectApplication = function(t) {
  var app_selections = this.getApplicationsFromReference(this.engine.reference), prop_selections = {};
  this.forms.select_application.elements[0].elements[0].options = app_selections;
  var modal = createDialog('Select an application for Node');
  // Positioning and size
  modal.css('height', '500px').css('width', '650px').css('left', '30%').css('top', '20%');

  $('.modal-container', modal).prepend('<form id=\"select-application\"></form>');
  $('.modal-container', modal).css('height', '463px').append(this.html.tabs.application);
  $('#select-application').buildForm(this.forms.select_application);
  $('select#app-name').change(this.onApplicationChange.bind(this));
  modal.addClass('dialog-active');
  $('#modal-tabs > li:eq(0)').click();
  $('#add-application-button').unbind('click').click(this.onApplicationCreate.bind(this));
  $('.modal > .check-button').unbind('click').click(this.onApplicationAdd.bind(this));
  modal.show();
  $('select#app-name').trigger('change');
};

/**
  * Displays "Select Group" Dialog
  */
EdEditor.prototype.selectGroup = function(t) {
  var engine = this.engine,
    modal = createDialog('Select a Group for the node'),
    i = 0, total = engine.group_keys.length, groups = [],
    groups_tmpl = $.template('tmpl_groups', '<li class=\"group\"><div class=\"group-color\" style=\"background-color: ${color}\"></div> ${name}</li>');
  for (i = engine.group_keys.length; i > 0; --i) {
    groups.push({'color' : engine.group_colors[i - 1], 'name' : engine.group_keys[i - 1]});
  }
  var container = $('.modal-container', modal).html('<form id=\"add-group\"></form>'+
                                '<div class=\"clear\"></div>'+
                                '<ul id=\"groups\"></ul>');
  $.tmpl('tmpl_groups', groups).appendTo('#groups');
  $('#add-group').buildForm(this.forms.select_group);
  modal.addClass('dialog-active');
  modal.show();
};

/**
  * Displays 'Properties" Dialog
  */
EdEditor.prototype.selectProperties = function(t) {
  var engine = this.engine, modal = createDialog('Select Properties for Node:');
  var container = $('.modal-container', modal).html('<form id=\"inet-select\"></form><form id=\"res-properties\"></form>');
  var node = $('.node-selected');
  var form = this.generateResourceProperties(node, null);
  $('#inet-select').buildForm(this.forms.select_inet);
  $('select#inet-choose').unbind('change').change(this.onInetChange.bind(this));
  $('#res-properties').buildForm(form);
  $('.modal > .check-button').unbind('click').click(this.onResourceSetProperties.bind(this));
  modal.addClass('dialog-active');
  modal.show();
  
  //$.uniformize("#res-properties");
};

/**
  * Displays "Preferences" Dialog
  */
EdEditor.prototype.loadPreferences = function(t) {
  var modal = createDialog('Experiment Preferences').css('width', '400px').css('left', '30%');

  var container = $('.modal-container', modal).html('<form id=\"exp-properties\" class=\"attr-choose\"></form>');
  $('#exp-properties').buildForm(this.forms.select_exp_properties);
  //$.uniformize("#exp-properties");
  modal.addClass('dialog-active');
  $('.modal > .check-button').unbind('click').click(function(evt) {
    var params = $('#exp-properties').formParams();
    var t_id = $('#testbed_id').attr('value');
    var t_name = $('#testbed_name').attr('value');
    params.exp['testbed'] = { id: t_id, name: t_name };
    this.engine.setExperimentProperties(params.exp);
    closeDialog('#modal-dialog');
    this.generateTimeline();    
  }.bind(this));
  modal.show();
};

/**
  * Displays notification on Design Tab
  */
EdEditor.prototype.showNotification = function(text) {
  var notification = '<p class=\"info\">'+ text + '</p>';
  $('#design').prepend(notification).slideDown().delay(5000).slideUp();
};

/**
  * Displays the add event in the applications table
  */
EdEditor.prototype.showAddEvent = function(evt) {
  var engine = this.engine, modal = createDialog('Event');
  var container = $('.modal-container', modal).html('<form id=\"application-add-event\"></form>');
  $('#application-add-event').buildForm(this.forms._event);
  $('.modal > .check-button').unbind('click').click(this.onApplicationAddEvent.bind(this));
  modal.show();
  //$.uniformize("#application-add-event");
};
