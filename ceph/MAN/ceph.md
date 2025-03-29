
# General usage: 

```shell
usage: ceph [-h] [-c CEPHCONF] [-i INPUT_FILE] [-o OUTPUT_FILE]
            [--setuser SETUSER] [--setgroup SETGROUP] [--id CLIENT_ID]
            [--name CLIENT_NAME] [--cluster CLUSTER]
            [--admin-daemon ADMIN_SOCKET] [-s] [-w] [--watch-debug]
            [--watch-info] [--watch-sec] [--watch-warn] [--watch-error]
            [-W WATCH_CHANNEL] [--version] [--verbose] [--concise]
            [-f {json,json-pretty,xml,xml-pretty,plain,yaml}]
            [--connect-timeout CLUSTER_TIMEOUT] [--block] [--period PERIOD]
	
optional arguments:
-h, --help            请求监视帮助
-c CEPHCONF, --conf CEPHCONF
                        Ceph 配置文件
-i INPUT_FILE, --in-file INPUT_FILE
                        输入文件，或者用 "-" 表示标准输入
-o OUTPUT_FILE, --out-file OUTPUT_FILE
                        输出文件，或者用 "-" 表示标准输出
--setuser SETUSER     设置用户文件权限
--setgroup SETGROUP   设置组文件权限
--id CLIENT_ID, --user CLIENT_ID
                        用于身份验证的客户端 ID
--name CLIENT_NAME, -n CLIENT_NAME
                        用于身份验证的客户端名称
--cluster CLUSTER     集群名称
--admin-daemon ADMIN_SOCKET
                        提交管理员套接字命令（"help" 获取帮助）
-s, --status          显示集群状态
-w, --watch           观看实时集群变化
--watch-debug         观看调试事件
--watch-info          观看信息事件
--watch-sec           观看安全事件
--watch-warn          观看警告事件
--watch-error         观看错误事件
-W WATCH_CHANNEL, --watch-channel WATCH_CHANNEL
                        观看特定通道上的实时集群变化
                        （例如，cluster、audit、cephadm，或者 '*' 表示所有）
--version, -v         显示版本
--verbose             输出详细信息
--concise             输出简洁信息
-f {json,json-pretty,xml,xml-pretty,plain,yaml}, --format {json,json-pretty,xml,xml-pretty,plain,yaml}
--connect-timeout CLUSTER_TIMEOUT
                        设置连接集群的超时时间
--block               阻塞直到完成（仅适用于 scrub 和 deep-scrub）
--period PERIOD, -p PERIOD
                        轮询周期，默认 1.0 秒（仅适用于轮询命令）
```

# 未分类
```shell
df [detail]                                                                   显示集群空闲空间统计
features                                                                      报告连接的特性
insights                                                                      获取洞察报告
insights prune-health [<hours:int>]                                           删除超过 <hours> 小时的健康历史
iostat [<width:int>] [--print-header]                                         获取 IO 速率
node ls [all|osd|mon|mds|mgr]                                                 列出集群中所有节点 [类型]
prometheus file_sd_config                                                     返回适用于 mgr 集群的 file_sd 兼容的 prometheus 配置
quorum_status                                                                 报告监视器法定人数状态
report [<tags>...]                                                            报告集群的完整状态，附加标签字符串（可选）
service dump                                                                  转储服务映射
service status                                                                转储服务状态
status                                                                        显示集群状态
telegraf config-set <key> <value>                                             设置配置值
telegraf config-show                                                          显示当前配置
telegraf send                                                                 强制发送数据到 Telegraf
telemetry off                                                                 禁用来自该集群的遥测报告
telemetry on [<license>]                                                      启用来自该集群的遥测报告
telemetry send [ceph|device...] [<license>]                                   强制发送数据到 Ceph 遥测
telemetry show [<channels>...]                                                显示最后的报告或即将发送的报告
telemetry show-all                                                            显示所有频道的报告
telemetry show-device                                                         显示最后的设备报告或即将发送的设备报告
telemetry status                                                              显示当前配置
tell <type.id> <args>...                                                      向特定守护进程发送命令
test_orchestrator load_data                                                   向测试编排器加载虚拟数据
time-sync-status                                                              显示时间同步状态
versions                                                                      检查正在运行的 Ceph 守护进程版本

```

# auth管理命令
```shell
auth add <entity> [<caps>...]         # 从输入文件为 <entity> 添加授权信息，如果没有输入文件则使用随机密钥，并/或根据命令中指定的任何权限
auth caps <entity> <caps>...          # 更新 <entity> 的权限，根据命令中指定的权限
auth export [<entity>]                    # 为请求的实体写入密钥环文件，如果未指定则为主密钥环
auth get <entity>                            # 写入请求的密钥的密钥环文件
auth get-key <entity>                     # 显示请求的密钥
auth get-or-create <entity> [<caps>...]         # 从输入文件为 <entity> 添加授权信息，如果没有输入文件则使用随机密钥，并/或根据命令中指定的任何权限
auth get-or-create-key <entity> [<caps>...]   # 获取或添加密钥，对于指定的系统/权限对，如果密钥已经存在，任何给定的权限必须与现有的权限匹配
auth import                                      # 授权导入：从 -i <file> 读取密钥环文件
auth ls                                               # 列出认证状态
auth print-key <entity>                    # 显示请求的密钥
auth print_key <entity>                    # 显示请求的密钥
auth rm <entity>                              # 移除 <entity> 的所有权限
```


# Local commands: 
```shell
ping <mon.id>           # 发送简单的存在/存活测试到一个mon, <mon.id> 可以是 'mon.*' 来表示所有mons
daemon {type.id|path} <cmd>          # 与 --admin-daemon 相同，但自动找到管理员套接字
daemonperf {type.id | path} [stat-pats] [priority] [<interval>] [<count>]
daemonperf {type.id | path} list|ls [stat-pats] [priority]
					从守护进程/管理员套接字获取选定的性能统计
					可选的shell-glob逗号分隔匹配字符串 stat-pats
					可选的选择优先级（可以缩写名称）：critical, interesting, useful, noninteresting, debug
					列表显示所有可用统计的表格
					运行 <count> 次（默认无限次），每 <interval> 秒运行一次（默认 1秒）
```

# balancer
```shell
balancer dump <plan>                                                          # 显示优化计划
balancer eval [<option>]                                                      # 评估当前集群或特定池或特定计划的数据分布
balancer eval-verbose [<option>]                                              # 详细评估当前集群或特定池或特定计划的数据分布
balancer execute <plan>                                                       # 执行优化计划
balancer ls                                                                   # 列出所有计划
balancer mode none|crush-compat|upmap                                         # 设置平衡模式
balancer off                                                                  # 禁用自动平衡
balancer on                                                                   # 启用自动平衡
balancer optimize <plan> [<pools>...]                                         # 运行优化器以创建新计划
balancer pool add <pools>...                                                  # 启用特定池的自动平衡
balancer pool ls                                                              # 列出自动平衡池。请注意，空列表意味着所有现有池将作为自动平衡目标，这是平衡器的默认行为
balancer pool rm <pools>...                                                   # 禁用特定池的自动平衡
balancer reset                                                                # 丢弃所有优化计划
balancer rm <plan>                                                            # 丢弃优化计划
balancer show <plan>                                                          # 显示优化计划的详细信息
balancer status                                                               # 显示平衡器状态
```

# alert
```shell
alerts send           # 立即发送（重新发送）警报
```

# cephadm
```shell
cephadm check-host <host> [<addr>]                                            # 检查是否可以访问并管理远程主机
cephadm clear-exporter-config                                                 # 清除 cephadm 导出程序守护进程使用的 SSL 配置
cephadm clear-key                                                             # 清除集群 SSH 密钥
cephadm clear-ssh-config                                                      # 清除 ssh_config 文件
cephadm config-check disable <check_name>                                     # 禁用特定的配置检查
cephadm config-check enable <check_name>                                      # 启用特定的配置检查
cephadm config-check ls [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] # 列出可用的配置检查及其当前状态
cephadm config-check status                                                   # 显示配置检查器功能是否已启用/禁用
cephadm generate-exporter-config                                              # 生成默认的 SSL crt/key 和令牌用于 cephadm 导出程序守护进程
cephadm generate-key                                                          # 生成集群 SSH 密钥（如果不存在）
cephadm get-exporter-config                                                   # 显示当前的 cephadm-exporter 配置（JSON 格式）
cephadm get-extra-ceph-conf                                                   # 获取附加的 ceph 配置
cephadm get-pub-key                                                           # 显示用于连接集群主机的 SSH 公钥
cephadm get-ssh-config                                                        # 返回 cephadm 使用的 ssh 配置
cephadm get-user                                                              # 显示用于 SSH 连接集群主机的用户
cephadm osd activate <host>...                                                # 启动现有 OSD 的 OSD 容器
cephadm prepare-host <host> [<addr>]                                          # 为远程主机准备使用 cephadm
cephadm registry-login [<url>] [<username>] [<password>]                      # 通过提供 URL、用户名和密码或 JSON 文件来设置自定义注册表登录信息 (-i <file>)
cephadm set-exporter-config                                                   # 从 JSON 文件 (-i <file>) 设置自定义 cephadm-exporter 配置。JSON 必须包含 crt、key、token 和 port
cephadm set-extra-ceph-conf                                                   # 附加到所有守护进程的 ceph.conf 的文本。主要是一个临时解决方案，直到 `config generate-minimal-conf` 生成完整的 ceph.conf。警告：这是一个危险操作。
cephadm set-priv-key                                                          # 设置集群 SSH 私钥（使用 -i <private_key>）
cephadm set-pub-key                                                           # 设置集群 SSH 公钥（使用 -i <public_key>）
cephadm set-ssh-config                                                        # 设置 ssh_config 文件（使用 -i <ssh_config>）
cephadm set-user <user>                                                       # 设置用于 SSH 连接集群主机的用户，非 root 用户需要无密码的 sudo 权限
```

# config
```shell
config assimilate-conf                                                        # 从配置文件中汇总选项，并返回一个新的最小配置文件
config dump                                                                   # 显示所有配置选项
config generate-minimal-conf                                                  # 生成一个最小的 ceph.conf 文件
config get <who> [<key>]                                                      # 显示某个实体的配置选项
config help <key>                                                             # 描述配置选项
config log [num:int]                                                        # 显示配置更改的最近历史记录
config ls                                                                     # 列出所有可用的配置选项
config reset num:int                                                        # 将配置恢复到指定的历史版本 <num>
config rm <who> <name>                                                        # 清除一个或多个实体的配置选项
config set <who> <name> <value> [--force]                                     # 设置一个或多个实体的配置选项
config show <who> [<key>]                                                     # 显示正在运行的配置
config show-with-defaults <who>                                               # 显示正在运行的配置（包括编译时默认配置）
config-key dump [<key>]                                                       # 转储键和值（可选前缀）
config-key exists <key>                                                       # 检查 <key> 是否存在
config-key get <key>                                                          # 获取 <key> 的值
config-key ls                                                                 # 列出所有键
config-key rm <key>                                                           # 删除 <key>
config-key set <key> [<val>]                                                  # 将 <key> 设置为值 <val>
```

# crash
```shell
crash archive <id>                                                            # 确认一个崩溃并静默健康警告
crash archive-all                                                             # 确认所有新崩溃并静默健康警告
crash info <id>                                                               # 显示崩溃转储元数据
crash json_report <hours>                                                     # 显示过去 <hours> 小时内的崩溃
crash ls                                                                      # 显示新的和已归档的崩溃转储
crash ls-new                                                                  # 显示新的崩溃转储
crash post                                                                    # 添加一个崩溃转储 (使用 -i <jsonfile>)
crash prune <keep>                                                            # 删除保留超过 <keep> 天的崩溃记录
crash rm <id>                                                                 # 删除一个已保存的崩溃 <id>
crash stat                                                                    # 汇总记录的崩溃
```

# dashboard
```shell
dashboard ac-role-add-scope-perms <rolename> <scopename> [<permissions>...]   # 为角色添加作用域权限
dashboard ac-role-create [<rolename>] [<description>]                         # 创建一个新的访问控制角色
dashboard ac-role-del-scope-perms <rolename> [<scopename>]                    # 删除角色的作用域权限
dashboard ac-role-delete [<rolename>]                                         # 删除访问控制角色
dashboard ac-role-show [<rolename>]                                           # 显示角色信息
dashboard ac-user-add-roles <username> [<roles>...]                           # 向用户添加角色
dashboard ac-user-create <username> [<rolename>] [<name>] [<email>] [--enabled] [--force-password] [<pwd_expiration_date:int>] [--pwd-update-required]           
# 创建用户。密码从 -i <file> 读取                                                         
dashboard ac-user-del-roles <username> [<roles>...]                           # 从用户删除角色
dashboard ac-user-delete [<username>]                                         # 删除用户
dashboard ac-user-disable [<username>]                                        # 禁用用户
dashboard ac-user-enable [<username>]                                         # 启用用户
dashboard ac-user-set-info <username> <name> [<email>]                        # 设置用户信息
dashboard ac-user-set-password <username> [--force-password]                  # 从 -i <file> 设置用户密码
dashboard ac-user-set-password-hash <username>                                # 从 -i <file> 设置用户密码 bcrypt 哈希
dashboard ac-user-set-roles <username> [<roles>...]                           # 设置用户角色
dashboard ac-user-show [<username>]                                           # 显示用户信息
dashboard create-self-signed-cert                                             # 创建自签名证书
dashboard debug [enable|disable|status]                                       # 控制并报告 Ceph-Dashboard 中的调试状态
dashboard feature [enable|disable|status] [rbd|mirroring|iscsi|cephfs|rgw|nfs...]     # 启用或禁用 Ceph-Mgr Dashboard 中的功能
dashboard get-account-lockout-attempts                                        # 获取 ACCOUNT_LOCKOUT_ATTEMPTS 配置项的值
dashboard get-alertmanager-api-host                                           # 获取 ALERTMANAGER_API_HOST 配置项的值
dashboard get-alertmanager-api-ssl-verify                                     # 获取 ALERTMANAGER_API_SSL_VERIFY 配置项的值
dashboard get-audit-api-enabled                                               # 获取 AUDIT_API_ENABLED 配置项的值
dashboard get-audit-api-log-payload                                           # 获取 AUDIT_API_LOG_PAYLOAD 配置项的值
dashboard get-enable-browsable-api                                            # 获取 ENABLE_BROWSABLE_API 配置项的值
dashboard get-ganesha-clusters-rados-pool-namespace                           # 获取 GANESHA_CLUSTERS_RADOS_POOL_NAMESPACE 配置项的值
dashboard get-grafana-api-password                                            # 获取 GRAFANA_API_PASSWORD 配置项的值
dashboard get-grafana-api-ssl-verify                                          # 获取 GRAFANA_API_SSL_VERIFY 配置项的值
dashboard get-grafana-api-url                                                 # 获取 GRAFANA_API_URL 配置项的值
dashboard get-grafana-api-username                                            # 获取 GRAFANA_API_USERNAME 配置项的值
dashboard get-grafana-frontend-api-url                                        # 获取 GRAFANA_FRONTEND_API_URL 选项值
dashboard get-grafana-update-dashboards                                       # 获取 GRAFANA_UPDATE_DASHBOARDS 选项值
dashboard get-iscsi-api-ssl-verification                                      # 获取 ISCSI_API_SSL_VERIFICATION 选项值
dashboard get-jwt-token-ttl                                                   # 获取 JWT token 的 TTL（生存时间）值，以秒为单位
dashboard get-login-banner                                                    # 获取自定义登录横幅文本
dashboard get-prometheus-api-host                                             # 获取 PROMETHEUS_API_HOST 选项值
dashboard get-prometheus-api-ssl-verify                                       # 获取 PROMETHEUS_API_SSL_VERIFY 选项值
dashboard get-pwd-policy-check-complexity-enabled                             # 获取 PWD_POLICY_CHECK_COMPLEXITY_ENABLED 选项值
dashboard get-pwd-policy-check-exclusion-list-enabled                         # 获取 PWD_POLICY_CHECK_EXCLUSION_LIST_ENABLED 选项值
dashboard get-pwd-policy-check-length-enabled                                 # 获取 PWD_POLICY_CHECK_LENGTH_ENABLED 选项值
dashboard get-pwd-policy-check-oldpwd-enabled                                 # 获取 PWD_POLICY_CHECK_OLDPWD_ENABLED 选项值
dashboard get-pwd-policy-check-repetitive-chars-enabled                       # 获取 PWD_POLICY_CHECK_REPETITIVE_CHARS_ENABLED 选项值
dashboard get-pwd-policy-check-sequential-chars-enabled                       # 获取 PWD_POLICY_CHECK_SEQUENTIAL_CHARS_ENABLED 选项值
dashboard get-pwd-policy-check-username-enabled                               # 获取 PWD_POLICY_CHECK_USERNAME_ENABLED 选项值
dashboard get-pwd-policy-enabled                                              # 获取 PWD_POLICY_ENABLED 选项值
dashboard get-pwd-policy-exclusion-list                                       # 获取 PWD_POLICY_EXCLUSION_LIST 选项值
dashboard get-pwd-policy-min-complexity                                       # 获取 PWD_POLICY_MIN_COMPLEXITY 选项值
dashboard get-pwd-policy-min-length                                           # 获取 PWD_POLICY_MIN_LENGTH 选项值
dashboard get-rest-requests-timeout                                           # 获取 REST_REQUESTS_TIMEOUT 选项值
dashboard get-rgw-api-access-key                                              # 获取 RGW_API_ACCESS_KEY 选项值
dashboard get-rgw-api-admin-resource                                          # 获取 RGW_API_ADMIN_RESOURCE 选项值
dashboard get-rgw-api-secret-key                                              # 获取 RGW_API_SECRET_KEY 选项值
dashboard get-rgw-api-ssl-verify                                              # 获取 RGW_API_SSL_VERIFY 选项值
dashboard get-user-pwd-expiration-span                                        # 获取 USER_PWD_EXPIRATION_SPAN 选项值
dashboard get-user-pwd-expiration-warning-1                                   # 获取USER_PWD_EXPIRATION_WARNING_1 选项值
dashboard get-user-pwd-expiration-warning-2                                   # 获取 USER_PWD_EXPIRATION_WARNING_2 选项值
dashboard grafana dashboards update                                           # 推送仪表板到 Grafana
dashboard iscsi-gateway-add [<name>]                                          # 添加 iSCSI 网关配置。网关 URL 通过 -i <file> 参数读取
dashboard iscsi-gateway-list                                                  # 列出 iSCSI 网关
dashboard iscsi-gateway-rm [<name>]                                           # 移除 iSCSI 网关配置
dashboard reset-account-lockout-attempts                                      # 将 ACCOUNT_LOCKOUT_ATTEMPTS 选项重置为默认值
dashboard reset-alertmanager-api-host                                         # 将 ALERTMANAGER_API_HOST 选项重置为默认值
dashboard reset-alertmanager-api-ssl-verify                                   # 将 ALERTMANAGER_API_SSL_VERIFY 选项重置为默认值
dashboard reset-audit-api-enabled                                             # 将 AUDIT_API_ENABLED 选项重置为默认值
dashboard reset-audit-api-log-payload                                         # 将 AUDIT_API_LOG_PAYLOAD 选项重置为默认值
dashboard reset-enable-browsable-api                                          # 重置 ENABLE_BROWSABLE_API 选项为默认值
dashboard reset-ganesha-clusters-rados-pool-namespace                         # 重置 GANESHA_CLUSTERS_RADOS_POOL_NAMESPACE 选项为默认值
dashboard reset-grafana-api-password                                          # 重置 GRAFANA_API_PASSWORD 选项为默认值
dashboard reset-grafana-api-ssl-verify                                        # 重置 GRAFANA_API_SSL_VERIFY 选项为默认值
dashboard reset-grafana-api-url                                               # 重置 GRAFANA_API_URL 选项为默认值
dashboard reset-grafana-api-username                                          # 重置 GRAFANA_API_USERNAME 选项为默认值
dashboard reset-grafana-frontend-api-url                                      # 重置 GRAFANA_FRONTEND_API_URL 选项为默认值
dashboard reset-grafana-update-dashboards                                     # 重置 GRAFANA_UPDATE_DASHBOARDS 选项为默认值
dashboard reset-iscsi-api-ssl-verification                                    # 重置 ISCSI_API_SSL_VERIFICATION 选项为默认值
dashboard reset-prometheus-api-host                                           # 重置 PROMETHEUS_API_HOST 选项为默认值
dashboard reset-prometheus-api-ssl-verify                                     # 重置 PROMETHEUS_API_SSL_VERIFY 选项为默认值
dashboard reset-pwd-policy-check-complexity-enabled                           # 重置 PWD_POLICY_CHECK_COMPLEXITY_ENABLED 选项为默认值
dashboard reset-pwd-policy-check-exclusion-list-enabled                       # 重置 PWD_POLICY_CHECK_EXCLUSION_LIST_ENABLED 选项为默认值
dashboard reset-pwd-policy-check-length-enabled                               # 重置 PWD_POLICY_CHECK_LENGTH_ENABLED 选项为默认值
dashboard reset-pwd-policy-check-oldpwd-enabled                               # 重置 PWD_POLICY_CHECK_OLDPWD_ENABLED 选项为默认值
dashboard reset-pwd-policy-check-repetitive-chars-enabled                     # 重置 PWD_POLICY_CHECK_REPETITIVE_CHARS_ENABLED 选项为默认值
dashboard reset-pwd-policy-check-sequential-chars-enabled                     # 重置 PWD_POLICY_CHECK_SEQUENTIAL_CHARS_ENABLED 选项为默认值
dashboard reset-pwd-policy-check-username-enabled                             # 重置 PWD_POLICY_CHECK_USERNAME_ENABLED 选项为默认值
dashboard reset-pwd-policy-enabled                                            # 重置 PWD_POLICY_ENABLED 选项为默认值
dashboard reset-pwd-policy-exclusion-list                                     # 重置 PWD_POLICY_EXCLUSION_LIST 选项为默认值
dashboard reset-pwd-policy-min-complexity                                     # 重置 PWD_POLICY_MIN_COMPLEXITY 选项为默认值
dashboard reset-pwd-policy-min-length                                         # 重置 PWD_POLICY_MIN_LENGTH 选项为默认值
dashboard reset-rest-requests-timeout                                         # 重置 REST_REQUESTS_TIMEOUT 选项为默认值
dashboard reset-rgw-api-access-key                                            # 重置 RGW_API_ACCESS_KEY 选项为默认值
dashboard reset-rgw-api-admin-resource                                        # 重置 RGW_API_ADMIN_RESOURCE 选项为默认值
dashboard reset-rgw-api-secret-key                                            # 重置 RGW_API_SECRET_KEY 选项为默认值
dashboard reset-rgw-api-ssl-verify                                            # 重置 RGW_API_SSL_VERIFY 选项为默认值
dashboard reset-user-pwd-expiration-span                                      # 重置 USER_PWD_EXPIRATION_SPAN 选项为默认值
dashboard reset-user-pwd-expiration-warning-1                                 # 重置 USER_PWD_EXPIRATION_WARNING_1 选项为默认值
dashboard reset-user-pwd-expiration-warning-2                                 # 重置 USER_PWD_EXPIRATION_WARNING_2 选项为默认值
dashboard set-account-lockout-attempts <value>                                # 设置 ACCOUNT_LOCKOUT_ATTEMPTS 选项的值
dashboard set-alertmanager-api-host <value>                                   # 设置 ALERTMANAGER_API_HOST 选项的值
dashboard set-alertmanager-api-ssl-verify <value>                             # 设置 ALERTMANAGER_API_SSL_VERIFY 选项的值
dashboard set-audit-api-enabled <value>                                       # 设置 AUDIT_API_ENABLED 选项的值
dashboard set-audit-api-log-payload <value>                                   # 设置 AUDIT_API_LOG_PAYLOAD 选项的值
dashboard set-enable-browsable-api <value>                                    # 设置 ENABLE_BROWSABLE_API 选项的值
dashboard set-ganesha-clusters-rados-pool-namespace <value>                   # 设置 GANESHA_CLUSTERS_RADOS_POOL_NAMESPACE 选项的值
dashboard set-grafana-api-password                                            # 设置 GRAFANA_API_PASSWORD 选项的值，从 -i <file> 中读取
dashboard set-grafana-api-ssl-verify <value>                                  # 设置 GRAFANA_API_SSL_VERIFY 选项的值
dashboard set-grafana-api-url <value>                                         # 设置 GRAFANA_API_URL 选项的值
dashboard set-grafana-api-username <value>                                    # 设置 GRAFANA_API_USERNAME 选项的值
dashboard set-grafana-frontend-api-url <value>                                # 设置 GRAFANA_FRONTEND_API_URL 选项的值
dashboard set-grafana-update-dashboards <value>                               # 设置 GRAFANA_UPDATE_DASHBOARDS 选项的值
dashboard set-iscsi-api-ssl-verification <value>                              # 设置 ISCSI_API_SSL_VERIFICATION 选项的值
dashboard set-jwt-token-ttl <seconds:int>                                     # 设置 JWT 令牌的有效时间（秒）
dashboard set-login-banner                                                    # 设置自定义登录横幅，从 -i <file> 中读取
dashboard set-login-credentials <username>                                    # 设置登录凭证，密码从 -i <file> 中读取
dashboard set-prometheus-api-host <value>                                     # 设置 PROMETHEUS_API_HOST 选项的值
dashboard set-prometheus-api-ssl-verify <value>                               # 设置 PROMETHEUS_API_SSL_VERIFY 选项的值
dashboard set-pwd-policy-check-complexity-enabled <value>                     # 设置 PWD_POLICY_CHECK_COMPLEXITY_ENABLED 选项的值
dashboard set-pwd-policy-check-exclusion-list-enabled <value>                 # 设置 PWD_POLICY_CHECK_EXCLUSION_LIST_ENABLED 选项的值
dashboard set-pwd-policy-check-length-enabled <value>                         # 设置 PWD_POLICY_CHECK_LENGTH_ENABLED 选项的值
dashboard set-pwd-policy-check-oldpwd-enabled <value>                         # 设置 PWD_POLICY_CHECK_OLDPWD_ENABLED 选项的值
dashboard set-pwd-policy-check-repetitive-chars-enabled <value>               # 设置 PWD_POLICY_CHECK_REPETITIVE_CHARS_ENABLED 选项的值
dashboard set-pwd-policy-check-sequential-chars-enabled <value>               # 设置 PWD_POLICY_CHECK_SEQUENTIAL_CHARS_ENABLED 选项的值
dashboard set-pwd-policy-check-username-enabled <value>                       # 设置 PWD_POLICY_CHECK_USERNAME_ENABLED 选项的值
dashboard set-pwd-policy-enabled <value>                                      # 设置 PWD_POLICY_ENABLED 选项的值
dashboard set-pwd-policy-exclusion-list <value>                               # 设置 PWD_POLICY_EXCLUSION_LIST 选项的值
dashboard set-pwd-policy-min-complexity <value>                               # 设置 PWD_POLICY_MIN_COMPLEXITY 选项的值
dashboard set-pwd-policy-min-length <value>                                   # 设置 PWD_POLICY_MIN_LENGTH 选项的值
dashboard set-rest-requests-timeout <value>                                   # 设置 REST_REQUESTS_TIMEOUT 选项的值
dashboard set-rgw-api-access-key                                              # 设置 RGW_API_ACCESS_KEY 选项的值，从 -i <file> 中读取
dashboard set-rgw-api-admin-resource <value>                                  # 设置 RGW_API_ADMIN_RESOURCE 选项的值
dashboard set-rgw-api-secret-key                                              # 设置 RGW_API_SECRET_KEY 选项的值，从 -i <file> 中读取
dashboard set-rgw-api-ssl-verify <value>                                      # 设置 RGW_API_SSL_VERIFY 选项的值
dashboard set-user-pwd-expiration-span <value>                                # 设置 USER_PWD_EXPIRATION_SPAN 选项的值
dashboard set-user-pwd-expiration-warning-1 <value>                           # 设置 USER_PWD_EXPIRATION_WARNING_1 选项的值
dashboard set-user-pwd-expiration-warning-2 <value>                           # 设置 USER_PWD_EXPIRATION_WARNING_2 选项的值
dashboard sso disable                                                         # 禁用单点登录
dashboard sso enable saml2                                                    # 启用 SAML2 单点登录
dashboard sso setup saml2 <ceph_dashboard_base_url> <idp_metadata> [<idp_username_attribute>] [<idp_entity_id>] [<sp_x_509_cert>] [<sp_private_key>]      # 设置 SAML2 单点登录
dashboard sso show saml2                                                      # 显示 SAML2 配置
dashboard sso status                                                          # 获取单点登录状态
dashboard unset-login-banner                                                  # 移除自定义登录横幅
```

# device
```shell
device check-health                                 # 检查设备的使用寿命
device get-health-metrics <devid> [<sample>]           # 显示设备存储的健康指标
device info <devid>                                                        # 显示设备信息
device light on|off <devid> [ident|fault] [--force]          # 开启或关闭设备指示灯。默认类型为ident  用法: device  light (on|off) <devid> [ident|fault] [--force]
device ls                                                                     # 显示设备列表
device ls-by-daemon <who>                                    # 显示与某个守护进程关联的设备
device ls-by-host <host>                                          # 显示主机上的设备
device ls-lights                                                          # 列出当前活动的设备指示灯
device monitoring off                                                # 禁用设备健康监控
device monitoring on                                                # 启用设备健康监控
device predict-life-expectancy <devid>                    # 预测设备的使用寿命
device query-daemon-health-metrics <who>          # 获取某个守护进程的设备健康指标
device rm-life-expectancy <devid>                          # 清除预测的设备使用寿命
device scrape-daemon-health-metrics <who>         # 抓取并存储某个守护进程的设备健康指标
device scrape-health-metrics [<devid>]                   # 抓取并存储设备健康指标
device set-life-expectancy <devid> <from> [<to>]       # 设置预测的设备使用寿命
```

# fs 
```shell
fs add_data_pool <fs_name> <pool>                                             # 添加数据池 <pool>
fs authorize <filesystem> <entity> <caps>...                                  # 为 <entity> 添加访问文件系统 <filesystem> 的授权，并指定以下目录和权限对
fs clone cancel <vol_name> <clone_name> [<group_name>]                        # 取消正在进行或待处理的克隆操作
fs clone status <vol_name> <clone_name> [<group_name>]                        # 获取克隆子卷的状态
fs compat <fs_name> rm_compat|rm_incompat|add_compat|add_incompat <feature:int> [<feature_str>]  # 操作兼容性设置
fs compat show <fs_name>                                                      # 显示文件系统的兼容性设置
fs dump [<epoch:int>]                                                         # 转储所有 CephFS 状态，可选从指定的 epoch 开始
fs fail <fs_name>                                                             # 使文件系统及其所有排名的 MDS 失败
fs feature ls                                                                 # 列出可设置/取消的 CephFS 功能
fs flag set enable_multiple <val> [--yes-i-really-mean-it]                    # 设置全局 CephFS 标志
fs get <fs_name>                                                              # 获取某个文件系统的信息
fs ls                                                                         # 列出文件系统
fs mirror disable <fs_name>                                                   # 禁用 Ceph 文件系统的镜像功能
fs mirror enable <fs_name>                                                    # 启用 Ceph 文件系统的镜像功能
fs mirror peer_add <fs_name> <uuid> <remote_cluster_spec> <remote_fs_name>    # 为 Ceph 文件系统添加一个镜像对等体
fs mirror peer_remove <fs_name> <uuid>                                        # 从 Ceph 文件系统中移除一个镜像对等体
fs new <fs_name> <metadata> <data> [--force] [--allow-dangerous-metadata-overlay] [<fscid:int>] [--recover]     # 使用指定的元数据池和数据池创建一个新文件系统
fs perf stats [<mds_rank>] [<client_id>] [<client_ip>]                        # 检索 Ceph FS 性能统计信息
fs required_client_features <fs_name> add|rm <val>                            # 添加/移除客户端所需的功能
fs reset <fs_name> [--yes-i-really-mean-it]                                   # 仅限灾难恢复：重置为单个 MDS 映射
fs rm <fs_name> [--yes-i-really-mean-it]                                      # 禁用指定的文件系统
fs rm_data_pool <fs_name> <pool>                                              # 移除数据池 <pool>
fs set <fs_name> max_mds|max_file_size|allow_new_snaps|inline_data|cluster_down|allow_dirfrags|balancer|standby_count_wanted|session_timeout|session_autoclose|allow_standby_replay|down|joinable|min_compat_client <val> [--yes-i-really-mean-it] [--yes-i-really-really-mean-it]   # 设置文件系统参数 <var> 的值为 <val>
fs set-default <fs_name>                                                      # 将指定文件系统设置为默认
fs snap-schedule activate <path> [<repeat>] [<start>] [<fs>]                  # 激活 <path> 的快照计划
fs snap-schedule add <path> [<snap_schedule>] [<start>] [<fs>]                # 为 <path> 设置快照计划
fs snap-schedule deactivate <path> [<repeat>] [<start>] [<fs>]                # 停用 <path> 的快照计划
fs snap-schedule list [<path>] [--recursive] [<fs>] [<format>]                # 获取 <path> 当前的快照计划
fs snap-schedule remove <path> [<repeat>] [<start>] [<fs>]                    # 移除 <path> 的快照计划
fs snap-schedule retention add <path> <retention_spec_or_period> [<retention_count>] [<fs>]  # 为 <path> 设置保留规格
fs snap-schedule retention remove <path> <retention_spec_or_period> [<retention_count>] [<fs>]           # 移除 <path> 的保留规格
fs snap-schedule status [<path>] [<fs>] [<format>]                            # 列出当前的快照调度
fs snapshot mirror add <fs_name> [<path>]                                     # 添加一个目录用于快照镜像
fs snapshot mirror daemon status                                              # 获取镜像守护进程状态
fs snapshot mirror dirmap <fs_name> [<path>]                                  # 获取目录的当前镜像实例映射
fs snapshot mirror disable [<fs_name>]                                        # 禁用文件系统的快照镜像
fs snapshot mirror enable [<fs_name>]                                         # 启用文件系统的快照镜像
fs snapshot mirror peer_add <fs_name> [<remote_cluster_spec>] [<remote_fs_name>] [<remote_mon_host>] [<cephx_key>]    # 添加远程文件系统对等端
fs snapshot mirror peer_bootstrap create <fs_name> <client_name> [<site_name>]      # 引导文件系统对等端
fs snapshot mirror peer_bootstrap import <fs_name> [<token>]                  # 导入引导令牌
fs snapshot mirror peer_list [<fs_name>]                                      # 列出文件系统的已配置对等端
fs snapshot mirror peer_remove <fs_name> [<peer_uuid>]                        # 移除文件系统的对等端
fs snapshot mirror remove <fs_name> [<path>]                                  # 移除一个快照镜像目录
fs snapshot mirror show distribution [<fs_name>]                              # 获取文件系统的当前实例到目录映射
fs status [<fs>]                                                              # 显示 CephFS 文件系统的状态
fs subvolume authorize <vol_name> <sub_name> <auth_id> [<group_name>] [<access_level>] [<tenant_id>] [--allow-existing-id]        # 允许 cephx 认证 ID 访问子卷
fs subvolume authorized_list <vol_name> <sub_name> [<group_name>]             # 列出有权访问子卷的认证 ID
fs subvolume create <vol_name> <sub_name> [<size:int>] [<group_name>] [<pool_layout>] [<uid:int>] [<gid:int>] [<mode>] [--namespace-isolated] # 在卷中创建 CephFS 子卷，并可以选择指定大小（以字节为单位）、数据池布局、模式、特定子卷组和 RADOS 命名空间
fs subvolume deauthorize <vol_name> <sub_name> <auth_id> [<group_name>]       # 拒绝 cephx 认证 ID 访问子卷
fs subvolume evict <vol_name> <sub_name> <auth_id> [<group_name>]             # 基于认证 ID 和子卷挂载情况驱逐客户端
fs subvolume exist <vol_name> [<group_name>]                                  # 检查卷中是否存在子卷，可选指定子卷组
fs subvolume getpath <vol_name> <sub_name> [<group_name>]                     # 获取 CephFS 子卷的挂载路径，并可选指定子卷组
fs subvolume info <vol_name> <sub_name> [<group_name>]                        # 获取 CephFS 子卷的信息，并可选指定子卷组
fs subvolume ls <vol_name> [<group_name>]                                     # 列出子卷
fs subvolume metadata get <vol_name> <sub_name> <key_name> [<group_name>]     # 获取与 CephFS 子卷关联的自定义元数据的键值，并可选指定子卷组
fs subvolume metadata ls <vol_name> <sub_name> [<group_name>]                 # 列出 CephFS 子卷的自定义元数据（键值对），并可选指定子卷组
fs subvolume metadata rm <vol_name> <sub_name> <key_name> [<group_name>] [--force]  # 移除 CephFS 子卷的自定义元数据（键值对），并可选指定子卷组
fs subvolume metadata set <vol_name> <sub_name> <key_name> <value> [<group_name>]   # 为 CephFS 子卷设置自定义元数据（键值对），并可选指定子卷组
fs subvolume pin <vol_name> <sub_name> export|distributed|random <pin_setting> [<group_name>]        # 为子卷设置 MDS 固定策略
fs subvolume resize <vol_name> <sub_name> <new_size> [<group_name>] [--no-shrink]    # 调整 CephFS 子卷的大小
fs subvolume rm <vol_name> <sub_name> [<group_name>] [--force] [--retain-snapshots]     # 删除 CephFS 子卷，并可选指定子卷组，强制删除已取消或失败的克隆，并保留现有子卷快照
fs subvolume snapshot clone <vol_name> <sub_name> <snap_name> <target_sub_name> [<pool_layout>] [<group_name>] [<target_group_name>]    # 克隆一个快照到目标子卷
fs subvolume snapshot create <vol_name> <sub_name> <snap_name> [<group_name>] # 创建 CephFS 子卷的快照，并可选指定子卷组
fs subvolume snapshot info <vol_name> <sub_name> <snap_name> [<group_name>]   # 获取 CephFS 子卷快照的信息，并可选指定子卷组
fs subvolume snapshot ls <vol_name> <sub_name> [<group_name>]                 # 列出子卷快照
fs subvolume snapshot metadata get <vol_name> <sub_name> <snap_name> <key_name> [<group_name>]    # 获取与 CephFS 子卷快照关联的自定义元数据的键值，并可选指定子卷组
fs subvolume snapshot metadata ls <vol_name> <sub_name> <snap_name> [<group_name>]  # 列出 CephFS 子卷快照的自定义元数据（键值对），并可选指定子卷组
fs subvolume snapshot metadata rm <vol_name> <sub_name> <snap_name> <key_name> [<group_name>] [--force]    # 移除 CephFS 子卷快照的自定义元数据（键值对），并可选指定子卷组
fs subvolume snapshot metadata set <vol_name> <sub_name> <snap_name> <key_name> <value> [<group_name>]    # 为 CephFS 子卷快照设置自定义元数据（键值对），并可选指定子卷组
fs subvolume snapshot protect <vol_name> <sub_name> <snap_name> [<group_name>]      # （已弃用）保护 CephFS 子卷快照，并可选指定子卷组
fs subvolume snapshot rm <vol_name> <sub_name> <snap_name> [<group_name>] [--force] # 删除 CephFS 子卷的快照，并可选指定子卷组
fs subvolume snapshot unprotect <vol_name> <sub_name> <snap_name> [<group_name>]    # （已弃用）取消保护 CephFS 子卷快照，并可选指定子卷组
fs subvolumegroup create <vol_name> <group_name> [<size:int>] [<pool_layout>] [<uid:int>] [<gid:int>] [<mode>]         # 在卷中创建 CephFS 子卷组，并可以选择指定大小（以字节为单位）、数据池布局、特定模式
fs subvolumegroup exist <vol_name>                                            # 检查卷中是否存在子卷组
fs subvolumegroup getpath <vol_name> <group_name>                             # 获取 CephFS 子卷组的挂载路径
fs subvolumegroup info <vol_name> <group_name>                                # 获取 CephFS 子卷组的信息
fs subvolumegroup ls <vol_name>                                               # 列出子卷组
fs subvolumegroup pin <vol_name> <group_name> export|distributed|random <pin_setting>  # 为子卷组设置 MDS 固定策略
fs subvolumegroup resize <vol_name> <group_name> <new_size> [--no-shrink]     # 调整 CephFS 子卷组的大小
fs subvolumegroup rm <vol_name> <group_name> [--force]                        # 删除 CephFS 子卷组
fs subvolumegroup snapshot create <vol_name> <group_name> <snap_name>         # 创建 CephFS 子卷组的快照
fs subvolumegroup snapshot ls <vol_name> <group_name>                         # 列出子卷组快照
fs subvolumegroup snapshot rm <vol_name> <group_name> <snap_name> [--force]   # 删除 CephFS 子卷组的快照
fs volume create <name> [<placement>]                                         # 创建 CephFS 卷
fs volume info <vol_name> [--human-readable]                                  # 获取 CephFS 卷的信息
fs volume ls                                                                  # 列出卷
fs volume rm <vol_name> [<yes-i-really-mean-it>]                              # 删除一个文件系统卷，需传入 --yes-i-really-mean-it 标志
fsid                                                                          # 显示集群 FSID/UUID
```

# health
```shell
health [detail]  # 获取健康状态的详细信息
show cluster health  # 显示集群健康状态
health mute <code> [<ttl>] [--sticky]  # 静音健康警报
# <code> 指定警报代码，<ttl> 是可选的超时时间，--sticky 表示将其设置为持续静音
health unmute [<code>]  # 取消静音已有的健康警报
# <code> 可选，指定要取消静音的警报代码
healthcheck history clear  # 清除健康检查历史记录
healthcheck history ls [--format {plain|json|json-pretty|yaml}]  # 列出所有被跟踪的健康检查
# format (Format, optional): 输出格式，默认为 Format.plain。
# 返回: HandleCommandResult: 返回代码、标准输出和标准错误返回给调用者。
```

# influx
```shell
influx config-set <key> <value>  # 设置配置值
influx config-show  # 显示当前配置
influx send  # 强制发送数据到 Influx
```

# k8sevents

```shell
k8sevents ceph  # 列出 Ceph 事件并将其发送到 Kubernetes 集群
k8sevents clear-config  # 清除外部 Kubernetes 配置设置
k8sevents ls  # 列出 Ceph 命名空间中的所有当前 Kubernetes 事件
k8sevents set-access <key>  # 设置 Kubernetes 访问凭证。<key> 必须是 cacrt 或 token，并使用 -i <filename> 语法
# (例如，ceph k8sevents set-access cacrt -i /root/ca.crt)
k8sevents set-config <key> <value>  # 设置 Kubernetes 配置参数。<key> 必须是 server 或 namespace
# (例如，ceph k8sevents set-config server https://localhost:30433)
k8sevents status  # 显示数据收集线程的状态
```

# log

```shell
log <logtext>...  # 将提供的文本记录到监控日志
log last [<num:int>] [debug|info|sec|warn|error] [*|cluster|audit|cephadm]  # 打印集群日志的最后几行
# <num:int> 指定要显示的行数，debug|info|sec|warn|error 指定日志级别，
# *|cluster|audit|cephadm 指定日志的类型（例如，集群日志、审计日志等）
```

# mds
```shell
mds count-metadata <property>  # 按元数据字段属性统计 MDS
mds fail <role_or_gid>  # 标记 MDS 失败：如果有备用，则触发故障转移
mds metadata [<who>]  # 获取指定 MDS 角色的元数据
mds ok-to-stop <ids>...  # 检查停止指定 MDS 是否会减少即时可用性
mds repaired <role>  # 标记损坏的 MDS 排名不再损坏
mds rm <gid:int>  # 删除非活动的 MDS
mds versions  # 检查正在运行的 MDS 版本
```


# mgr
```shell
mgr count-metadata <property>  # 按元数据字段属性统计 ceph-mgr 守护进程
mgr dump [<epoch:int>]  # 转储最新的 MgrMap
mgr fail [<who>]  # 将指定的管理器守护进程标记为失败
mgr metadata [<who>]  # 转储所有守护进程或指定守护进程的元数据
mgr module disable <module>  # 禁用 mgr 模块
mgr module enable <module> [--force]  # 启用 mgr 模块
mgr module ls  # 列出活动的 mgr 模块
mgr self-test background start <workload>  # 激活后台工作负载（例如 command_spam，throw_exception）
mgr self-test background stop  # 停止后台工作负载（如果有正在运行）
mgr self-test cluster-log <channel> <priority> <message>  # 创建审计日志记录
mgr self-test config get <key>  # 查看配置值
mgr self-test config get_localized <key>  # 查看本地化配置值
mgr self-test health clear [<checks>...]  # 清除健康检查，提供名称时清除指定检查，未提供名称时清除所有
mgr self-test health set <checks>  # 从 JSON 格式的描述中设置健康检查
mgr self-test insights_set_now_offset <hours>  # 设置 insights 模块的当前时间偏移量
mgr self-test module <module>  # 运行其他模块的 self_test() 方法
mgr self-test python-version  # 查询嵌入式 Python 运行时版本
mgr self-test remote  # 测试模块间调用
mgr self-test run  # 运行 mgr Python 接口测试
mgr services  # 列出 mgr 模块提供的服务端点
mgr stat  # 转储有关 mgr 集群状态的基本信息
mgr versions  # 检查正在运行的 ceph-mgr 守护进程版本
```

# mon
```shell
mon add <name> <addr> [<location>...]                                         # 在 <addr> 上添加一个名为 <name> 的新监视器，可能包括 CRUSH 位置 <location>
mon add disallowed_leader <name>                                              # 阻止指定的监视器成为 leader
mon count-metadata <property>                                                 # 按元数据字段 <property> 统计监视器数量
mon dump [<epoch:int>]                                                        # 转储格式化的 monmap（可选地来自某个 epoch）
mon enable-msgr2                                                              # 启用 msgr2 协议，端口为 3300
mon enable_stretch_mode <tiebreaker_mon> <new_crush_rule> <dividing_bucket>   # 启用 stretch 模式，改变所有池的对等规则和故障处理，将 <tiebreaker_mon> 作为决胜监视器，并设置 <dividing_bucket> 位置为跨区伸展的单位
mon feature ls [--with-value]                                                 # 列出可设置/取消设置的可用 monmap 特性
mon feature set <feature_name> [--yes-i-really-mean-it]                       # 设置 monmap 的特性
mon getmap [<epoch:int>]                                                      # 获取 monmap
mon metadata [<id>]                                                           # 获取指定监视器 <id> 的元数据
mon ok-to-add-offline                                                         # 检查是否可以添加一个离线的监视器，而不会破坏法定人数
mon ok-to-rm <id>                                                             # 检查是否可以移除指定的监视器，而不会破坏法定人数
mon ok-to-stop <ids>...                                                       # 检查是否可以安全停止指定的监视器而不降低即时可用性
mon rm <name>                                                                 # 移除名为 <name> 的监视器
mon rm disallowed_leader <name>                                               # 允许指定的监视器再次成为 leader
mon scrub                                                                     # 清理监视器存储
mon set election_strategy <strategy>                                          # 设置选举策略；可选策略：classic, disallow, connectivity
mon set-addrs <name> <addrs>                                                  # 设置指定监视器绑定的地址（IP 和端口）
mon set-rank <name> <rank:int>                                                # 设置指定监视器的排名
mon set-weight <name> <weight:int>                                            # 设置指定监视器的权重
mon set_location <name> <args>...                                             # 为指定的监视器 <name> 指定 CRUSH 桶名称作为位置 <args>
mon set_new_tiebreaker <name> [--yes-i-really-mean-it]                        # 将 stretch 决胜监视器切换为指定的监视器 <name>
mon stat                                                                      # 汇总监视器状态
mon versions                                                                  # 检查监视器的运行版本
```

# nfs
```shell
nfs cluster config get <cluster_id>                                           # 获取 NFS-Ganesha 配置
nfs cluster config reset <cluster_id>                                         # 重置 NFS-Ganesha 配置为默认设置
nfs cluster config set <cluster_id>                                           # 通过 `-i <config_file>` 设置 NFS-Ganesha 配置
nfs cluster create <cluster_id> [<placement>] [--ingress] [<virtual_ip>]      # 创建一个 NFS 集群
[<port:int>]                                                                 # （可选）指定端口
nfs cluster delete <cluster_id>                                               # 移除 NFS 集群（已弃用）
nfs cluster info [<cluster_id>]                                               # 显示 NFS 集群信息
nfs cluster ls                                                                # 列出所有 NFS 集群
nfs cluster rm <cluster_id>                                                   # 移除 NFS 集群
nfs export apply <cluster_id>                                                 # 通过 `-i <json_or_ganesha_export_file>` 创建或更新导出
nfs export create cephfs <cluster_id> <pseudo_path> <fsname> [<path>] [--readonly] [<client_addr>...] [<squash>]     # 创建 CephFS 导出
nfs export create rgw <cluster_id> <pseudo_path> [<bucket>] [<user_id>] [--readonly] [<client_addr>...] [<squash>]   # 创建 RGW 导出
nfs export delete <cluster_id> <pseudo_path>                                  # 删除 CephFS 导出（已弃用）
nfs export get <cluster_id> <pseudo_path>                                     # 获取 NFS 集群中给定伪路径/绑定的导出（已弃用）
nfs export info <cluster_id> <pseudo_path>                                    # 获取 NFS 集群中给定伪路径/绑定的导出信息
nfs export ls <cluster_id> [--detailed]                                       # 列出 NFS 集群的所有导出
nfs export rm <cluster_id> <pseudo_path>                                      # 移除 CephFS 导出
```

# orch
```shell
orch apply [mon|mgr|rbd-mirror|cephfs-mirror|crash|alertmanager|grafana|node-exporter|prometheus|mds|rgw|nfs|iscsi|cephadm-exporter|snmp-gateway] [<placement>] [--dry-run] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--unmanaged] [--no-overwrite]                                         # 更新服务的大小或放置，或者应用大规模的yaml配置文件
orch apply iscsi <pool> <api_user> <api_password> [<trusted_ip_list>] [<placement>] [--unmanaged] [--dry-run] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--no-overwrite]        # 扩展iSCSI服务
orch apply mds <fs_name> [<placement>] [--dry-run] [--unmanaged] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--no-overwrite]               # 更新指定文件系统（fs_name）的MDS实例数量
orch apply nfs <svc_id> [<placement>] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [<port:int>] [--dry-run] [--unmanaged] [--no-overwrite]     # 扩展NFS服务
orch apply osd [--all-available-devices] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--unmanaged] [--dry-run] [--no-overwrite]             # 在所有可用设备上创建OSD守护进程
orch apply rgw <svc_id> [<placement>] [<realm>] [<zone>] [<port:int>] [--ssl] [--dry-run] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--unmanaged] [--no-overwrite]                                                  # 更新指定区域（zone）的RGW实例数量
orch apply snmp-gateway V2c|V3 <destination> [<port:int>] [<engine_id>] [MD5|SHA] [DES|AES] [<placement>] [--unmanaged] [--dry-run] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--no-overwrite]                      # 添加Prometheus到SNMP网关服务（仅适用于cephadm）
orch cancel   # 取消正在进行的后台操作                                
orch client-keyring ls [--format {plain|json|json-pretty|yaml|xml-pretty|xml}]        # 列出在cephadm管理下的客户端密钥                                                                
orch client-keyring rm <entity>                                              # 从cephadm管理中删除客户端密钥
orch client-keyring set <entity> <placement> [<owner>] [<mode>]               # 在cephadm管理下添加或更新客户端密钥
orch daemon add [mon|mgr|rbd-mirror|cephfs-mirror|crash|alertmanager|grafana|node-exporter|prometheus|mds|rgw|nfs|iscsi|cephadm-exporter|snmp-gateway]    
[<placement>]                                                                # 添加守护进程
orch daemon add iscsi <pool> <api_user> <api_password> [<trusted_ip_list>] [<placement>]   # 启动iSCSI守护进程
orch daemon add mds <fs_name> [<placement>]                                   # 启动MDS守护进程
orch daemon add nfs <svc_id> [<placement>]                                   # 启动NFS守护进程
orch daemon add osd [<svc_arg>] [raw|lvm]                                     # 在指定主机和设备上创建OSD守护进程 (例如，ceph orch daemon add osd myhost:/dev/sdb)
orch daemon add rgw <svc_id> [<placement>] [<port:int>] [--ssl]               # 启动RGW守护进程
orch daemon redeploy <name> [<image>]                                         # 使用特定镜像重新部署一个守护进程
orch daemon rm <names>... [--force]                                          # 删除特定的守护进程
orch daemon start|stop|restart|reconfig <name>                                # 启动、停止、重启或重新配置特定守护进程
orch device ls [<hostname>...] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--refresh] [--wide]                                            # 列出主机上的设备
orch device zap <hostname> <path> [--force]                                   # 擦除设备，以便重新使用
orch host add <hostname> [<addr>] [<labels>...] [--maintenance]               # 添加一个主机
orch host drain <hostname> [--force]                                          # 将所有守护进程从主机上排除
orch host label add <hostname> <label>                                       # 添加主机标签
orch host label rm <hostname> <label> [--force]                              # 删除主机标签
orch host ls [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [<host_pattern>] [<label>] [<host_status>]                                          # 列出主机
orch host maintenance enter <hostname> [--force]                              # 准备主机进入维护状态，关闭并禁用所有Ceph守护进程 (仅适用于cephadm)
orch host maintenance exit <hostname>                                         # 将主机从维护状态中恢复，重启所有Ceph守护进程 (仅适用于cephadm)
orch host ok-to-stop <hostname>                                              # 检查指定主机是否可以安全停止，而不会减少可用性
orch host rescan <hostname> [--with-summary]                                  # 执行主机上的磁盘重新扫描
orch host rm <hostname> [--force] [--offline]                                 # 删除主机
orch host set-addr <hostname> <addr>                                          # 更新主机地址
orch ls [<service_type>] [<service_name>] [--export] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--refresh]                                # 列出已知的服务
orch osd rm <osd_id>... [--replace] [--force] [--zap]                         # 删除OSD守护进程
orch osd rm status [--format {plain|json|json-pretty|yaml|xml-pretty|xml}]    # 查看OSD删除操作的状态
orch osd rm stop <osd_id>...                                                  # 取消进行中的OSD删除操作
orch pause                                                                   # 暂停后台工作
orch ps [<hostname>] [<service_name>] [<daemon_type>] [<daemon_id>] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}] [--refresh]             # 列出已知的守护进程
orch resume                                                                  # 恢复后台工作（如果已暂停）
orch rm <service_name> [--force]                                             # 删除服务
orch set backend [<module_name>]                                             # 选择后台模块
orch start|stop|restart|redeploy|reconfig <service_name>                      # 启动、停止、重启、重新部署或重新配置整个服务（即所有守护进程）
orch status [--detail] [--format {plain|json|json-pretty|yaml|xml-pretty|xml}]                                                                        # 报告已配置的后台及其状态
orch upgrade check [<image>] [<ceph_version>]                                 # 检查服务版本与可用的目标容器之间的差异
orch upgrade ls [<image>] [--tags]                                           # 检查可以升级到的版本（或标签）
orch upgrade pause                                                           # 暂停正在进行的升级
orch upgrade resume                                                          # 恢复已暂停的升级
orch upgrade start [<image>] [<ceph_version>] [<daemon_types>] [<hosts>] [<services>] [<limit:int>]                                                   # 启动升级
orch upgrade status                                                          # 查看服务版本与可用和目标容器之间的差异
orch upgrade stop                                                            # 停止进行中的升级
```

# osd
```shell
osd blocked-by                                                                # 打印出哪些OSD正在阻塞它们的对等节点
osd blocklist [<range>] add|rm <addr> [<expire:float>]                        # 将<addr>添加到阻塞列表中（可选的指定<expire>，单位为秒）或从阻塞列表中移除<addr>
osd blocklist clear                                                           # 清空所有被阻塞的客户端
osd blocklist ls                                                              # 显示被阻塞的客户端
osd count-metadata <property>                                                 # 按元数据字段<property>统计OSD的数量
osd crush add <id|osd.id> <weight:float> <args>...                            # 添加或更新CRUSH映射中的位置和权重，<name>对应的权重为<weight>，位置为<args>
osd crush add-bucket <name> <type> [<args>...]                                # 将一个无父节点的CRUSH桶<name>（可能是root桶）添加到指定类型<type>，并可选指定位置<args>
osd crush class create <class>                                                # 创建CRUSH设备类<class>
osd crush class ls                                                            # 列出所有的CRUSH设备类
osd crush class ls-osd <class>                                                # 列出所有属于指定<class>类的OSD
osd crush class rename <srcname> <dstname>                                    # 将CRUSH设备类<srcname>重命名为<dstname>
osd crush class rm <class>                                                    # 删除CRUSH设备类<class>
osd crush create-or-move <id|osd.id> <weight:float> <args>...                 # 为<name>创建或移动现有的条目，权重为<weight>，位置为<args>
osd crush dump                                                                # 转储当前的CRUSH映射
osd crush get-device-class <ids>...                                           # 获取指定OSD的设备类<id> [<id>...]
osd crush get-tunable straw_calc_version                                      # 获取CRUSH的可调项<tunable>
osd crush link <name> <args>...                                               # 在指定位置<args>下链接现有条目<name>
osd crush ls <node>                                                           # 列出CRUSH树中某个节点下的所有项目
osd crush move <name> <args>...                                               # 将现有的条目<name>移动到指定位置<args>
osd crush rename-bucket <srcname> <dstname>                                   # 将CRUSH桶<srcname>重命名为<dstname>
osd crush reweight <name> <weight:float>                                      # 将<name>的权重修改为<weight>，更新CRUSH映射
osd crush reweight-all                                                        # 重新计算CRUSH树中所有项的权重，以确保它们的权重总和正确
osd crush reweight-subtree <name> <weight:float>                              # 修改位于<name>下的所有叶子节点的权重为<weight>，更新CRUSH映射
osd crush rm <name> [<ancestor>]                                              # 从CRUSH映射中删除<name>，可以选择指定<ancestor>，仅删除指定节点下的项
osd crush rm-device-class <ids>...                                            # 删除指定OSD的设备类<id> [<id>...]，也可以使用<all|any>删除所有设备类
osd crush rule create-erasure <name> [<profile>]                              # 创建用于擦除编码池的CRUSH规则<name>，可选指定<profile>（默认为default）
osd crush rule create-replicated <name> <root> <type> [<class>]               # 创建用于复制池的CRUSH规则<name>，以<root>为起点，跨类型为<type>的桶进行复制，使用设备类型<class>（如ssd或hdd）
osd crush rule create-simple <name> <root> <type> [firstn|indep]              # 创建简单的CRUSH规则<name>，以<root>为起点，跨类型为<type>的桶进行复制，使用<firstn|indep>的选择模式（默认为firstn；indep适用于擦除池）
osd crush rule dump [<name>]                                                  # 转储指定CRUSH规则<name>（默认所有规则）
osd crush rule ls                                                            # 列出所有CRUSH规则
osd crush rule ls-by-class <class>                                            # 列出所有引用指定<class>的CRUSH规则
osd crush rule rename <srcname> <dstname>                                     # 将CRUSH规则<srcname>重命名为<dstname>
osd crush rule rm <name>                                                      # 删除CRUSH规则<name>
osd crush set <id|osd.id> <weight:float> <args>...                            # 更新CRUSH映射中<name>的权重为<weight>，位置为<args>
osd crush set [<prior_version:int>]                                           # 设置从输入文件中获取的CRUSH映射
osd crush set-all-straw-buckets-to-straw2                                     # 将所有CRUSH中的当前草堆桶转换为使用strw2算法
osd crush set-device-class <class> <ids>...                                   # 将指定OSD的设备类设置为<class>，也可以使用<all|any>设置所有设备
osd crush set-tunable straw_calc_version <value:int>                          # 设置CRUSH可调项<tunable>的值为<int>
osd crush show-tunables                                                       # 显示当前的CRUSH可调项
osd crush swap-bucket <source> <dest> [--yes-i-really-mean-it]                # 交换源桶<source>和目标桶<dest>的内容（如果确认，使用--yes-i-really-mean-it）
osd crush tree [--show-shadow]                                                # 以树状视图展示CRUSH桶和项
osd crush tunables legacy|argonaut|bobtail|firefly|hammer|jewel|optimal|      # 设置CRUSH可调项值为指定的配置文件<profile>
default                                                                      
osd crush unlink <name> [<ancestor>]                                          # 从CRUSH映射中取消链接<name>，可以选择仅在<ancestor>节点下取消链接
osd crush weight-set create <pool> flat|positional                            # 创建一个指定池的权重集
osd crush weight-set create-compat                                            # 创建一个默认的向后兼容的权重集
osd crush weight-set dump                                                     # 显示权重集
osd crush weight-set ls                                                       # 列出所有权重集
osd crush weight-set reweight <pool> <item> <weight:float>...                 # 设置指定池中项（桶或OSD）的权重
osd crush weight-set reweight-compat <item> <weight:float>...                 # 设置向后兼容的权重集中的项（桶或OSD）的权重
osd crush weight-set rm <pool>                                                # 删除指定池的权重集
osd crush weight-set rm-compat                                                # 删除向后兼容的权重集
osd deep-scrub <who>                                                          # 在指定的 OSD 上启动深度擦除，或者使用 <all|any> 来深度擦除所有 OSD
osd destroy <id|osd.id> [--force] [--yes-i-really-mean-it]                    # 标记 OSD 为已销毁。保持 ID 不变（允许重用），但移除 cephx 密钥、配置密钥数据和锁箱密钥，导致数据永久不可读取。
osd df [plain|tree] [class|name] [<filter>]                                   # 显示 OSD 的使用情况
osd down <ids>... [--definitely-dead]                                         # 设置指定的 OSD(s) 为 down，或者使用 <any|all> 设置所有 OSD 为 down
osd dump [<epoch:int>]                                                        # 打印 OSD 映射的摘要
osd erasure-code-profile get <name>                                           # 获取指定名称的擦除码配置文件
osd erasure-code-profile ls                                                   # 列出所有擦除码配置文件
osd erasure-code-profile rm <name>                                            # 删除指定名称的擦除码配置文件
osd erasure-code-profile set <name> [<profile>...] [--force]                  # 创建指定名称的擦除码配置文件，使用 [<key[=value]> ...] 键值对。添加 --force 强制覆盖现有的配置文件（非常危险）
osd find <id|osd.id>                                                          # 在 CRUSH 映射中查找指定的 OSD 并显示其位置
osd force-create-pg <pgid> [--yes-i-really-mean-it]                           # 强制创建指定的 PG（pgid）
osd force_healthy_stretch_mode [--yes-i-really-mean-it]                       # 强制健康伸展模式，要求所有 CRUSH 桶完全对等并允许所有非破坏性监视器当选为领导
osd force_recovery_stretch_mode [--yes-i-really-mean-it]                      # 强制恢复伸展模式，在当前池降级并且所有监视器桶都已上线时，增加池的大小到其非故障值
osd get-require-min-compat-client                                             # 获取我们将维护兼容性的最低客户端版本
osd getcrushmap [<epoch:int>]                                                 # 获取 CRUSH 映射
osd getmap [<epoch:int>]                                                      # 获取 OSD 映射
osd getmaxosd                                                                 # 显示最大 OSD id
osd in <ids>...                                                               # 设置指定的 OSD(s) 为 in，或者使用 <any|all> 自动将所有之前为 out 的 OSD 设置为 in
osd info [<id|osd.id>]                                                        # 打印指定 OSD {id} 的信息（而非所有 OSD）
osd last-stat-seq <id|osd.id>                                                 # 获取该 OSD 上报告的最后一次 PG 状态序列号
osd lost <id|osd.id> [--yes-i-really-mean-it]                                 # 将指定的 OSD 标记为永久丢失。如果没有更多的副本存在，数据将被销毁，请小心使用
osd ls [<epoch:int>]                                                          # 显示所有 OSD 的 ID
osd ls-tree [<epoch:int>] <name>                                              # 显示 CRUSH 映射中指定桶 <name> 下的所有 OSD IDs
osd map <pool> <object> [<nspace>]                                            # 查找指定池中的对象的 PG，使用 [namespace]
osd metadata [<id|osd.id>]                                                    # 获取指定 OSD {id} 的元数据（默认为所有 OSD）
osd new <uuid> [<id|osd.id>]                                                  # 创建一个新的 OSD。如果提供了 id，则需要替换的 OSD 必须已经存在且之前被销毁。通过 -i <file> 从 JSON 文件中读取秘密
osd numa-status                                                               # 显示 OSD 的 NUMA 状态
osd ok-to-stop <ids>... [<max:int>]                                           # 检查是否可以安全停止指定的 OSD(s)，而不降低即时数据可用性
osd out <ids>...                                                              # 设置指定的 OSD(s) 为 out，或者使用 <any|all> 设置所有 OSD 为 out
osd pause                                                                     # 暂停 OSD
osd perf                                                                      # 打印 OSD 性能摘要统计的输出
osd pg-temp <pgid> [<id|osd.id>...]                                           # 设置 pg_temp 映射 pgid:[<id> [<id>...]]（仅供开发者使用）
osd pg-upmap <pgid> <id|osd.id>...                                            # 设置 pg_upmap 映射 <pgid>:[<id> [<id>...]]（仅供开发者使用）
osd pg-upmap-items <pgid> <id|osd.id>...                                      # 设置 pg_upmap_items 映射 <pgid>:{<id> 到 <id>, [...]}（仅供开发者使用）
osd pool application disable <pool> <app> [--yes-i-really-mean-it]            # 禁用池 <poolname> 上的应用 <app>
osd pool application enable <pool> <app> [--yes-i-really-mean-it]             # 启用池 <poolname> 上的应用 <app> [cephfs,rbd,rgw]
osd pool application get [<pool>] [<app>] [<key>]                             # 获取池 <poolname> 上应用 <app> 的键 <key> 的值
osd pool application rm <pool> <app> <key>                                    # 移除池 <poolname> 上应用 <app> 的元数据键 <key>
osd pool application set <pool> <app> <key> <value>                           # 设置池 <poolname> 上应用 <app> 的元数据键 <key> 为值 <value>
osd pool autoscale-status [<format>]                                          # 获取池的 PG 数量大小调整建议和意图
osd pool cancel-force-backfill <who>...                                       # 恢复指定池 <who> 的正常恢复优先级
osd pool cancel-force-recovery <who>...                                       # 恢复指定池 <who> 的正常恢复优先级
osd pool create <pool> [<pg_num:int>] [<pgp_num:int>] [replicated|erasure]    # 创建池
[<erasure_code_profile>] [<rule>] [<expected_num_objects:int>] [<size:int>]  
[<pg_num_min:int>] [<pg_num_max:int>] [on|off|warn] [--bulk] [<target_size_  
bytes:int>] [<target_size_ratio:float>]                                       # 创建池时指定其他配置
osd pool deep-scrub <who>...                                                  # 对池 <who> 发起深度检查
osd pool force-backfill <who>...                                              # 强制对指定池 <who> 进行回填操作
osd pool force-recovery <who>...                                              # 强制对指定池 <who> 进行恢复操作
osd pool get <pool> size|min_size|pg_num|pgp_num|crush_rule|hashpspool|       # 获取池的参数 <var>
nodelete|nopgchange|nosizechange|write_fadvise_dontneed|noscrub|nodeep-      
scrub|hit_set_type|hit_set_period|hit_set_count|hit_set_fpp|use_gmt_hitset|  
target_max_objects|target_max_bytes|cache_target_dirty_ratio|cache_target_   
dirty_high_ratio|cache_target_full_ratio|cache_min_flush_age|cache_min_      
evict_age|erasure_code_profile|min_read_recency_for_promote|all|min_write_   
recency_for_promote|fast_read|hit_set_grade_decay_rate|hit_set_search_last_  
n|scrub_min_interval|scrub_max_interval|deep_scrub_interval|recovery_        
priority|recovery_op_priority|scrub_priority|compression_mode|compression_   
algorithm|compression_required_ratio|compression_max_blob_size|compression_  
min_blob_size|csum_type|csum_min_block|csum_max_block|allow_ec_overwrites|   
fingerprint_algorithm|pg_autoscale_mode|pg_autoscale_bias|pg_num_min|pg_num_ 
max|target_size_bytes|target_size_ratio|dedup_tier|dedup_chunk_algorithm|    
dedup_cdc_chunk_size|bulk                                                     # 获取池的各种参数
osd pool get noautoscale                                                      # 获取 noautoscale 标志，查看所有池的自动扩展设置
osd pool get-quota <pool>                                                     # 获取池的对象或字节限制
osd pool ls [detail]                                                          # 列出池
osd pool mksnap <pool> <snap>                                                 # 在池 <pool> 中创建快照 <snap>
osd pool rename <srcpool> <destpool>                                          # 将池 <srcpool> 重命名为 <destpool>
osd pool repair <who>...                                                      # 对池 <who> 发起修复操作
osd pool rm <pool> [<pool2>] [--yes-i-really-really-mean-it] [--yes-i-really- # 删除池 <poolname>
really-mean-it-not-faking]                                                   
osd pool rmsnap <pool> <snap>                                                 # 从池 <pool> 中删除快照 <snap>
osd pool scrub <who>...                                                       # 对池 <who> 发起检查操作
osd pool set <pool> size|min_size|pg_num|pgp_num|pgp_num_actual|crush_rule|   # 设置池的参数 <var> 为值 <val>
hashpspool|nodelete|nopgchange|nosizechange|write_fadvise_dontneed|noscrub|  
nodeep-scrub|hit_set_type|hit_set_period|hit_set_count|hit_set_fpp|use_gmt_  
hitset|target_max_bytes|target_max_objects|cache_target_dirty_ratio|cache_   
target_dirty_high_ratio|cache_target_full_ratio|cache_min_flush_age|cache_   
min_evict_age|min_read_recency_for_promote|min_write_recency_for_promote|    
fast_read|hit_set_grade_decay_rate|hit_set_search_last_n|scrub_min_interval| 
scrub_max_interval|deep_scrub_interval|recovery_priority|recovery_op_        
priority|scrub_priority|compression_mode|compression_algorithm|compression_  
required_ratio|compression_max_blob_size|compression_min_blob_size|csum_     
type|csum_min_block|csum_max_block|allow_ec_overwrites|fingerprint_          
algorithm|pg_autoscale_mode|pg_autoscale_bias|pg_num_min|pg_num_max|target_  
size_bytes|target_size_ratio|dedup_tier|dedup_chunk_algorithm|dedup_cdc_     
chunk_size|bulk <val> [--yes-i-really-mean-it]                                # 设置池的各种参数 <var> 为值 <val>
osd pool set noautoscale                                                      # 设置所有池（包括未来创建的池）的 noautoscale 标志，并完成所有正在进行的 PG 自动扩展进程
osd pool set-quota <pool> max_objects|max_bytes <val>                         # 设置池的对象或字节限制
osd pool stats [<pool_name>]                                                  # 获取所有池或指定池的统计信息
osd pool unset noautoscale                                                    # 取消 noautoscale 标志，使所有池启用自动缩放（包括未来创建的池）
osd primary-affinity <id|osd.id> <weight:float>                               # 调整 OSD 主亲和力，范围是 0.0 <= <weight> <= 1.0
osd primary-temp <pgid> <id|osd.id>                                           # 设置 primary_temp 映射 pgid:<id>|-1（仅限开发者）
osd purge <id|osd.id> [--force] [--yes-i-really-mean-it]                      # 从监视器中清除所有 OSD 数据，包括 OSD id 和 CRUSH 位置
osd purge-new <id|osd.id> [--yes-i-really-mean-it]                            # 清除部分创建但从未启动的 OSD 所有痕迹
osd repair <who>                                                              # 对指定的 OSD <who> 启动修复，或者使用 <all|any> 修复所有 OSD
osd require-osd-release luminous|mimic|nautilus|octopus|pacific [--yes-i-     # 设置参与集群的 OSD 最低版本要求
really-mean-it]                                                              
osd reweight <id|osd.id> <weight:float>                                       # 对 OSD 进行重新加权，0.0 < <weight> < 1.0
osd reweight-by-pg [<oload:int>] [<max_change:float>] [<max_osds:int>]        # 根据 PG 分布重新加权 OSD [超载百分比，默认 120]
[<pools>...]                                                                  
osd reweight-by-utilization [<oload:int>] [<max_change:float>] [<max_osds:int>] # 根据利用率重新加权 OSD [超载百分比，默认 120]
[--no-increasing]                                                           
osd reweightn <weights>                                                       # 使用 {<id>: <weight>,...} 对 OSD 重新加权
osd rm-pg-upmap <pgid>                                                        # 清除 pg_upmap 映射（仅限开发者）
osd rm-pg-upmap-items <pgid>                                                  # 清除 pg_upmap_items 映射（仅限开发者）
osd safe-to-destroy <ids>...                                                  # 检查是否可以安全销毁 OSD(s)，不会减少数据持久性
osd scrub <who>                                                               # 对指定的 OSD <who> 启动清理，或者使用 <all|any> 清理所有 OSD
osd set full|pause|noup|nodown|noout|noin|nobackfill|norebalance|norecover|   # 设置 <key>
noscrub|nodeep-scrub|notieragent|nosnaptrim|pglog_hardlimit [--yes-i-really- 
mean-it]                                                                     
osd set-backfillfull-ratio <ratio:float>                                      # 设置 OSD 被标记为过满，无法回填的使用比例
osd set-full-ratio <ratio:float>                                              # 设置 OSD 被标记为已满的使用比例
osd set-group <flags> <who>...                                                # 设置批量 OSD 或 CRUSH 节点的 <flags>，<flags> 必须是 {noup,nodown,noin,noout} 的逗号分隔子集
osd set-nearfull-ratio <ratio:float>                                          # 设置 OSD 被标记为接近满的使用比例
osd set-require-min-compat-client <version> [--yes-i-really-mean-it]          # 设置我们将保持兼容性的最小客户端版本
osd setcrushmap [<prior_version:int>]                                         # 从输入文件设置 CRUSH 映射
osd setmaxosd <newmax:int>                                                    # 设置新的最大 OSD 数量
osd stat                                                                      # 打印 OSD 映射的摘要信息
osd status [<bucket>]                                                         # 显示桶内或所有 OSD 的状态
osd stop <ids>...                                                             # 停止对应的 OSD 守护进程，并将其标记为不可用
osd test-reweight-by-pg [<oload:int>] [<max_change:float>] [<max_osds:int>] [<pools>...]   # 重新加权 OSD 的 PG 分布的干运行 [超载百分比，默认 120]
osd test-reweight-by-utilization [<oload:int>] [<max_change:float>] [<max_osds:int>] [--no-increasing]    # 重新加权 OSD 的利用率的干运行 [超载百分比，默认 120]
osd tier add <pool> <tierpool> [--force-nonempty]                             # 将 tier <tierpool>（第二个）添加到基本池 <pool>（第一个）
osd tier add-cache <pool> <tierpool> <size:int>                               # 向现有池 <pool>（第一个）添加大小为 <size> 的缓存池 <tierpool>（第二个）
osd tier cache-mode <pool> writeback|readproxy|readonly|none [--yes-i-really- # 为缓存池 <pool> 指定缓存模式
mean-it]                                                                     
osd tier rm <pool> <tierpool>                                                 # 从基本池 <pool>（第一个）中删除缓存池 <tierpool>（第二个）
osd tier rm-overlay <pool>                                                    # 删除基本池 <pool> 的覆盖池
osd tier set-overlay <pool> <overlaypool>                                     # 将基本池 <pool> 的覆盖池设置为 <overlaypool>
osd tree [<epoch:int>] [up|down|in|out|destroyed...]                          # 打印 OSD 树
osd tree-from [<epoch:int>] <bucket> [up|down|in|out|destroyed...]            # 打印桶内的 OSD 树
osd unpause                                                                   # 解除暂停 OSD
osd unset full|pause|noup|nodown|noout|noin|nobackfill|norebalance|norecover| unset <key> noscrub|nodeep-scrub|notieragent|nosnaptrim                                  
osd unset-group <flags> <who>...                                              # 取消批量 OSD 或 CRUSH 节点的 <flags>，<flags> 必须是 {noup,nodown,noin,noout} 的逗号分隔子集
osd utilization                                                               # 获取基本的 PG 分布统计信息
osd versions                                                                  # 检查正在运行的 OSD 版本
```

# pg
```shell
pg cancel-force-backfill <pgid>...                                            # 恢复<pgid>的正常回填优先级
pg cancel-force-recovery <pgid>...                                            # 恢复<pgid>的正常恢复优先级
pg debug unfound_objects_exist|degraded_pgs_exist                             # 显示关于PG的调试信息
pg deep-scrub <pgid>                                                          # 启动<pgid>的深度清理
pg dump [all|summary|sum||pools|osds|pgs|pgs_brief...]                   # 显示PG映射的可读版本（仅‘all’适用于纯文本）
pg dump_json [all|summary|sum|pools|osds|pgs...]                              # 仅以JSON格式显示PG映射的可读版本
pg dump_pools_json                                                            # 仅以JSON格式显示PG池信息
pg dump_stuck [inactive|unclean|stale|undersized|degraded...] [<threshold:    # 显示卡住的PG信息
int>]                                                                        
pg force-backfill <pgid>...                                                   # 强制先回填<pgid>
pg force-recovery <pgid>...                                                   # 强制先恢复<pgid>
pg getmap                                                                     # 获取二进制PG映射到 -o/stdout
pg ls [<pool:int>] [<states>...]                                              # 列出具有特定池、OSD、状态的PG
pg ls-by-osd <id|osd.id> [<pool:int>] [<states>...]                           # 列出指定OSD的PG
pg ls-by-pool <poolstr> [<states>...]                                         # 列出指定池的PG
pg ls-by-primary <id|osd.id> [<pool:int>] [<states>...]                       # 列出指定主OSD的PG
pg map <pgid>                                                                 # 显示PG到OSD的映射
pg repair <pgid>                                                              # 启动<pgid>的修复
pg repeer <pgid>                                                              # 强制PG重新对等
pg scrub <pgid>                                                               # 启动<pgid>的清理
pg stat                                                                       # 显示PG状态
```

# progress
```shell
progress  # 显示恢复操作的进度
progress clear  # 重置进度跟踪
progress json  # 显示机器可读的进度信息
progress off  # 禁用进度跟踪
progress on  # 启用进度跟踪
```

# rbd
```shell
rbd mirror snapshot schedule add <level_spec> <interval> [<start_time>]       # 添加rbd镜像快照调度
rbd mirror snapshot schedule list [<level_spec>]                              # 列出rbd镜像快照调度
rbd mirror snapshot schedule remove <level_spec> [<interval>] [<start_time>]  # 删除rbd镜像快照调度
rbd mirror snapshot schedule status [<level_spec>]                            # 显示rbd镜像快照调度状态
rbd perf image counters [<pool_spec>] [write_ops|write_bytes|write_latency|   # 获取当前RBD IO性能计数
read_ops|read_bytes|read_latency]                                            
rbd perf image stats [<pool_spec>] [write_ops|write_bytes|write_latency|read_ # 获取当前RBD IO性能统计
ops|read_bytes|read_latency]                                                 
rbd task add flatten <image_spec>                                             # 异步在后台扁平化克隆镜像
rbd task add migration abort <image_spec>                                     # 异步在后台中止已准备的迁移
rbd task add migration commit <image_spec>                                    # 异步在后台提交已执行的迁移
rbd task add migration execute <image_spec>                                   # 异步在后台执行镜像迁移
rbd task add remove <image_spec>                                              # 异步在后台删除镜像
rbd task add trash remove <image_id_spec>                                     # 异步在后台从回收站删除镜像
rbd task cancel <task_id>                                                     # 取消挂起或正在运行的异步任务
rbd task list [<task_id>]                                                     # 列出挂起或正在运行的异步任务
rbd trash purge schedule add <level_spec> <interval> [<start_time>]           # 添加rbd回收站清除调度
rbd trash purge schedule list [<level_spec>]                                  # 列出rbd回收站清除调度
rbd trash purge schedule remove <level_spec> [<interval>] [<start_time>]      # 删除rbd回收站清除调度
rbd trash purge schedule status [<level_spec>]                                # 显示rbd回收站清除调度状态
```

# restful
```shell
restful create-key <key_name>  # 创建一个具有此名称的API密钥
restful create-self-signed-cert  # 创建本地化的自签名证书
restful delete-key <key_name>  # 删除具有此名称的API密钥
restful list-keys  # 列出所有API密钥
restful restart  # 重启API服务器
```


# zabbix
```shell
zabbix config-set <key> <value>  # 设置配置值
zabbix config-show               # 显示当前配置
zabbix discovery                 # 发现Zabbix数据
zabbix send                      # 强制发送数据到Zabbix
```


