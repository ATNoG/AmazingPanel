module ExperimentsHelper
  def phase_sequence_widget
    phases = Phase.order("number ASC")
    last = phases.last.number
    phases_container = ""
    current_phase = session
    phases.each do |p|
      _ph_number = p.number
      _ph = phase(p)
      phases_container +=  _ph
    end
    return content_tag(:div, phases_container.html_safe, :id => "phases")
  end

  def phase(p)
    current_phase  = session[:phase]
    is_current_phase = (current_phase.number == p.number)
    _ph_div = content_tag(:div, p.label, 
                          :class => "phase "+(is_current_phase ? "phase-active" : ""))
    _ph_a = ""
    if p.number != Phase.last.number
      _ph_a = link_to("", new_experiment_path, 
                      :class => (is_current_phase ? "arrow arrow-active" : "arrow-right"))
    end
    return (_ph_div + _ph_a).html_safe
  end

  def current_phase
    return session[:phase].number.to_i
  end

  def render_for_phase(phase, object)    
    canonical_name = phase
    render :partial => "experiments/e_#{canonical_name}", :locals => { :f => object }
  end

  def showStatus(experiment)
    estatus = session['estatus']
    if estatus.nil?
      estatus = "null"
    end
    status = experiment.status    
    session['estatus'] = status
    "showStatus(#{status}, #{estatus}, options);"    
  end

  def experiment_widget(experiment)
    status = experiment.status
    l_button = "button giant-button"
    #l_run_class= (experiment.finished? or experiment.prepared? or experiment.not_init?) ? l_button : l_button+" button-disabled"
    l_prepare_class = (!experiment.prepared? and !experiment.preparing? ) ? l_button : l_button+" button-disabled"
    l_start_class = (experiment.prepared? and !experiment.started?) ? l_button : l_button+" button-disabled"
    l_stop_class = (experiment.started? or experiment.preparing?) ? l_button : l_button+" button-disabled"
    
    #l_run = content_tag(:div, "Run", :id => "run-experiment-button", :class=>l_run_class)
    l_prepare = content_tag(:div, "Prepare", :id => "prepare-experiment-button", :class=>l_prepare_class)
    l_start = content_tag(:div, "Start", :id => "start-experiment-button", :class=>l_start_class)
    l_stop = content_tag(:div, "Stop", :id => "stop-experiment-button", :class=>l_stop_class)
    error = image_tag('error.png')
    img = image_tag('loading.gif')
    _str_ = 'Loading System Images on nodes...'    
    __started_class = " "
    case 
    when experiment.started?
      _str_ = ''
      __started_class = " hidden"    
    when experiment.prepared?
      _str_ = 'Preparing experiment...'
    end
    text  = content_tag(:span, _str_, :class => "text")
    err_text  = content_tag(:span, "", :class => "text")
    container = content_tag(:div, l_prepare+l_start+l_stop, :id => "experiment-briefing")
    images_loader = content_tag(:div, "", :id => "images-loading");
    return (container+images_loader).html_safe
  end  

  def pane_link(resource, name, image=nil, desc=nil)
    options = { 
      :id => "edit-#{resource}-action", 
      :class => "pane-tab"
    }
    
    return link_to("##{resource}", options) do
      ret = image_tag(image, :width => 16, :height => 16) unless image.blank?
      ret + name
    end
  end

  def ed_pane_link
    pane_link("ed", "Definition", 'edit.png')
  end

  def rm_pane_link
    pane_link("rm", "Map", 'rm_edit.png')
  end
  
  def commit_branch_image_link
    pane_link("commit-branch-action", "Commit Branch", 'commit_branch.png', "Commit the current alterations on selected branch")
  end
  
  def commit_branch_image_link(branch="master")
    options = {
      :id => "commit-branch-action",
      "original-title" => "Save current alterations, on selected branch"
    }
    #return  link_to(commit_experiment_branch_path(:experiment_id => @experiment.id, :id => "master"), options) do
    return  link_to("#", options) do
      image_tag('save.png', :width => 16, :height => 16)
    end
  end
  
  def new_branch_image_link(branch="master")    
    return content_tag(:div, :id=>"new-branch-block") do 
      text_field_tag(:name, nil, :class => "left", :id=>"branch_name_input") + 
        link_to("#", { "original-title" => "Create a new branch from the selected at the right",
                       :id => "new-branch-action" }) do        
          image_tag('new_branch.png', :width => 16, :height => 16)                  
        end
      end
  end
  
  def change_branch_image_link(branch="master")
    options = {
      :id => "change-branch-action",
      :class => "omnip-image-action",      
      "original-title" => "Change the working branch"
    }
    return  link_to(change_experiment_branch_path(:experiment_id => @experiment.id, :id => "master"), options) do
      image_tag('branch.png', :width => 16, :height => 16)
    end
  end
end
