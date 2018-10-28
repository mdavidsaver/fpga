#!/usr/bin/env python

import logging
import sys
import os
import shutil
import subprocess as SP

_log = logging.getLogger(__name__)

BASEDIR=os.path.expandvars('$HOME')

def createdir(*parts):
    name = os.path.join(BASEDIR, *parts)
    try:
        os.makedirs(name)
    except os.error:
        pass # may already exist
    return name

def check_call(*args, **kws):
    if 'shell' not in kws:
        kws['shell']=True
    _log.debug('check_call(%s, %s)', args, kws)
    SP.check_call(*args, **kws)

def check_output(*args, **kws):
    if 'shell' not in kws:
        kws['shell']=True
    ret = SP.check_output(*args, **kws)
    _log.debug('check_output(%s, %s) -> %s', args, kws, ret)
    return ret

class Package(object):
    def __init__(self, name, url):
        self.name, self.url = name, url
        self.cached = False # assume cache miss until proven otherwise

    def prepare(self):
        scratch = createdir('.deps')
        check_call('git clone --depth=5 %s %s'%(self.url, self.name), cwd=scratch)
        gitdir = self.srcdir = os.path.join(scratch, self.name)

        HEAD = self.HEAD = check_output('git log -n1 --pretty=format:%H', cwd=gitdir).strip()
        # TODO: further mangle cache_key based on build environment

        self.cache_key = HEAD

        _log.info('%s at %s', self.name, HEAD)

        cachedir = createdir('.cache')
        self.cachedir = os.path.join(cachedir, self.name+'-key')
        keyfile = self.keyfile = os.path.join(cachedir, self.name+'-key')

        if os.path.exists(keyfile):
            with open(keyfile, 'r') as F:
                old_key = F.read().strip()

            _log.info('%s cache at %s', self.name, old_key)

            self.cached = self.cache_key==old_key
            _log.info('%s cache %s', self.name, 'HIT' if self.cached else 'MISS')

        self.cachedir = os.path.join(cachedir, self.name)

        if not self.cached:
            _log.debug('remove %s', self.cachedir)
            shutil.rmtree(self.cachedir, ignore_errors=True) # may not exist

    def save(self):
        with open(self.keyfile, 'w') as F:
            F.write(self.cache_key)

if __name__=='__main__':
    logging.basicConfig(level=logging.DEBUG)

    iverilog = Package('iverilog', 'https://github.com/steveicarus/iverilog.git')
    yosys = Package('yosys', 'https://github.com/cliffordwolf/yosys.git')
    icestorm = Package('icestorm', 'https://github.com/cliffordwolf/icestorm.git')
    arachne = Package('arachne-pnr', 'https://github.com/cseed/arachne-pnr.git')

    iverilog.prepare()
    yosys.prepare()
    icestorm.prepare()
    arachne.prepare()

    if iverilog.cached and yosys.cached and icestorm.cached and arachne.cached:
        sys.exit(0)

    prefix=os.path.join(BASEDIR, '.cache', 'usr')
    shutil.rmtree(prefix, ignore_errors=True)

    # iverilog

    check_call('sh autoconf.sh', cwd=iverilog.srcdir)
    check_call('./configure --prefix='+prefix, cwd=iverilog.srcdir)
    check_call('make -j2', cwd=iverilog.srcdir)
    check_call('make install', cwd=iverilog.srcdir)

    # yosys
    check_call('make config-gcc PREFIX='+prefix, cwd=yosys.srcdir)
    check_call('make -j2 PREFIX='+prefix, cwd=yosys.srcdir)
    check_call('make install PREFIX='+prefix, cwd=yosys.srcdir)

    # icestorm
    check_call('make -j2 PREFIX='+prefix, cwd=icestorm.srcdir)
    check_call('make install PREFIX='+prefix, cwd=icestorm.srcdir)

    # arachne
    check_call('make -j2 PREFIX='+prefix, cwd=arachne.srcdir)
    check_call('make install PREFIX='+prefix, cwd=arachne.srcdir)

    iverilog.save()
    yosys.save()
    icestorm.save()
    arachne.save()
