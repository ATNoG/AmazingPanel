module Jobs
  class Job
    attr_accessor :id, :type
    def initialize(type,id)
      @id = id
      @type = type
    end
  end
end
