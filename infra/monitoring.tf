resource "random_password" "grafana_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*+-=?@_"
}
