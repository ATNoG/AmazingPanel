module Library::EdsHelper
  def timeline(tm_params)
    ret = nil
    unless tm_params.blank?
      ret = Array.new()
      tm_params.each do |k,v|
        v[:start] = v[:start].to_i
        v[:stop] = v[:stop].to_i
        ret.push(v)      
      end
    end
    return ret
  end
end
