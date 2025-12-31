probe backend_health_204 {
  # The URL path to request during health checks
  # This should be a lightweight endpoint on your backend that returns a 204 status
  # when the service is healthy
  .url = "/health";
  .expected_response = 204;

  # How frequently Varnish will poll the backend (in seconds)
  # Lower values provide faster detection of backend failures but increase load
  # Higher values reduce backend load but increase failure detection time
  .interval = 10s;

  # Maximum time to wait for a response from the backend
  # If the backend does not respond within this time, the probe is considered failed
  # Should be less than the interval to prevent probe overlap
  .timeout = 9s;

  # Number of most recent probes to consider when determining backend health
  # Varnish keeps a sliding window of the latest probe results
  # Higher values make the health determination more stable but slower to change
  .window = 10;

  # Minimum number of probes in the window that must succeed for the backend
  # to be considered healthy
  # In this case, at least 5 out of the 10 most recent probes must be successful
  # Half the window is a common value for basic fault tolerance
  .threshold = 5;

  # Initial assumed state of the backend
  # Starts with the backend considered healthy
  .initial = 5;
}