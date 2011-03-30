/**
  * JSON Forms
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
        "class" : "clear"
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


