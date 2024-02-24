#!/bin/sh

cd `dirname $0`/..

RDstrictbarrier -q -f docker/deps.R
