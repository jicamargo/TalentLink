require 'jwt'

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  rescue_from OAuth2::Error, with: :handle_oauth_error
  
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
      scope:  'openid profile email w_member_social r_member_social'
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
    redirect_uri = 'http://localhost:3000/auth/linkedin/callback'
    token = client.auth_code.get_token(
      code,
      redirect_uri: redirect_uri,
      scope:  'openid profile email',
      client_secret: Rails.application.credentials.linkedin[:client_secret]
    )

    # Almacenar el token de acceso en la sesión
    session[:access_token] = token.token

    # Decodificar el ID Token para obtener el ID del usuario
    id_token = token.params['id_token']
    #decoded_token = JWT.decode(id_token, nil, false) # No verificamos la firma aquí por simplicidad
    #linkedin_user_id = decoded_token[0]['sub']
    
    # Almacenar el ID del usuario en la sesión
    #session[:linkedin_user_id] = linkedin_user_id
    #puts ">>>>>>>>>>>>>>>>>>>> encontre el id del usuario #{linkedin_user_id}"

    #redirect_to root_path, notice: 'Conexión exitosa con LinkedIn'
    redirect_to profile_path, notice: 'Conexión exitosa con LinkedIn'
  end

  def profile
    # Obtener el token de acceso desde la sesión
    access_token = session[:access_token]

    if access_token
      client = initialize_linkedin_client

      begin
        token = OAuth2::AccessToken.new(client, access_token)
        response = token.get('https://api.linkedin.com/v2/userinfo')      
        @user_profile = JSON.parse(response.body)
        session[:linkedin_user_id] = @user_profile['sub']
      rescue OAuth2::Error => e
        handle_oauth_error(e)
      end
    else
      flash[:error] = "No estás autenticado con LinkedIn"
      redirect_to root_path      
    end
  end

  # Acción para obtener los posts del usuario
  def get_user_posts
    access_token = session[:access_token]
    linkedin_user_id = session[:linkedin_user_id]
    
    puts "=============== entrando a get_user_posts 1"
    if access_token && linkedin_user_id
      client = initialize_linkedin_client
      puts "=============== entrando a get_user_posts 2 linkedin_user_id #{linkedin_user_id}"
    
      begin
        puts "=============== entrando a get_user_posts 3"
        #token = OAuth2::AccessToken.new(client, access_token, scope: 'openid profile email w_member_social')
        #response = token.get("https://api.linkedin.com/v2/ugcPosts?q=authors&authors=List(urn:li:person:#{linkedin_user_id})", headers: { 'X-Restli-Protocol-Version': '2.0.0' })
        #response = token.get("https://api.linkedin.com/v2/ugcPosts?authors=List(#{linkedin_user_id})")

        token = OAuth2::AccessToken.new(client, access_token)
        encoded_urn = ERB::Util.url_encode("urn:li:person:#{linkedin_user_id}")
        #url = "https://api.linkedin.com/rest/posts?q=author&author=#{encoded_urn}&count=10&sortBy=LAST_MODIFIED"
        url = "https://api.linkedin.com/rest/posts?author=#{encoded_urn}&q=author&count=10&sortBy=LAST_MODIFIED"
        puts ">>>>>>>>>>>>>>>>>>>> URL: #{url}"
        response = token.get(url, headers: { 'LinkedIn-Version': '202401', 'X-Restli-Protocol-Version': '2.0.0' })

        puts "=============== entrando a get_user_posts 4 response #{response}"
        if response.status == 200
          @user_posts = JSON.parse(response.body)
          puts "%%%%%%%%%%%%%%%%%%%%%%%%%"
          puts "%%%%%%%%%%%%%%%%%%%%%%%%%  SessionsController.get_user_posts :user_posts #{@user_posts}"
          puts "%%%%%%%%%%%%%%%%%%%%%%%%%"
        else
          flash[:alert] = "Error al obtener los posts de LinkedIn. Por favor, inténtalo nuevamente."
        end
      rescue OAuth2::Error => e
        handle_oauth_error(e)
      end
    else
      flash[:error] = "No estás autenticado con LinkedIn"
    end

    redirect_to profile_path
  end

  # Acción para obtener las estadísticas de un post
  def get_post_analytics
    access_token = session[:access_token]
    post_urn = params[:post_urn] # Se debe enviar el URN del post como parámetro desde la vista

    if access_token
      client = initialize_linkedin_client

      begin
        token = OAuth2::AccessToken.new(client, access_token)
        response = token.get("https://api.linkedin.com/v2/ugcPosts/#{post_urn}/analytics", headers: { 'X-Restli-Protocol-Version': '2.0.0' })

        if response.status == 200
          @post_analytics = JSON.parse(response.body)
        else
          flash[:alert] = "Error al obtener las estadísticas del post de LinkedIn. Por favor, inténtalo nuevamente."
        end
      rescue OAuth2::Error => e
        handle_oauth_error(e)
      end
    else
      flash[:error] = "No estás autenticado con LinkedIn"
    end

    redirect_to root_path
  end

  private

  # Método para inicializar el cliente de LinkedIn OAuth2
  def initialize_linkedin_client
    OAuth2::Client.new(
      Rails.application.credentials.linkedin[:client_id],
      Rails.application.credentials.linkedin[:client_secret],
      site: 'https://api.linkedin.com'
    )
  end

  def handle_oauth_error(exception = nil)
    if exception.present? && exception.response.present?
      case exception.response.status
      when 401
        if exception.response.parsed['code'] == 'REVOKED_ACCESS_TOKEN'
          flash[:alert] = "Tu sesión ha expirado o fue revocada. Por favor, vuelve a iniciar sesión."
        else
          flash[:alert] = "Error de autenticación con LinkedIn. Por favor, intenta nuevamente."
        end
      else
        # muestra todo el mensaje de error
        flash[:alert] = exception.message
        # flash[:alert] = "Ocurrió un error al intentar obtener tu perfil. Por favor, intenta nuevamente."
      end
    else
      # muestra todo el mensaje de error
      flash[:alert] = exception.message
      #flash[:alert] = "Ocurrió un error al intentar obtener tu perfil. Por favor, intenta nuevamente."
    end

    #redirect_to root_path
  end  
end