variable "project_id" {
  description = "GCP project ID where all load balancer resources are created."
  type        = string
}

variable "region" {
  description = "Default GCP region for regional load balancer resources."
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Common governance labels applied to all resources."
  type        = map(string)
  default     = {}
}

variable "global_http_lbs" {
  description = "Global external application load balancers (HTTP/HTTPS Layer 7)."
  type = list(object({
    key                   = string
    create                = optional(bool, true)
    name                  = string
    enable_https          = optional(bool, false)
    ssl_domains           = optional(list(string), [])
    ssl_cert_ids          = optional(list(string), [])
    reserve_ip_address    = optional(bool, false)
    load_balancing_scheme = optional(string, "EXTERNAL_MANAGED")
    backend_service_name  = string
    protocol              = optional(string, "HTTP")
    session_affinity      = optional(string, "NONE")
    timeout_sec           = optional(number, 30)
    enable_cdn            = optional(bool, false)
    enable_logging        = optional(bool, false)
    log_sample_rate       = optional(number, 1.0)
    backends = list(object({
      group                 = string
      balancing_mode        = optional(string, "UTILIZATION")
      capacity_scaler       = optional(number, 1.0)
      max_utilization       = optional(number, 0.8)
      max_rate_per_instance = optional(number, 0)
    }))
    health_check = object({
      name                = string
      protocol            = optional(string, "HTTP")
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })
    url_map_name = string
  }))
  default = []
}

variable "regional_http_lbs" {
  description = "Regional application load balancers (external or internal HTTP/HTTPS Layer 7)."
  type = list(object({
    key                   = string
    create                = optional(bool, true)
    name                  = string
    region                = optional(string, "")
    load_balancing_scheme = optional(string, "EXTERNAL_MANAGED")
    enable_https          = optional(bool, false)
    ssl_cert_ids          = optional(list(string), [])
    network               = optional(string, "")
    subnetwork            = optional(string, "")
    reserve_ip_address    = optional(bool, false)
    backend_service_name  = string
    protocol              = optional(string, "HTTP")
    session_affinity      = optional(string, "NONE")
    timeout_sec           = optional(number, 30)
    enable_logging        = optional(bool, false)
    log_sample_rate       = optional(number, 1.0)
    backends = list(object({
      group           = string
      balancing_mode  = optional(string, "UTILIZATION")
      capacity_scaler = optional(number, 1.0)
      max_utilization = optional(number, 0.8)
    }))
    health_check = object({
      name                = string
      protocol            = optional(string, "HTTP")
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })
    url_map_name = string
  }))
  default = []
}

variable "network_lbs" {
  description = "Regional external passthrough network load balancers (TCP/UDP Layer 4)."
  type = list(object({
    key                = string
    create             = optional(bool, true)
    name               = string
    region             = optional(string, "")
    protocol           = optional(string, "TCP")
    all_ports          = optional(bool, false)
    ports              = optional(list(string), [])
    reserve_ip_address = optional(bool, false)
    backends = list(object({
      group           = string
      balancing_mode  = optional(string, "CONNECTION")
      capacity_scaler = optional(number, 1.0)
    }))
    health_check = object({
      name                = string
      protocol            = optional(string, "TCP")
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })
  }))
  default = []
}

variable "internal_lbs" {
  description = "Regional internal passthrough network load balancers (TCP/UDP Layer 4)."
  type = list(object({
    key           = string
    create        = optional(bool, true)
    name          = string
    region        = optional(string, "")
    protocol      = optional(string, "TCP")
    all_ports     = optional(bool, false)
    ports         = optional(list(string), [])
    network       = string
    subnetwork    = string
    global_access = optional(bool, false)
    backends = list(object({
      group           = string
      balancing_mode  = optional(string, "CONNECTION")
      capacity_scaler = optional(number, 1.0)
    }))
    health_check = object({
      name                = string
      protocol            = optional(string, "TCP")
      port                = optional(number, 80)
      request_path        = optional(string, "/")
      check_interval_sec  = optional(number, 10)
      timeout_sec         = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    })
  }))
  default = []
}
