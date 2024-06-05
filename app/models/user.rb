class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:linkedin]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    end
  end
end

# class User < ApplicationRecord
#   def self.from_omniauth(auth)
#     where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
#       user.name = auth.info.name
#       user.oauth_token = auth.credentials.token
#       user.oauth_expires_at = Time.at(auth.credentials.expires_at)
#       user.save!
#     end
#   end
# end
