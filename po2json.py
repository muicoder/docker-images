#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os


def po2json(po):
    json = po.replace('po', 'json').replace('for_use_stf_ui_', 'stf.')
    str = "pojson " + po + " > " + json
    os.system(str)


def j2json(j):
    if os.path.isfile(j):
        json = open(j).read()
        tmp = json.replace(' [null, ', '').replace('], ', ',').replace(']}', '}}').replace(' {*}, ', '{')
        head = '{"' + j.split('.')[1] + '":{"-":"Smartphone Test Farm"'
        data = head + tmp.split('"-":"-"')[1]
        open(j, 'w').write(data)


for po in os.listdir('.'):
    if os.path.isfile(po) and ".po" in po:
        if "for_use_stf_ui_" in po:
            po2json(po)
            p = po.replace('for_use_stf_ui_', 'stf.')
            os.rename(po, p)
            j = p.replace('po', 'json')
            j2json(j)
        else:
            print "No for_use_stf_ui_*.po file!"
