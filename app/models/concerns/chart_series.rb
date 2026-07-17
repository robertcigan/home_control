module ChartSeries
  extend ActiveSupport::Concern

  MAX_CHART_POINTS = 2000

  class_methods do
    private

    def chart_window_scope(owner_column, owner_id, min, max)
      where(owner_column => owner_id).where("created_at >= ? AND created_at <= ?", min, max).order(:created_at)
    end

    def bucket_average_series(owner_id:, owner_column:, value_column:, min:, max:, cap:, scale: 1.0)
      window_seconds = (max - min).to_f
      if window_seconds <= 0
        []
      else
        bucket_seconds = [(window_seconds / cap).ceil, 1].max
        column = connection.quote_column_name(value_column.to_s)
        owner = connection.quote_column_name(owner_column.to_s)
        sql = sanitize_sql_array(
          [
            <<~SQL.squish,
              SELECT
                date_bin((? || ' seconds')::interval, created_at, ?::timestamptz) AS bucket,
                AVG(#{column}) AS avg_value
              FROM #{table_name}
              WHERE #{owner} = ?
                AND created_at >= ?
                AND created_at <= ?
              GROUP BY bucket
              ORDER BY bucket
            SQL
            bucket_seconds.to_s,
            min,
            owner_id,
            min,
            max
          ]
        )

        connection.select_all(sql).map do |row|
          bucket = Time.zone.parse(row["bucket"].to_s)
          midpoint = bucket + (bucket_seconds / 2.0).seconds
          value = row["avg_value"]
          if value.nil?
            [midpoint.to_s, nil]
          else
            [midpoint.to_s, value.to_f * scale]
          end
        end
      end
    end
  end
end
