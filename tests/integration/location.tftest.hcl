run "deploys_data_collection_rule_in_required_location" {
  command = apply

  module {
    source = "./examples/required-location"
  }

  variables {
    location = "eastus2"
  }

  assert {
    condition     = output.data_collection_rule_location == "eastus2"
    error_message = "The deployed Data Collection Rule must use the required location."
  }

  assert {
    condition     = length(output.data_collection_rule_id) > 0
    error_message = "The deployed Data Collection Rule must return a resource ID."
  }
}
