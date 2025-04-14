# config.py
import os



# 配置追加
SEARCH_CONFIG_PATCH = f'''
# 允许从接口自动创建索引/数据集名
action.auto_create_index: \\*

# 设置数据存储目录
path.data: "{os.getenv('SEARCH_DATA_DIR').replace(os.sep, "/")}"

# 全局网络地址绑定
#network.host: 0.0.0.0

# 集群通信地址绑定,不配置则使用network.host
#transport.host: 0.0.0.0
'''
KIBANA_CONFIG_PATCH = f'''
# 设置数据存储目录
path.data: {os.getenv('KIBANA_DATA_DIR').replace(os.sep, "/")}

# 网页服务地址
# server.host: 0.0.0.0
server.publicBaseUrl: "http://192.168.1.11:5601"
'''
LOGSTASH_CONFIG_PATCH = f'''
# 设置数据存储目录
path.data: "{os.getenv('LOGSTASH_DATA_DIR').replace(os.sep, "/")}"
# 自动热重载配置
config.reload.automatic: true
'''





# logstash pipeline
LOGSTASH_PIPELINE_YAML_PATCH = f'''
# 新增 syslog pipeline, logstash pipeline yaml 在windows中不支持/ 路径，需要\\\\
- pipeline.id: syslog_514
  path.config: "{os.getenv('LOGSTASH_PIPELINE_CONF_DIR').replace(os.sep, "\\\\")}\\\\syslog.514.conf"
'''
LOGSTASH_PIPELINE_CONIF_VAR = {
    'es_host': f"{os.getenv('ELASTICSEARCH_HOST')}",
    'es_user': f"{os.getenv('ELASTICSEARCH_USER')}",
    'es_password': f"{os.getenv('ELASTICSEARCH_PASS')}",
    'ca_cert_path': f"{os.getenv('ELASTICSEARCH_HTTP_CA_CRT').replace(os.sep, "/")}"
}





# 脚本会在源代码中查找 SRC_LINE 的行与其适配结尾}的行直接的内容, 然后使用 BLOCK 代码块替换之
LEARNED_1_BLOCK = '''    public static boolean verifyLicense(final License license, PublicKey publicKey) {
        return true;
    }'''
LEARNED_1_SRC_LINE = LEARNED_1_BLOCK.splitlines()[0]
LEARNED_2_BLOCK = '''    public static boolean verifyLicense(final License license) {
        return true;
    }'''
LEARNED_2_SRC_LINE = LEARNED_2_BLOCK.splitlines()[0]
LEARNED_3_BLOCK = '''    static {
        final String shortHash;
        final String date;
        Path path = getElasticsearchCodebase();
        shortHash = "Unknown";
        date = "Unknown";
        CURRENT = new XPackBuild(shortHash, date);
    }'''
LEARNED_3_SRC_LINE = LEARNED_3_BLOCK.splitlines()[0]


