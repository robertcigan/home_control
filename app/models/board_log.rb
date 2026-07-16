class BoardLog < ApplicationRecord
  include ChartSeries

  belongs_to :board

  scope :recent, -> { order("id DESC").limit(20) }

  def self.chart_connection_series(board, min, max, cap: MAX_CHART_POINTS)
    # Never downsample connection state — skipped transitions would hide
    # short disconnects/reconnects on the stepped chart.
    chart_window_scope(:board_id, board.id, min, max).map(&:chart_data_status)
  end

  def self.chart_signal_series(board, min, max, cap: MAX_CHART_POINTS)
    scope = chart_window_scope(:board_id, board.id, min, max)
    count = scope.count

    if count > cap
      bucket_average_series(
        owner_id: board.id,
        owner_column: :board_id,
        value_column: :signal_strength,
        min: min,
        max: max,
        cap: cap,
        scale: 0.01
      )
    else
      scope.map(&:chart_data_signal_strength)
    end
  end

  def indication
    connected? ? "connected" : "disconnected"
  end

  def chart_data_status
    [created_at.to_s, connected? ? 1 : 0]
  end

  def chart_data_ssid
    [created_at.to_s, ssid]
  end

  def chart_data_signal_strength
    [created_at.to_s, signal_strength ? (signal_strength / 100.0) : nil]
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end
