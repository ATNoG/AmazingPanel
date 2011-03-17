module BranchesHelper
  def transform_map(input_rm)    
    rm = Hash.new()
    input_rm.each do |n, v|      
      rm[n.to_i] = v[:sys_image].to_i unless v.nil? or n.eql?("testbed")
    end
    return rm
  end
end
