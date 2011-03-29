/**
  * Templates
  */
EdEditor.prototype.templates = {
  display_info: $.template("display_info","<div class=\"grid-view-row\">"+
                      "<div><b>${key} </b></div>"+
                      "<div>${value}</div>"+
                    "</div>"),
  display_property: $.template("display_property","<div class=\"grid-view-row\">"+
      "<div>"+
        "<b>${key}</b>"+
      "</div>"+
      "<div>${value}</div>"+
      "<div>"+
        "<input class=\"{{if v}}{{else}}hidden{{/if}}\" name=\"properties[${key}]\" type=\"text\" value=\"{{if v}}${v}{{/if}}\" />"+
        "<input name=\"selected\" class=\"prop-check\" type=\"checkbox\" {{if v}}checked=\"true\"{{/if}} value=\"${key}\"/></div>"+
      "</div>"),
  display_measure : $.template("display_measures","<p>"+
        "<b>${key}<input name=\"selected\" type=\"checkbox\" value=\"${key}\"/></b>"+
        "<ul class=\"list\">{{each(i,m) metrics}} <li>${m.name} : ${m.type}</li>{{/each}} </ul>"+
      "</p>"),
  insert_info: $.template("insert_info","<div class=\"grid-view-row\">"+
      "<div><b>${key} </b></div>"+
      "<div><input name=\"info[${key}]\" type=\"text\"/>${value}</div>"+
    "</div>"),
  insert_property: $.template("insert_property","<div class=\"grid-view-row\">"+      
      "<div>"+
        "<select id=\"property-type\" name=\"property_type\">"+
          "<option value=\"integer\">integer</option>"+
          "<option value=\"string\">string</option>"+
          "<option value=\"boolean\">boolean</option>"+
        "</select>"+
      "</div>"+
      "<div>"+
        "<b><input name=\"property_name\" type=\"text\"/></b>"+
      "</div>"+
      "<div>"+
        "<input name=\"property_description\" type=\"text\"/>  </div>"+
        "<div style=\"width:250px\">"+
          "<input name=\"property_value\" type=\"text\"/>"+
          "<input name=\"has_value\" type=\"checkbox\"/>"+
          "<div id=\"add-application-property-button\"class=\"button inline right\">Add</div>"+
        "</div>"+
      "</div>"),
  inserted_info : $.template("inserted_info", "<input name=\"${key}\" type=\"hidden\" value=\"${value}\" />"),
  inserted_property: $.template("inserted_property","<div class=\"grid-view-row\">"+     
      "{{if type}}"+
      "<div>"+
        "<span>${type}</span>"+
        "<input name=\"properties[${key}][options][type]\" type=\"hidden\" value=\"${type}\" />"+
      "</div>"+
      "{{/if}}"+
      "<div>"+
        "<b>${key}</b>"+
        "<input name=\"properties[${key}][name]\" type=\"hidden\" value=\"${key}\" />"+
      "</div>"+
      "<div>"+
        "<span>${value}</span>"+
        "<input name=\"properties[${key}][description]\" type=\"hidden\" value=\"${value}\" />"+
      "</div>"+
      "<div>"+
        "<input class=\"{{if v}}{{else}}hidden{{/if}}\" name=\"properties[${key}][value]\" type=\"text\" value=\"{{if v}}${v}{{/if}}\" />"+
        "<input name=\"selected\" class=\"prop-check\" type=\"checkbox\" {{if v}}checked=\"true\"{{/if}} value=\"${key}\"/>"+
      "</div>"+
    "</div>"),
  groups: $.template("tmpl_groups", "<div class=\"grid-view-row has-tooltip\" title=\"Selecting a timestamp on the timeline, will let execute a command on this group\">"+
        "<div class=\"sidetable-group-select group-color\" style=\"background-color: ${color}\">"+
          "<input value=\"${name}\" type=\"hidden\"/>"+
        "</div>"+
        "<div>${nodes}</div>"+
      "</div>"),
  apps: $.template("tmpl_apps", "<div class=\"grid-view-row has-tooltip\" title=\"Selecting a timestamp on the timeline, will let execute all applications on this group\">"+
        "<div class=\"sidetable-app-select group-color\" style=\"background-color: ${color}\">"+
          "<input value=\"${group}\" type=\"hidden\"/>"+
        "</div>"+
        "<div>${app}</div>"+
      "</div>")

}
