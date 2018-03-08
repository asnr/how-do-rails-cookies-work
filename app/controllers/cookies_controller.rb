class CookiesController < ApplicationController
  def set_cookies
    cookies[:plain] = 'Some unencrypted value'.freeze
    cookies.signed[:signed] = 'Some signed value'.freeze
    cookies.encrypted[:encrypted] = 'Some encrypted value'.freeze
    render html: "Consider your cookies set.\n".freeze
  end

  def reset_cookies
    delete_all_cookies
    redirect_to '/set-cookies'
  end

  def delete_cookies
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
