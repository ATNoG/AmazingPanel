module OMF::Experiments::OEDL::GeneratorValidations
  class UnknownPropertyType < RuntimeError
    attr :type
    def initialize(t)
      @type = t
    end
  end

  class InvalidVersionFormat < RuntimeError
    attr :version
    def initialize(v)
      @version = v.to_s
    end
  end

  def valid_group(group)
    if group[:name].blank? or group[:nodes].blank?
      return false
    end

    return true
  end
end
