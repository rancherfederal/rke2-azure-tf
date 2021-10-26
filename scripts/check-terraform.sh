#!/usr/bin/env bash
set -e

terraform init

TFFMT_COUNT=$(terraform fmt -write=false -recursive | wc -l)
if (( $TFFMT_COUNT > 0 )); then
  echo -e "\n*** ERROR! the following files require re-formatting"
  terraform fmt -recursive -check
fi

terraform validate
