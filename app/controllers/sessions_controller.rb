 # app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def linkedin_auth
    puts "::::::::::  SessionsController.linkedin_auth :client_id #{:client_id}"
    client = OAuth2::Client.new(
      Rails.application.credentials.linkedin[:client_id],
      Rails.application.credentials.linkedin[:client_secret],
      site: 'https://www.linkedin.com',
      authorize_url: '/oauth/v2/authorization',
      token_url: '/oauth/v2/accessToken'
    )

    redirect_uri = 'http://localhost:3000/auth/linkedin/callback' # Asegúrate de que esta URL coincida con la registrada en LinkedIn
    
    redirect_to client.auth_code.authorize_url(
      redirect_uri: redirect_uri, 
      scope: 'w_member_social'
     ), allow_other_host: true 
  end

  def linkedin_callback
    if params[:error]
      flash[:error] = params[:error_description]
      redirect_to root_path and return
    end

    client = OAuth2::Client.new(
      Rails.application.credentials.linkedin[:client_id],
      Rails.application.credentials.linkedin[:client_secret],
      site: 'https://www.linkedin.com',
      authorize_url: '/oauth/v2/authorization',
      token_url: '/oauth/v2/accessToken'
    )

    code = params[:code]
    redirect_uri = 'http://localhost:3000/auth/linkedin/callback' # Definir redirect_uri
    token = client.auth_code.get_token(code, redirect_uri: redirect_uri, client_secret: Rails.application.credentials.linkedin[:client_secret])

    # Utiliza el token de acceso para hacer solicitudes a la API de LinkedIn
    # ej: obtener el perfil del usuario
    # response = token.get('https://api.linkedin.com/v2/me')
    response = token.get('https://api.linkedin.com/v2/userinfo')
    user_profile = JSON.parse(response.body)
    
    render json: user_profile
        
    # Aquí puedes manejar la autenticación y almacenar la información del usuario
    #user = User.find_or_create_by(uid: user_profile['id'], provider: 'linkedin') do |u|
    #  u.name = user_profile['localizedFirstName'] + ' ' + user_profile['localizedLastName']
    #  u.oauth_token = token.token
    #  u.oauth_expires_at = token.expires_at
    #end

    #session[:user_id] = user.id
    #redirect_to root_path, notice: 'Conexión exitosa con LinkedIn'
  end
end
