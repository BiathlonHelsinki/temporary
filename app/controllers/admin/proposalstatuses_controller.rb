class Admin::ProposalstatusesController < Admin::BaseController
  skip_load_and_authorize_resource
  load_and_authorize_resource
  
  def create
    @proposalstatus = Proposalstatus.new(proposalstatus_params)
    if @proposalstatus.save
      flash[:notice] = 'Proposalstatus saved.'
      redirect_to admin_proposalstatuses_path
    else
      flash[:error] = "Error saving proposalstatus!"
      render template: 'admin/proposalstatuses/new'
    end
  end
  
  def destroy
    proposalstatus = Proposalstatus.find(params[:id])
    proposalstatus.destroy!
    redirect_to admin_proposalstatuses_path
  end
  
  def edit
    @proposalstatus = Proposalstatus.find(params[:id])
    set_meta_tags title: 'Edit proposal status'
  end
  
  def index
    @proposalstatuses = Proposalstatus.all.order(created_at: :desc)
    set_meta_tags title: 'Proposal statuses'
  end
  
  def new
    @proposalstatus = Proposalstatus.new
  end
  
  def update
    @proposalstatus = Proposalstatus.find(params[:id])
    if @proposalstatus.update_attributes(proposalstatus_params)
      flash[:notice] = 'Proposalstatus details updated.'
      redirect_to admin_proposalstatuses_path
    else
      flash[:error] = 'Error updating proposalstatus'
    end
  end
  protected
  
  def proposalstatus_params
    params.require(:proposalstatus).permit(translations_attributes: [:id, :locale, :name ]
      )
  end
    
end
  