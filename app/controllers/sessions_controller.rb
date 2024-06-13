# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def linkedin_auth
    client = OAuth2::Client.new(
      Rails.application.credentials.linkedin[:client_id],
      Rails.application.credentials.linkedin[:client_secret],
      site: 'https://www.linkedin.com',
      authorize_url: '/oauth/v2/authorization',
      token_url: '/oauth/v2/accessToken'
    )

    redirect_uri = 'http://localhost:3000/auth/linkedin/callback'
    
    redirect_to client.auth_code.authorize_url(
      redirect_uri: redirect_uri, 
      scope:  'openid profile email'
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
    puts ">>>>>>>>>>>>>>>>>>>>"
    puts ">>>>>>>>>>>>>>>>>>>>  SessionsController.linkedin_callback :code #{code}"
    puts ">>>>>>>>>>>>>>>>>>>>"
    redirect_uri = 'http://localhost:3000/auth/linkedin/callback'
    token = client.auth_code.get_token(
      code,
      redirect_uri: redirect_uri,
      scope:  'openid profile email',
      client_secret: Rails.application.credentials.linkedin[:client_secret]
    )

    # Almacenar el token de acceso en la sesión
    session[:access_token] = token.token
    redirect_to root_path, notice: 'Conexión exitosa con LinkedIn'
    #redirect_to profile_path
  end

  def profile
    # Obtener el token de acceso desde la sesión
    access_token = session[:access_token]

    if access_token
      client = OAuth2::Client.new(
        Rails.application.credentials.linkedin[:client_id],
        Rails.application.credentials.linkedin[:client_secret],
        site: 'https://www.linkedin.com'
      )

      token = OAuth2::AccessToken.new(client, access_token)
      response = token.get('https://api.linkedin.com/v2/userinfo')
      
      begin
        @user_profile = JSON.parse(response.body)
        puts ">>>>>>>>>>>>>>>>>>>>  SessionsController.profile :user_profile #{@user_profile}"
      rescue OAuth2::Error => e
        if e.response.status == 401 && e.response.parsed['code'] == 'REVOKED_ACCESS_TOKEN'
          flash[:alert] = "Tu sesión ha expirado. Por favor, vuelve a iniciar sesión."
          redirect_to root_path and return
          #redirect_to auth_linkedin_path and return
        else
          flash[:alert] = "Ocurrió un error al intentar obtener tu perfil. Por favor, intenta nuevamente."
          redirect_to root_path and return
        end
      end
    else
      flash[:error] = "No estás autenticado con LinkedIn"
      redirect_to root_path      
    end
  end
end
