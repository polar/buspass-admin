class CustomersController < ApplicationController
  layout "main-layout"
  helper_method :sort_column, :sort_direction

  def index
    @roles = Customer::ROLE_SYMBOLS
    @customers = Customer.search(params[:search]).order(sort_column => sort_direction).paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @customers }
      format.js # render index.js.erb
    end
  end

  def show
    @customer = Customer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @customer }
    end
  end

  def new
    @customer = Customer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @customer }
    end
  end

  def edit
    @customer = Customer.find(params[:id])
  end

  def create
    @customer = Customer.new(params[:customer])

    respond_to do |format|
      if @customer.save
        format.html { redirect_to @customer, notice: 'Customer was successfully created.' }
        format.json { render json: @customer, status: :created, location: @customer }
      else
        format.html { render action: "new" }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @roles = Customer::ROLE_SYMBOLS
    @customer = Customer.find(params[:id])

    if current_customer == @customer
      # We don't want you to alter your own roles.
      params[:customer][:role_symbols] = @customer.role_symbols
    end

    respond_to do |format|
      if @customer.update_attributes(params[:customer])
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.json { head :no_content }
        format.js # update.js.erb
      else
        format.html { render action: "edit" }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
        format.js # update.js.erb
      end
    end
  end

  def destroy
    @customer = Customer.find(params[:id])
    @customer.destroy

    respond_to do |format|
      format.html { redirect_to customers_url }
      format.json { head :no_content }
      format.js # destroy.htm.erb
    end
  end

  private

  def sort_column
    Customer.keys.keys.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    [1, -1].include?(params[:direction].to_i) ? params[:direction].to_i : -1
  end
end
