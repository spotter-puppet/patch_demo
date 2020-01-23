class profile::app::wsus(
  $wsus_directory = 'C:\\WSUS',
  $sync_tod = "03:00:00", # 3AM (UTC) 24H Clock
) {

  class { 'wsusserver':
    package_ensure                     => 'present',
    include_management_console         => true,
    service_manage                     => true,
    service_ensure                     => 'running',
    service_enable                     => true,
    wsus_directory                     => $wsus_directory,
    join_improvement_program           => false,
    sync_from_microsoft_update         => true,
    update_languages                   => ['en'],
    products                           => [
      'Windows Server 2016'
    ],
    product_families                   => [
    ],
    update_classifications             => [
      'Update Rollups',
      'Security Updates',
      'Critical Updates',
      'Service Packs',
      'Updates'
    ],
    targeting_mode                     => 'Client',
    host_binaries_on_microsoft_update  => true,
    synchronize_automatically          => true,
    synchronize_time_of_day            => $sync_tod,
    number_of_synchronizations_per_day => 1,
  }

  wsusserver_computer_target_group { 'AutoApproval':
    ensure => 'present',
  }

  wsusserver::approvalrule { 'Automatic Approval for all Updates Rule':
    ensure          => 'present',
    enabled         => true,
    classifications => [
      'Update Rollups',
      'Security Updates',
      'Critical Updates',
      'Updates'
    ],
    products        => [
      'Windows Server 2016'
    ],
    computer_groups => ['AutoApproval'],
  }

  # Set 'restart_private_memory_limit' on the IIS WsusPool to largest value for stability
  iis_application_pool { 'WsusPool':
    ensure                       => 'present',
    state                        => 'started',
    managed_pipeline_mode        => 'Integrated',
    managed_runtime_version      => 'v4.0',
    enable32_bit_app_on_win64    => false,
    restart_private_memory_limit => 4294967,
    restart_schedule             => ['07:00:00', '15:00:00', '23:00:00']
  }
}
