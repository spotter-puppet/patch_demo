class profile::platform::baseline::windows::patch_mgmt(
  Array $blacklist = [],
  Array $whitelist = [],
  $server_url = "http://wsus.example.com:8530",
  $target_group = "AutoApproval",
  $enable_status_server = true,
  $auto_install_minor_updates = false,
  $auto_update_option = "NotifyOnly",
  $detection_frequency_hours = 22,
  Optional[Hash] $patch_window = {
    range   => "01:00 - 04:00",
    weekday => "Sunday",
    repeat  => 3
  }
) {
  include os_patching
  
  class { 'wsus_client':
    server_url                 => $server_url,
    target_group               => $target_group,
    enable_status_server       => $enable_status_server,
    auto_install_minor_updates => $auto_install_minor_updates,
    auto_update_option         => $auto_update_option,
    detection_frequency_hours  => $detection_frequency_hours,
  }

  if $facts['os_patching'] {
    $updatescan = $facts['os_patching']['missing_update_kbs']
  } else {
    $updatescan = []
  }

  if $whitelist.count > 0 {
    $updates = $updatescan.filter |$item| { $item in $whitelist }
  } elsif $blacklist.count > 0 {
    $updates = $updatescan.filter |$item| { !($item in $blacklist) }
  } else {
    $updates = $updatescan
  }

  schedule { 'patch_window':
    * => $patch_window
  }

  if $facts['os_patching']['reboots']['reboot_required'] == true {
    Windows_updates::Kb {
      require => Reboot['patch_window_reboot']
    }
    notify { 'Reboot pending, rebooting node...':
      schedule => 'patch_window',
      notify   => Reboot['patch_window_reboot']
    }
  }

  reboot { 'patch_window_reboot':
    apply    => 'finished',
    schedule => 'patch_window'
  }
  
  $updates.each | $kb | {
    windows_updates::kb { $kb:
      ensure      => 'present',
      maintwindow => 'patch_window'
    }
  }

}
