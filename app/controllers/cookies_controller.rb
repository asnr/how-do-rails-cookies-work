class CookiesController < ApplicationController
  def create
    cookies[:plain] = 'Some unencrypted value'.freeze
    cookies.signed[:signed] = 'Some signed value'.freeze
    cookies.encrypted[:encrypted] = 'Some encrypted value'.freeze
    session[:my_session_id] = 5924
    render html: "Consider your cookies set.\n".freeze
  end

  def reset
    delete_all_cookies
    redirect_to '/set-cookies'
  end

  def destroy
    delete_all_cookies
    render html: "Consider your cookies deleted.\n".freeze
  end

  def show
    @plain_cookie = cookies[:plain]
    @signed_cookie = cookies.signed[:signed]
    @encrypted_cookie = cookies.encrypted[:encrypted]
  end

  private

  def delete_all_cookies
    cookies.delete :plain
    cookies.delete :signed
    cookies.delete :encrypted
  end
end
