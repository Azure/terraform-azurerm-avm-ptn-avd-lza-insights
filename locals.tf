locals {
  # The ARM schema models `properties.dataFlows` as an array of objects using
  # camelCase keys, so the module's snake_case inputs are renamed here.
  data_flows = [
    for flow in var.data_flows : {
      builtInTransform = flow.built_in_transform
      captureOverflow  = flow.capture_overflow
      destinations     = flow.destinations
      outputStream     = flow.output_stream
      streams          = flow.streams
      transformKql     = flow.transform_kql
    }
  ]
}

locals {
  data_sources = var.data_sources == null ? null : {
    # `dataImports.eventHub` is a single object in ARM, not a list.
    dataImports = var.data_sources.data_imports == null ? null : {
      eventHub = {
        consumerGroup = var.data_sources.data_imports.event_hub.consumer_group
        name          = var.data_sources.data_imports.event_hub.name
        stream        = var.data_sources.data_imports.event_hub.stream
      }
    }
    extensions = var.data_sources.extensions == null ? null : [
      for extension in var.data_sources.extensions : {
        extensionName = extension.extension_name
        # ARM expects an object here, so the caller's JSON string is decoded.
        extensionSettings = extension.extension_settings == null ? null : jsondecode(extension.extension_settings)
        inputDataSources  = extension.input_data_sources
        name              = extension.name
        streams           = extension.streams
      }
    ]
    iisLogs = var.data_sources.iis_logs == null ? null : [
      for iis_log in var.data_sources.iis_logs : {
        logDirectories = iis_log.log_directories
        name           = iis_log.name
        streams        = iis_log.streams
        transformKql   = iis_log.transform_kql
      }
    ]
    logFiles = var.data_sources.log_files == null ? null : [
      for log_file in var.data_sources.log_files : {
        filePatterns = log_file.file_patterns
        format       = log_file.format
        name         = log_file.name
        settings = log_file.settings == null ? null : {
          text = {
            recordStartTimestampFormat = log_file.settings.text.record_start_timestamp_format
          }
        }
        streams      = log_file.streams
        transformKql = log_file.transform_kql
      }
    ]
    performanceCounters = var.data_sources.performance_counters == null ? null : [
      for counter in var.data_sources.performance_counters : {
        counterSpecifiers          = counter.counter_specifiers
        name                       = counter.name
        samplingFrequencyInSeconds = counter.sampling_frequency_in_seconds
        streams                    = counter.streams
        transformKql               = counter.transform_kql
      }
    ]
    platformTelemetry = var.data_sources.platform_telemetry == null ? null : [
      for telemetry in var.data_sources.platform_telemetry : {
        name    = telemetry.name
        streams = telemetry.streams
      }
    ]
    prometheusForwarder = var.data_sources.prometheus_forwarder == null ? null : [
      for forwarder in var.data_sources.prometheus_forwarder : {
        # ARM models the filters as a dictionary of label name to label value.
        labelIncludeFilter = forwarder.label_include_filter
        name               = forwarder.name
        streams            = forwarder.streams
      }
    ]
    syslog = var.data_sources.syslog == null ? null : [
      for syslog in var.data_sources.syslog : {
        facilityNames = syslog.facility_names
        logLevels     = syslog.log_levels
        name          = syslog.name
        streams       = syslog.streams
        transformKql  = syslog.transform_kql
      }
    ]
    windowsEventLogs = var.data_sources.windows_event_logs == null ? null : [
      for event_log in var.data_sources.windows_event_logs : {
        name         = event_log.name
        streams      = event_log.streams
        transformKql = event_log.transform_kql
        xPathQueries = event_log.x_path_queries
      }
    ]
    windowsFirewallLogs = var.data_sources.windows_firewall_logs == null ? null : [
      for firewall_log in var.data_sources.windows_firewall_logs : {
        name          = firewall_log.name
        profileFilter = firewall_log.profile_filter
        streams       = firewall_log.streams
      }
    ]
  }
}

locals {
  # Every destination except `azureMonitorMetrics` is an array in the ARM schema.
  destinations = {
    azureDataExplorer = var.destinations.azure_data_explorer == null ? null : [
      for destination in var.destinations.azure_data_explorer : {
        databaseName = destination.database_name
        ingestionUri = destination.ingestion_uri
        name         = destination.name
        resourceId   = destination.resource_id
      }
    ]
    azureMonitorMetrics = var.destinations.azure_monitor_metrics == null ? null : {
      name = var.destinations.azure_monitor_metrics.name
    }
    eventHubs = var.destinations.event_hubs == null ? null : [
      for destination in var.destinations.event_hubs : {
        eventHubResourceId = destination.event_hub_resource_id
        name               = destination.name
      }
    ]
    eventHubsDirect = var.destinations.event_hubs_direct == null ? null : [
      for destination in var.destinations.event_hubs_direct : {
        eventHubResourceId = destination.event_hub_resource_id
        name               = destination.name
      }
    ]
    logAnalytics = var.destinations.log_analytics == null ? null : [
      for destination in var.destinations.log_analytics : {
        name                = destination.name
        workspaceResourceId = destination.workspace_resource_id
      }
    ]
    microsoftFabric = var.destinations.microsoft_fabric == null ? null : [
      for destination in var.destinations.microsoft_fabric : {
        artifactId   = destination.artifact_id
        databaseName = destination.database_name
        ingestionUri = destination.ingestion_uri
        name         = destination.name
        tenantId     = destination.tenant_id
      }
    ]
    monitoringAccounts = var.destinations.monitoring_accounts == null ? null : [
      for destination in var.destinations.monitoring_accounts : {
        accountResourceId = destination.account_resource_id
        name              = destination.name
      }
    ]
    storageAccounts = var.destinations.storage_accounts == null ? null : [
      for destination in var.destinations.storage_accounts : {
        containerName            = destination.container_name
        name                     = destination.name
        storageAccountResourceId = destination.storage_account_resource_id
      }
    ]
    storageBlobsDirect = var.destinations.storage_blobs_direct == null ? null : [
      for destination in var.destinations.storage_blobs_direct : {
        containerName            = destination.container_name
        name                     = destination.name
        storageAccountResourceId = destination.storage_account_resource_id
      }
    ]
    storageTablesDirect = var.destinations.storage_tables_direct == null ? null : [
      for destination in var.destinations.storage_tables_direct : {
        name                     = destination.name
        storageAccountResourceId = destination.storage_account_resource_id
        tableName                = destination.table_name
      }
    ]
  }
}

locals {
  # ARM keys `properties.streamDeclarations` by stream name, so the map key is
  # the stream name rather than an attribute on each element.
  stream_declarations = var.stream_declarations == null ? null : {
    for stream_name, declaration in var.stream_declarations : stream_name => {
      columns = declaration.columns
    }
  }
}

locals {
  has_user_assigned_identities = length(var.managed_identities.user_assigned_resource_ids) > 0
  identity_type = (
    var.managed_identities.system_assigned && local.has_user_assigned_identities ? "SystemAssigned, UserAssigned" : (
      var.managed_identities.system_assigned ? "SystemAssigned" : (
        local.has_user_assigned_identities ? "UserAssigned" : null
      )
    )
  )
}
