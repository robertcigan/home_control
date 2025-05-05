class Program < ApplicationRecord
  include AttributeOption
  include WebsocketPushChange
  attribute_options :program_type, [:default, :repeated]

  serialize :storage, type: Hash, coder: YAML

  has_many :programs_devices, dependent: :destroy
  has_many :devices, through: :programs_devices
  has_many :widgets, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :program_type, presence: true

  accepts_nested_attributes_for :programs_devices, reject_if: :all_blank, allow_destroy: true

  scope :default, -> { where(program_type: ProgramType::DEFAULT) }
  scope :repeated, -> { where(program_type: ProgramType::REPEATED) }
  scope :repeated_to_run, -> { repeated.where(enabled: true).where("(now() - last_run) >= interval '1 seconds' * COALESCE(repeat_every, 1)")}

  before_save :set_default_storage
  before_save :precompile_code

  amoeba do
    enable
  end

  def to_s
    name
  end

  def run
    start_time = Time.current
    extend(ProgramsHelper)
    self.output = ""
    begin
      log_info("Program #{name} started")
      eval(compiled_code)
      log_info("Program #{name} finished successfully")
    rescue Exception => e
      log_error("Program #{name} failed: #{e.message}")
      update(last_error_at: Time.current, last_error_message: e.message, last_run: Time.current, runtime: ((start_time - Time.current) * 1000).round)
    ensure
      update(last_run: Time.current, runtime: ((Time.current - start_time) * 1000).round)
    end
  end

  def thread_utilisation
    if runtime
      if program_type_repeated?
        runtime / (repeat_every * 10.0)
      elsif program_type_default?
        runtime / ((Time.current - last_run) * 10.0)
      end
    else
      0.0
    end
  end

  def set(key, val)
    self.storage[key] = val
  end

  def get(key)
    storage[key]
  end

  def set_default_storage
    self.storage = {} if storage.nil?
  end

  def last_run_text
    last_run ? I18n.l(last_run, format: :custom) : nil
  end

  def last_error_at_text
    last_error_at ? I18n.l(last_error_at, format: :custom) : nil
  end

  def json_data
    super.merge(
      enabled: enabled.to_s,
      runtime: runtime,
      "thread-utilisation": thread_utilisation.round(1),
      "last-run": last_run_text,
      "last-error-at": last_error_at_text,
      "has-error": has_error?.to_s
    )
  end

  def has_error?
    last_run == last_error_at
  end

  private

  def precompile_code
    if code_changed? || code.present? && compiled_code.blank?
      prepend_variables = ""
      temp_code = code.dup
      programs_devices.each do |programs_device|
        prepend_variables << "#{programs_device.variable_name}_device = Device.find(#{programs_device.device_id})\n"
        temp_code.gsub!("{{#{programs_device.variable_name}}}", "#{programs_device.variable_name}_device")
      end
      self.compiled_code = [prepend_variables, temp_code].join("\n")
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end
