collection @activities

node(:elapsed) { |activity| time_ago_in_words(activity.created_at) }
node(:date) { |activity| activity.created_at.to_date == Date.today ? 'Today' : activity.created_at.strftime('%b %d, %Y') }
node(:created_at) { |activity| activity.created_at.to_date }
node(:title) { |activity| t("activity.#{activity.key}.title", user: activity.owner.try(:name)) }
node(:icon) { |activity| t("activity.#{activity.key}.icon") }
node(:color) { |activity| "bgcolor-#{t("activity.#{activity.key}.color")}" }
node(:body) do |activity|
  if activity.trackable.is_a? Maintenance::WorkOrder
    work_order_url = link_to("WO ##{activity.trackable.id}", maintenance_work_orders_path(id: activity.trackable.id), class: 'text-primary semibold')
    t("activity.#{activity.key}.body", user: activity.owner.try(:name),
                                       url: work_order_url,
                                       maintainable_name: activity.trackable.maintainable.to_s
     )
  elsif activity.trackable.is_a? Maintenance::MaintenanceRecord
    t("activity.#{activity.key}.body", user: activity.owner.try(:name),
                                       maintainable: activity.trackable.maintainable.to_s,
                                       status: maintenance_record_status(activity.trackable)
     )
  elsif activity.trackable.is_a? Comment
    t("activity.#{activity.key}.body", body: activity.trackable.body)
  end
end
node(:avatar) { |activity| activity.owner.present? ? activity.owner.avatar.thumb.url : '' }