class EbayAccountsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_ebay_account, only: [:show, :edit, :update, :destroy]

  # GET /ebay_accounts
  # GET /ebay_accounts.json
  def index
    @ebay_accounts = current_user.ebay_accounts.all
  end

  # GET /ebay_accounts/1
  # GET /ebay_accounts/1.json
  def show
  end

  # GET /ebay_accounts/new
  def new
    @ebay_account = EbayAccount.new
  end

  # GET /ebay_accounts/1/edit
  def edit
  end

  # POST /ebay_accounts
  # POST /ebay_accounts.json
  def create
    @ebay_account = EbayAccount.new(ebay_account_params)
    @ebay_account.user = current_user

    respond_to do |format|
      if @ebay_account.save
        format.html { redirect_to @ebay_account, notice: 'Ebay account was successfully created.' }
        format.json { render :show, status: :created, location: @ebay_account }
      else
        format.html { render :new }
        format.json { render json: @ebay_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ebay_accounts/1
  # PATCH/PUT /ebay_accounts/1.json
  def update
    respond_to do |format|
      if @ebay_account.update(ebay_account_params)
        format.html { redirect_to @ebay_account, notice: 'Ebay account was successfully updated.' }
        format.json { render :show, status: :ok, location: @ebay_account }
      else
        format.html { render :edit }
        format.json { render json: @ebay_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ebay_accounts/1
  # DELETE /ebay_accounts/1.json
  def destroy
    @ebay_account.destroy
    respond_to do |format|
      format.html { redirect_to ebay_accounts_url, notice: 'Ebay account was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ebay_account
      @ebay_account = EbayAccount.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ebay_account_params
      p = params.require(:ebay_account).permit(:auth_token,
                                               'auth_token_expiry_time(1i)',
                                               'auth_token_expiry_time(2i)',
                                               'auth_token_expiry_time(3i)',
                                               'auth_token_expiry_time(4i)',
                                               'auth_token_expiry_time(5i)')

      year   = p.delete('auth_token_expiry_time(1i)')
      month  = p.delete('auth_token_expiry_time(2i)')
      day    = p.delete('auth_token_expiry_time(3i)')
      hour   = p.delete('auth_token_expiry_time(4i)')
      minute = p.delete('auth_token_expiry_time(5i)')

      p[:auth_token_expiry_time] = Time.utc(year, month, day, hour, minute)
      p
    end
end
