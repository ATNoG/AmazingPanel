class User < Resource
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  validates :username, :uniqueness => true
  attr_accessor :roles
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :username, :intention, :password, :password_confirmation, :remember_me, 
                  :activated, :name, :institution, :roles
  
  ROLES = %w[admin experimenter moderator]

  def roles=(roles)
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
  end

  def roles
    ROLES.reject do |r|
      ((roles_mask || 0) & 2**ROLES.index(r)).zero?
    end
  end

  def is?(role)
    roles.include?(role.to_s)
  end
end
