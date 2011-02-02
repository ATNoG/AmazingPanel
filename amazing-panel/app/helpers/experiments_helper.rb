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

  def render_for_phase
    phase = session[:phase]
    canonical_name = phase.label.downcase
    render :partial => "experiments/#{canonical_name}"
  end

  def experiment_widget(experiment, nodes)
    status = experiment.status
    l_button = "button giant-button"
    #l_run_class= (experiment.finished? or experiment.prepared? or experiment.not_init?) ? l_button : l_button+" button-disabled"
    l_prepare_class = (!experiment.prepared?) ? l_button : l_button+" button-disabled"
    l_start_class = (experiment.prepared?) ? l_button : l_button+" button-disabled"
    l_stop_class = (experiment.started? or experiment.preparing?) ? l_button : l_button+" button-disabled"
    
    #l_run = content_tag(:div, "Run", :id => "run-experiment-button", :class=>l_run_class)
    l_prepare = content_tag(:div, "Prepare", :id => "prepare-experiment-button", :class=>l_prepare_class)
    l_start = content_tag(:div, "Start", :id => "start-experiment-button", :class=>l_start_class)
    l_stop = content_tag(:div, "Stop", :id => "stop-experiment-button", :class=>l_stop_class)
    error = image_tag('error.png')
    img = image_tag('loading.gif')
    _str_ = 'Loading System Images on nodes...'
    case 
    when experiment.prepared?
      _str_ = 'Starting experiment...'
    when experiment.started?
      _str_ = 'Stopping experiment...'
    end
    text  = content_tag(:span, _str_, :class => "text")
    err_text  = content_tag(:span, "", :class => "text")
    capt_exp  = content_tag(:div, img+text, :id => "caption-experiment")
    err_exp  = content_tag(:div, error+err_text, :id => "error-experiment", :class =>"hidden")
    container = content_tag(:div, l_prepare+l_start+l_stop+capt_exp+err_exp, :id => "experiment-briefing")
    #container = content_tag(:div, l_run+l_stop+capt_exp+err_exp, :id => "experiment-briefing")
    nodes_str = "".html_safe
    nodes.each do |k,v|
       lbl = content_tag(:span, "node-#{k}:", :class => "image-label bold")
       lbls = content_tag(:span, "", :class => "image-status")
       pb = progress_bar()
       cls = clear()
       image_node = content_tag(:div, lbl+pb+lbls+cls, :id => "image-node-#{k}", :class => "image-progress").html_safe
       nodes_str += image_node
    end
    images_loader = content_tag(:div, nodes_str, :id => "images-loading")
    return (container+images_loader).html_safe
  end  
end
