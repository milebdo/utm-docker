package config

import "os"

const PanelConnectionKeyEndpoint = "%s/api/federation-service/token"
const PanelPipelinesEndpoint = "%s/api/logstash-pipelines/port"
const LogstashPipelinesEndpoint = "http://%s:%s"
const PanelAPIKeyHeader = "Utm-Internal-Key"
const ProxyAPIKeyHeader = "Utm-Connection-Key"
const ProxyLogTypeHeader = "Utm-Log-Type"
const ProxySourceHeader = "Utm-Log-Source"
const UTMSharedKeyEnv = "INTERNAL_KEY"
const UTMHostEnv = "UTM_HOST"
const UTMAgentManagerHostEnv = "UTM_AGENT_MANAGER_HOST"
const UTMLogstashHostEnv = "UTM_LOGSTASH_HOST"
const UTMCertsLocationEnv = "UTM_CERTS_LOCATION"
const UTMCertFileName = "utm.crt"
const UTMCertFileKey = "utm.key"
const UTMLogSeparator = "<utm-log-separator>"

func LogstashHost() string {
	return os.Getenv(UTMLogstashHostEnv)
}

type LogType string

const (
	BeatsLinuxAgent          LogType = "beats_linux_agent"
	BeatsApacheModule                = "beats_apache_module"
	BeatsApache2Module               = "beats_apache2_module"
	BeatsAuditdModule                = "beats_auditd_module"
	BeatsElasticsearchModule         = "beats_elasticsearch_module"
	BeatsKafkaModule                 = "beats_kafka_module"
	BeatsKibanaModule                = "beats_kibana_module"
	BeatsLogstashModule              = "beats_logstash_module"
	BeatsMongodbModule               = "beats_mongodb_module"
	BeatsMysqlModule                 = "beats_mysql_module"
	BeatsNginxModule                 = "beats_nginx_module"
	BeatsOsqueryModule               = "beats_osquery_module"
	BeatsPostgresqlModule            = "beats_postgresql_module"
	BeatsRedisModule                 = "beats_redis_module"
	BeatsIisModule                   = "beats_iis_module"
	MacosLogs                        = "macos_logs"
	Vmware                           = "vmware"
	CiscoAsa                         = "cisco_asa"
	CiscoMeraki                      = "cisco_meraki"
	CiscoFirepower                   = "cisco_firepower"
	CiscoSwitch                      = "cisco_switch"
	AntivirusKaspersky               = "antivirus_kaspersky"
	AntivirusEset                    = "antivirus_eset"
	AntivirusSentinelOne             = "antivirus_sentinel_one"
	FirewallFortinet                 = "firewall_fortinet"
	FirewallSophos                   = "firewall_sophos"
	CloudAzure                       = "cloud_azure"
	CloudGoogle                      = "cloud_google"
	FirewallUbuntu                   = "firewall_ubuntu"
	FirewallMikrotik                 = "firewall_mikrotik"
	FirewallPaloalto                 = "firewall_paloalto"
	FirewallSonicwall                = "firewall_sonicwall"
	AntivirusDeceptivebytes          = "antivirus_deceptivebytes"
	WebHookGithub                    = "web_hook_github"
	AntivirusBitdefender             = "antivirus_bitdefender"
	BeatsWindowsAgent                = "beats_windows_agent"
	BeatsTraefikModule               = "beats_traefik_module"
	BeatsNatsModule                  = "beats_nats_module"
	BeatsHaproxyModule               = "beats_haproxy_module"
	JsonInput                        = "json_input"
	Syslog                           = "syslog"
	Generic                          = "generic"
	Netflow                          = "netflow"
	Aix                              = "ibm_aix"
	AS400                            = "as_400"
	FirewallPfsense                  = "firewall_pfsense"
	FirewallFortiweb                 = "firewall_fortiweb"
	Suricata                         = "suricata"
)

type ServiceStatus string

const (
	Up   ServiceStatus = "up"
	Down               = "down"
)

type PipelinePortConfiguration struct {
	InputId LogType
	Port    string
}

func ValidateConnectorType(typ string) string {
	switch LogType(typ) {
	case AS400:
		return "collector"
	default:
		return "agent"
	}
}
