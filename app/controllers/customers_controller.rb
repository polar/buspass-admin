class CustomersController < ApplicationController
  layout "empty"

  helper_method :sort_column, :sort_direction

  def index
    authenticate_customer!
    authorize_customer!(:read, Customer)
    get_front_site()

    @roles = Customer::ROLE_SYMBOLS
    @customers = Customer.search(params[:search]).order(sort_column => sort_direction).paginate(:page => params[:page], :per_page => 4)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @customers }
      format.js # render index.js.erb
    end
  end

  def show
    authenticate_customer!
    authorize_customer!(:read, Customer)
    @customer = Customer.find(params[:id])
    get_front_site()
    raise NotFoundError if @customer.nil?

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @customer }
    end
  end

  def edit
    authenticate_customer!
    @customer = Customer.find(params[:id])
    get_front_site()
    raise NotFoundError if @customer.nil?

    authorize_customer!(:edit, @customer)
  end

  def update
    authenticate_customer!
    @customer = Customer.find(params[:id])
    authorize_customer!(:edit, @customer)

    @roles = Customer::ROLE_SYMBOLS

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
    authenticate_customer!
    @customer = Customer.find(params[:id])
    if @customer
      authorize_customer!(:delete, @customer)

      @customer.destroy
    end

    respond_to do |format|
      format.html { redirect_to customers_url }
      format.json { head :no_content }
      format.js # destroy.htm.erb
    end
  end

  private

  def get_front_site
    @site = Cms::Site.find_by_identifier("busme-main")
    @error_site = Cms::Site.find_by_identifier("busme-main-error")
    return @site
  end

  def sort_column
    Customer.keys.keys.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    [1, -1].include?(params[:direction].to_i) ? params[:direction].to_i : -1
  end
end
