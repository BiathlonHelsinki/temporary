class AccountsController < ApplicationController
  
  before_action :authenticate_user!
  
  def set_as_primary
    @user = User.friendly.find(params[:user_id])
    if @user != current_user
      unless current_user.has_role? :admin
        flash[:error] = "This is not your account" 
        redirect_to edit_user_path(@user) and return
      else
        continue
      end
    end
    @account = @user.accounts.find(params[:id])
    @user.accounts.each do |acc|
      acc.primary_account = false
      acc.save
    end
    @account.primary_account = true
    if @account.save
      flash[:notice] = "Account #{@account.address} set as primary"
      redirect_to edit_user_path(@user)
    else
      flash[:error] = 'Error: ' + @account.errors.inspect
    end
  end
  
end