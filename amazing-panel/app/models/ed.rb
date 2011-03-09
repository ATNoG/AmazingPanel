require 'omf.rb'

class Ed < Resource
  attr_accessor :code
  belongs_to :user

  after_initialize :read_file
  after_find :read_file
  after_create :read_file
  after_update :read_file

  def allowed() 
    nodes = Array.new()
    begin
      p = OMF::Experiments::ScriptHandler.exec(-1, self)
      p.properties[:groups].each do |k,v|
        hrn = v[:selector]
        n = Node.find_by_hrn!(hrn)
        nodes.push(n.id.to_i)    
      end
    rescue
      nodes = nil
    end
    return nodes
  end
  
  private
  def read_file()
    self.code = OMF::Workspace.open_ed(User.find(self.user_id), "#{self.id.to_s}.rb")
  end
end
