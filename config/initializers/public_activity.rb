PublicActivity::Activity.class_eval do
  scope :created_from, -> (from) { where('created_at >= ?', from) }
  scope :created_to, -> (to) { where('created_at <= ?', Date.strptime(to, '%m/%d/%Y').end_of_day) }

  private

  def self.ransackable_scopes(auth_object = nil)
    %i(created_from created_to)
  end
end