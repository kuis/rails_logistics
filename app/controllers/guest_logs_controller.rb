class GuestLogsController < ApplicationController
  add_breadcrumb I18n.t('controllers.guest_logs'), :guest_logs_path
  def index
    respond_to do |format|
      format.json {
        render json: get_logs
      }
      format.pdf do
        @results = get_logs
        title = format("Hotel Guest Logs")
        render pdf: title,
               template: 'guest_logs/index',
               layout: 'layouts/pdf.html.haml',
               header: {
                   html: {
                       template: 'reports/pdf/header',
                       locals: {
                           report_title: title
                       }
                   },
                   spacing: -10
               },
               footer: {
                   center: '[page] of [topage]'
               }
      end
      format.html {}
    end
  end

  def create
    @log = Comment.build_from(current_property, current_user.id, params[:body])
    if @log.save
      render json: @log.as_json(current_user: current_user)
    else
      render json: {errors: @log.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def like
    @log = Comment.find(params[:id])
    @log.liked_by current_user
    render json: @log.as_json(current_user: current_user)
  end

  def set_alarm
    @alarm = Alarm.new(alarm_params)
    @alarm.user = current_user
    @alarm.property = current_property
    @alarm.save
    render json: @alarm.as_json(current_user: current_user)
  end

  def check_alarm
    @alarm = Alarm.find(params[:id])
    if @alarm.update(checked_by: current_user, checked_on: Time.now)
      render json: @alarm.as_json(current_user: current_user)
    else
      render json: {errors: @alarm.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def remove_alarm
    @alarm = Alarm.find(params[:id])
    @alarm.destroy
    head :ok
  end

  private
  def alarm_params
    params.permit(:alarm_at, :body)
  end

  def get_logs
    comments = current_property.root_comments.where("to_char(created_at, 'MM/DD/YYYY') = ?", params[:date]).order(created_at: :desc)
    alarms = current_property.alarms.where("to_char(alarm_at, 'MM/DD/YYYY') = ?", params[:date]).order(:alarm_at)
    results = {comments: comments.as_json(current_user: current_user), alarms: alarms.as_json(current_user: current_user)}
  end
end
