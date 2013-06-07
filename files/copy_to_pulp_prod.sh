#!/bin/bash
pulp-admin -u jenkins -p j3nk1n5 rpm repo copy rpm --from-repo-id='testing_${1}' --to-repo-id='prod_${1}' --match="version=.*$PROMOTED_NUMBER"
pulp-admin -u jenkins -p j3nk1n5 rpm repo publish run --repo-id='prod_${1}'
