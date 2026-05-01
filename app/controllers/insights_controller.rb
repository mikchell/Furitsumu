class InsightsController < ApplicationController
  before_action :authenticate_user!

  def show
    @insights = UserInsightsSnapshot.new(current_user)
  end
end
