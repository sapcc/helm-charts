import threading
import sys
import os
import urllib3

from neutron import server
from neutron.common import config
from neutron.common import profiler
from oslo_config import cfg

application = None
app_lock = threading.Lock()

with app_lock:
    if application is None:
        if os.environ.get('PYTHONWARNINGS') == 'ignore:Unverified HTTPS request':
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

        conf_files = server._get_config_files()

        print(os.environ)

        config.init([], default_config_files=conf_files)
        config.setup_logging()
        config.set_config_defaults()
        if not cfg.CONF.config_file:
            sys.exit(_("ERROR: Unable to find configuration file via the default"
                       " search paths (~/.neutron/, ~/, /etc/neutron/, /etc/) and"
                       " the '--config-file' option!"))

        profiler.setup('neutron-server', cfg.CONF.host)
        application = config.load_paste_app('neutron')