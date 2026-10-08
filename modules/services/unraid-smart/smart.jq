def sample(name; labels; value): "unraid_disk_\(name){device=\"\(.device.name)\"\(labels)} \(value)";
def sample(name; value): sample(name; ""; value);

select(.smart_status != null)
| sample("info"; ",model=\"\(.model_name)\",serial=\"\(.serial_number)\""; 1),
  sample("smart_passed"; if .smart_status.passed then 1 else 0 end),
  (select(.temperature.current != null) | sample("temperature_celsius"; .temperature.current)),
  (select(.temperature.op_limit_max != null) | sample("temperature_limit_celsius"; .temperature.op_limit_max)),
  (. as $disk | .ata_smart_attributes.table[]?
    | select(.id == (5, 187, 197, 198))
    | . as $attribute
    | $disk | sample("ata_attribute_raw"; ",attribute=\"\($attribute.name)\""; $attribute.raw.value)),
  (.nvme_smart_health_information_log as $log | select($log != null)
    | sample("nvme_critical_warning"; $log.critical_warning),
      sample("nvme_media_errors_total"; $log.media_errors),
      sample("nvme_available_spare_ratio"; $log.available_spare / 100),
      sample("nvme_available_spare_threshold_ratio"; $log.available_spare_threshold / 100),
      sample("nvme_percentage_used_ratio"; $log.percentage_used / 100))
