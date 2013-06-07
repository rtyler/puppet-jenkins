#!/bin/bash
pulp-admin -u jenkins -p j3nk1n5 rpm repo uploads rpm --repo-id testing_${1} -d $WORKSPACE/build/rpm_root/RPMS/x86_64/
pulp-admin -u jenkins -p j3nk1n5 rpm repo publish run --repo-id testing_${1}
