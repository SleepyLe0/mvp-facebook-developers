class PagesController < ApplicationController
  # Public — no require_user!. Reviewers must be able to reach these while logged out.
  def privacy; end
  def data_deletion; end
end
