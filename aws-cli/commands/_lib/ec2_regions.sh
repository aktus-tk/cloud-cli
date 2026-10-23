#!/usr/bin/env bash
# Shared: EC2 enabled region names for the current account (read-only describe-regions).

aws_ec2_enabled_regions_list() {
  aws ec2 describe-regions \
    --query 'sort(Regions[].RegionName)' \
    --output text | tr '\t' '\n'
}
