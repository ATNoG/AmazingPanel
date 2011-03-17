class BranchesController < ApplicationController
  include BranchesHelper

  load_and_authorize_resource :experiment
  before_filter :set_repository

  def show
    redirect_to @experiment
  end

  def update
  end

  def destroy
  end

  def commit
    branches = @experiment.repository.branches
    branch = branches[params[:id]]
    
    code = params[:code]
    rm = transform_map(params[:experiment][:nodes])
    
    flash[:error] = t("errors.experiment.evc.branch_commit", :branch => branch.name)
    unless branch.blank?
      branch.commit_branch(params[:message], code, rm)
      flash[:success] = t("amazing.experiments.evc.branch_commit", :branch => branch.name)
      flash.delete(:error)
    end  
    redirect_to @experiment
  end

  def clone
    success = @experiment.clone(params[:name], params[:parent])
    branch = params[:name]
    if success
      flash[:success] = t("amazing.experiments.evc.branch_clone", :branch => branch)
    else
      flash[:error] = t("errors.experiment.evc.branch_clone", :branch => branch)
    end
    redirect_to @experiment
  end

  private
  def set_repository
    @experiment.set_user_repository(current_user)
  end
end
