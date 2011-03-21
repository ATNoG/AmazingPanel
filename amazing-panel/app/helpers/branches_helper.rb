module BranchesHelper
  def transform_map(input_rm)    
    rm = Hash.new()
    testbed = input_rm.delete(:testbed)
    input_rm.each do |n, v|
      e =  { 
        'testbed' => testbed, 
        'sys_image' => v[:sys_image].to_i 
      } 
      rm[n.to_i] = e unless v.nil? or n.eql?("testbed")
    end
    return { 'resources' => rm }
  end
end
