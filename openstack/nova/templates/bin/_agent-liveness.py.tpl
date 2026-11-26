#!/usr/bin/env python3
"""Keep Nova's service-status check and token cache with Keystone plugin auth."""

import contextlib
import logging
import shelve
import socket

from agentliveness.agent import Liveness
from keystoneauth1 import loading
from oslo_config import cfg


class NovaLiveness(Liveness):
    def _get_session(self):
        # The upstream implementation uses v3.Password directly. Load Nova's
        # application-credential plugin instead, including for token renewal.
        auth = loading.load_auth_from_conf_options(
            self.CONF, 'keystone_authtoken')
        session = loading.load_session_from_conf_options(
            self.CONF, 'keystone_authtoken', auth=auth)
        if self._persistent_storage is not None:
            auth.auth_ref = self._persistent_storage.get('auth_ref')
            self._persistent_storage['auth_ref'] = auth.get_access(session)
        return session


def main():
    logging.basicConfig(level=logging.WARNING)
    conf = cfg.ConfigOpts()
    conf.register_cli_opts([
        cfg.StrOpt('component', default='nova', choices=['nova']),
        cfg.StrOpt('token_cache_file'),
    ])
    conf.register_opt(cfg.StrOpt('host', default=socket.gethostname()))
    loading.register_auth_conf_options(conf, 'keystone_authtoken')
    loading.register_session_conf_options(conf, 'keystone_authtoken')
    conf(project='nova')

    storage = (shelve.open(conf.token_cache_file) if conf.token_cache_file
               else contextlib.nullcontext())
    with storage as persistent_storage:
        return NovaLiveness(conf, persistent_storage).check()


if __name__ == '__main__':
    raise SystemExit(main())
