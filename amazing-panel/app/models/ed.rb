require 'omf.rb'

class EdValidator < ActiveModel::Validator
  def validate(record)
      begin
        OMF::Experiments::ScriptHandler.exec_raw(record.code);
      rescue Exception => ex
        Rails.logger.debug "Syntax error => #{ex.class}"
        stx_error = ex.message.split(":")
        record.errors[:ed] << " - "+stx_error[2]
      end
  end
end

class Ed < Resource
  attr_accessor :code
  belongs_to :user
  validates_with EdValidator 

  #after_initialize :read_file
  after_find :read_file
  #after_create :read_file
  after_update :read_file

  def self.available()
    return Node.all.collect{ |n| n.id.to_i }
  end

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
    self.code = OMF::Workspace.open_ed(User.find(self.user_id), "#{self.id.to_s}.rb") unless self.user.blank?
  end
end
