Spree::CheckoutController.class_eval do
  before_action :save_user_to_create, only: [:update]
  before_action :verify_updated_user_to_create, only: [:update]
  before_action :load_order_create_user, only: [:edit]

  after_filter :create_user, only: [:update]

  def create_user
    return if !@order.completed?

    load_order_create_user
    if !@order_create_user.blank?
      user = Spree::User.new(
        email: @order.email,
        password: @order_create_user['password'],
        password_confirmation: @order_create_user['password']
      )

      if user.save
        flash[:success] = Spree.t('checkout_registration.user_created')
        @order.update(user: user)
      else
        Spree.t('checkout_registration.user_not_created')
        flash[:error] = Spree.t('checkout_registration.user_not_created')
        flash[:error] += ', ' + user.errors.full_messages.join(', ') unless user.errors.blank?
      end
    end
  end

  def save_user_to_create
    return if @order.state != 'address' || !current_spree_user.blank? || params[:create_account] != '1'

    user = Spree::User.new(
      email: @order.email,
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if user.valid?
      set_order_create_user
    else
      clear_order_create_user
      flash[:error] = user.errors.full_messages.join(', ') unless user.errors.blank?
      redirect_to :back
    end
  end

  def verify_updated_user_to_create
    return if params[:order].blank? || params[:order][:email].blank? || params[:order][:email] == @order.email
    user = Spree::User.new(
      email: params[:order][:email],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if user.valid?
      set_order_create_user
    else
      clear_order_create_user
      flash[:error] = user.errors.full_messages.join(', ') unless user.errors.blank?
      redirect_to :back
    end
  end

  private

  def load_order_create_user
    @order_create_user = session[:order_create_user] if current_spree_user.blank? &&
                                                        !session[:order_create_user].blank? &&
                                                        session[:order_create_user]['order_number'] == @order.number
  end

  def set_order_create_user
    session[:order_create_user] = {
      order_number: @order.number,
      password: params[:password]
    }
  end

  def clear_order_create_user
    session[:order_create_user] = nil
  end
end