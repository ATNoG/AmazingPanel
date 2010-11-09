module Library::ResourceHelper
  def generate_table_headers(base_model, path, options={}, &block)
    filters = options[:filters]
    labels = options[:labels]
    refs = options[:refs]
    fields = options[:fields]
    model = base_model.first.attribute_names
    _missing = nil
    i = fields.index("...")
    if !i.nil?
      _f = fields.slice(0, i)
      _s = fields.slice(i+1, fields.length)
      _missing = model.delete_if {|x| fields.index(x).nil? == false}
      fields = _f.concat(_missing).concat(_s)
    end
    concat("<thead><tr>".html_safe)
    fields.each do |k_attr|
      if k_attr != "__actions"
	  span = content_tag(:span, k_attr.capitalize.html_safe)
	  span = content_tag(:span, labels[k_attr.to_s].html_safe) unless (labels.nil? or labels[k_attr].nil?)
	  f = ""
	  if filters and filters[k_attr]	    
	    value = filters[k_attr].split(/:/)
	    filter = value[0] unless value.nil?
	    value = value[1] unless value.nil?
	    m = self.method(filter+"_filter")
	    f = (modal_filter_dialog(k_attr) do 
	      case filter
	      when "integer_field_select"
		concat(m.call(path, k_attr, base_model.all))
	      when "text_field", "bool_field"
		concat(m.call(path, k_attr))
	      when "string_list_field"
	        _refs = refs[k_attr]
	        if value == "custom"
		  concat(m.call(path, k_attr, base_model.all, _refs[0], _refs[1], _refs[2], &block))
	        else		
		  puts "calling from non-block"
		  concat(m.call(path, k_attr, base_model.all, _refs[0], _refs[1], _refs[2]))		  
	        end
	      end
	    end)
	  end	  	  
	  th = content_tag(:th, span+f)	  
      else      
	 th = content_tag(:th, span)
      end
      concat(th.html_safe)
    end          
    concat("</thead></tr>".html_safe)
    return
  end
  
  def active_filters(path)
    concat("<ul class=\"filter\">".html_safe)
    @filters.each do |k, f|	     
      field = content_tag(:span, f[:field] + " ", :class => "filter-name")
      op = content_tag(:span, op_conv(f[:op])  + " ", :class => "filter-op")
      value = content_tag(:span, f[:value] + " ", :class => "filter-value")
      l_remove = content_tag(:div, link_to("Remove", clear_filter_path(path, k.to_s), :id => "remove-filter"), :class=>"button")
      concat(content_tag(:li, field+op+value+l_remove, :class=>"option").html_safe)
    end  
    concat("</ul>".html_safe);	  
    return
  end
  
  def modal_dialog(title, id, &block)            
    title_box = content_tag(:div, title.html_safe, :class=>"title-box")    
    close_button = content_tag(:div, "Close", :class=>"button", :onclick => "$('#"+id+"').removeClass('dialog-active')");
    actions = content_tag(:div, close_button, :class=>"modal-actions")
    content = with_output_buffer(&block)
    container = content_tag(:div, content, :class=>"modal-container")    
    modal = content_tag(:div, title_box+container+actions, :class=>"modal", :id => id)
    return modal
  end

  
  def modal_filter_dialog(field, &block)            
    f_title = "Filter by: " + content_tag(:span, field, :class=>"column")
    title_box = content_tag(:div, f_title.html_safe, :class=>"title-box")    
    close_button = content_tag(:div, "Close", :class=>"button", :onclick => "$('#"+field+"-filter').removeClass('dialog-active')");
    actions = content_tag(:div, close_button, :class=>"modal-actions")
    content = with_output_buffer(&block)
    container = content_tag(:div, content, :class=>"modal-container")    
    modal = content_tag(:div, title_box+container+actions, :class=>"modal", :id => field+"-filter")
    return ("<a class=\"filter-link\" href=\"#\" onclick=\"$('.filter-link + #"+field+"-filter').addClass('dialog-active')\"><img src=\"/images/right.gif\"/></a>" + modal).html_safe
  end

  def field_filter(&block)
    concat("<ul class=\"filter\">".html_safe)
    block.call(d)
    concat("</ul>".html_safe)    
    return 
  end
  
  def list_field_filter(field_name, data, &block)
    concat("<ul class=\"filter\">".html_safe)
    data.each do |d|      
      concat("<li class=\"option\">".html_safe)
      block.call(d)
      concat("</li>".html_safe)
    end
    concat("</ul>".html_safe)    
    return 
  end

  def string_list_field_filter(path, field_name, data, v_child_model=nil, v_child_model_attr="", op="eq", &block)
    concat("<ul class=\"filter\">".html_safe)
    list = Array.new()
    data.each do |d|      
      _v = d.read_attribute(field_name)
      
      if v_child_model.nil? == false
	if ((list.index(_v).nil?) && (_v.nil? ==false))
	  _v_child_unique = v_child_model.find(_v)
	  if v_child_model_attr.nil? == false
	    _v_child_value = _v_child_unique.read_attribute(v_child_model_attr)
	  end
	  concat("<li class=\"option\">".html_safe)
	  if block_given?
	    _v_child_unique["field_filter"] = field_name
	    block.call(_v_child_unique)
	  else
	    concat(link_to _v_child_value, filter_path(path, field_name, op, _v.to_s))
	  end
	  concat("</li>".html_safe)
	  list.push(_v)
	end
      else
	  if (list.index(_v).nil?)
	    concat("<li class=\"option\">".html_safe)
	    concat(link_to( _v, filter_path(path, field_name, op, _v.to_s).html_safe, :class => "option").html_safe)
	    concat("</li>".html_safe)
	    list.push(_v)
	  end
      end
    end
    concat("</ul>".html_safe)    
    return 
  end

  def bool_field_filter(path, field_name)    
    l_d = link_to((image_tag("disable.png", {:height => 16, :width => 16}) + " Deactivated").html_safe, filter_path(path, field_name, "eq", 0.to_s))
    l_a = link_to((image_tag("enable.png", {:height => 16, :width => 16}) + " Activated").html_safe, filter_path(path, field_name, "eq", 1.to_s))
    li_d = content_tag(:li, l_d, :class => "option")
    li_a = content_tag(:li, l_a, :class => "option")
    ul = content_tag(:ul, li_d+li_a, :class => "filter")   
    return ul.html_safe
  end
  
  def integer_field_select_filter(path, field_name, data)
    s_op = select_tag(:op, options_for_select([['>=', 'ge'], ['=', 'eq'], ['<=', 'le'], ['<', 'l'], ['>', 'g']]), :onchange => "setIntegerComparatorFilterExpression('"+path+"', '"+field_name+"')" )
    values = Array.new
    data.each do |v|
      _v = v.read_attribute(field_name)
      values.push([_v.to_s, _v.to_s])
    end
    s_value = select_tag(:value, options_for_select(values), :onchange => "setIntegerComparatorFilterExpression('"+path+"', '"+field_name+"')" )
    c = content_tag(:div, link_to("Apply", filter_path(path, field_name, "ge", values[0][0]), :id => "apply-filter"), :class=>"button")
    li = content_tag(:li, s_op+s_value+c, :class => "option")
    ul = content_tag(:ul, li, :class => "filter")   
    return ul.html_safe
  end
  
  def text_field_filter(path, field_name)
    s = select_tag(:op, options_for_select([['>=', 'ge'], ['=', 'eq'], ['<=', 'le'], ['<', 'l'], ['>', 'g']]), :onchange => "setStringComparatorFilterExpression('"+path+"', '"+field_name+"')")
    t = text_field_tag(:value, '', :onchange => "setStringComparatorFilterExpression('"+path+"', '"+field_name+"')",  :length => 10)
    c = content_tag(:div, link_to("Apply", filter_path(path, field_name, "ge", ""), :id => "apply-filter"), :class => "button")
    li = content_tag(:li, s+t+c, :class => "option")
    ul = content_tag(:ul, li, :class => "filter")   
    return ul.html_safe
  end
  
  def filter_path(root_path, field, cmp, value)
    return root_path+"?filter=field&field="+field+"&op="+cmp+"&value="+value
  end
  
  def clear_filter_path(root_path, id)
    return root_path+"?filter=clear&value="+id;
  end
  
  def op_conv(cmp, inv=true)
    op_map = {
      "ge" => ">=",
      "eq" => "=",
      "le" => "<=",
      "l" => "<",
      "g" => ">",
      "like" => "="
    }
    if inv == false
      return op_map.index(cmp)
    end
    return op_map[cmp]    
  end
  
  def table_header(title, &block)
    if title=="#"
      concat("<th class=\"actions-1\"".html_safe)
    else
      concat("<th>".html_safe)
    end
    
    concat(("<span>"+title+"</span>").html_safe)
    if block_given?
      concat(with_output_buffer(&block).html_safe)
    end
    concat("</th>".html_safe)
    return
  end
end
