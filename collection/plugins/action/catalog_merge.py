# Copyright 2022 James Harmison <jharmison@redhat.com>

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleActionFail
from ansible.module_utils.parsing.convert_bool import boolean
from ansible.plugins.action import ActionBase


class ActionModule(ActionBase):
    '''Merge OLM Operator Catalog entries, setting facts'''

    TRANSFERS_FILES = False

    def run(self, tmp=None, task_vars=None):
        if task_vars is None:
            task_vars = dict()

        result = super(ActionModule, self).run(tmp, task_vars)
        del tmp  # tmp no longer has any effect

        facts = dict()
        cacheable = boolean(self._task.args.pop('cacheable', False))

        operator_catalogs = list(self._task.args.pop('operator_catalogs', []))

        catalog = str(self._task.args.pop('catalog', 'registry.redhat.io/redhat/redhat-operator-index:v4.9'))
        full = boolean(self._task.args.pop('full', True))
        packages = list(self._task.args.pop('packages', []))

        if self._task.args:
            raise AnsibleActionFail(f'Unknown args provided for catalog merging: {self._task.args}')

        added = False
        for operator_catalog in operator_catalogs:
            if operator_catalog.get('catalog') == catalog:
                if boolean(operator_catalog.get('full')) != full:
                    raise AnsibleActionFail('Unable to merge two catalog specs with different full specifications')
                operator_catalog.get('packages').extend(packages)
                added = True
                break
        if not added:
            operator_catalogs.append({
                'catalog': catalog,
                'full': full,
                'packages': packages,
            })

        facts['operator_catalogs'] = operator_catalogs

        if facts:
            result['ansible_facts'] = facts
            result['_ansible_facts_cacheable'] = cacheable

        return result
