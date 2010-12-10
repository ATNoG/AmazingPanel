prawn_document() do |pdf|
  pdf.text "Experiment ##{@experiment.id}", :size => 30, :style => :bold
end
