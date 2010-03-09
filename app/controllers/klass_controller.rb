class KlassController < ApplicationController
  unloadable

  before_filter :find_node, :only => [:list,:create]
  before_filter :find_klass, :only => [:configure,:destroy,:move]
  before_filter :authorize
 
  layout 'nested' 
  helper :initr
  menu_item :initr
  
  def list
    node_klasses = Initr::KlassDefinition.all_for_node(@node).sort
    @klass_definitions = []
    Initr::KlassDefinition.all.each do |kd|
      unless node_klasses.include?(kd) and kd.unique?
        @klass_definitions << kd
      end
      @klass_definitions.sort!
    end
    @facts = @node.puppet_host.get_facts_hash rescue []
    @external_nodes_yaml = YAML.dump @node.parameters
    if @node.puppet_host
      @exported_resources = @node.exported_resources 
    else
      @exported_resources = []
    end
  end
 
  def create
    begin
      # try old naming of plugin models,
      # until we migrate all them to initr namespace
      klass = Kernel.const_get("Initr#{params[:klass_name].camelize}").new({:node_id=>@node.id})
    rescue NameError
      klass = Kernel.eval("Initr::"+params[:klass_name].camelize).new({:node_id=>@node.id})
    end

    # if plugin controller implements "new" method, redirect_to it
    if (eval("#{klass.controller.camelize}Controller")).action_methods.include? "new"
      redirect_to :controller => klass.controller, :action => 'new', :id => @node
    else
      if klass.save
        if klass.controller == 'klass'
          redirect_to :action => 'list', :id => @node.id
        else
          redirect_to :controller => klass.controller, :action => 'configure', :id => klass.id
        end
      else
        flash[:error] = "Error adding class: #{klass.errors.full_messages}"
        redirect_to :back
      end
    end
  end

  def configure
    #TODO
  end

  def move
    unless @klass.movable?
      flash[:error] = "This klass can't be moved"
      redirect_to :action => 'list', :id => @node.id
      return
    end
    @nodes = User.current.projects.collect {|p| p.nodes }.compact.flatten.sort
    if request.post?
      unless @nodes.collect {|n| n.id.to_s }.include? params[:klass][:node_id]
        flash[:error] = "Invalid destination node"
        render :action => 'move'
        return
      end
      @klass.node_id = params[:klass][:node_id]
      if @klass.save
        flash[:notice] = "Klass moved"
        redirect_to :action => 'list', :id => params[:klass][:node_id]
      else
        render :action => 'move'
      end
    end
  end

  def destroy
    k = Initr::Klass.find params[:id]
    k.destroy
    flash[:notice] = "Klass deleted"
    redirect_to :action => 'list', :id => @node
  end
    
  private
  
  def find_klass
    @klass = Initr::Klass.find params[:id]
    @node = @klass.node
    @project = @node.project
  end
  
  def find_node
    @node = Initr::Node.find params[:id]
    @project = @node.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
