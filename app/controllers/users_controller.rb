class UsersController < ApplicationController
  skip_before_action :require_sign_in, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Auto-sign-in the user unless the user is already signed in
      # (eg. creating an account for someone else)
      session[:user_id] = @user.id unless current_user

      redirect_to root_url, :notice => "Signed up!"
    else
      render "new"
    end
  end

  def scorecard
    users = User.order(:group_id, :name).includes(:songs)
    group_user_ids = current_user.group_id.nil? ? [current_user.id] : User.where(group_id: current_user.group_id).pluck(:id)

    @song_count = current_competition.songs.where.not(user_id: group_user_ids).count

    @groups = []
    groups_tmp = {} # temporary variable to make it easier to add people to groups
    users.each do |user|
      if user.group_id.nil?
        @groups << { users: [user], attempts: user.attempts.where(competition_id:current_competition.id) }
      else
        group = groups_tmp[user.group_id]
        if group.nil?
          group = { users: [], attempts: user.group_attempts.where(competition_id:current_competition.id) }
          @groups << group
          groups_tmp[user.group_id] = group
        end
        group[:users] << user
      end
    end
  end

  private

  def user_params
    params.require(:user)
      .permit(
        :name,
        :email,
        :password,
        :password_confirmation
      )
  end
end
