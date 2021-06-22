# rke2-azure-tf

__Warning:__ This module is still a work in progress and we are actively collecting feedback, it is __not__ recommended for any production workloads just yet.

`rke2` is lightweight, easy to use, and has minimal dependencies.  As such, there is a tremendous amount of flexibility for deployments that can be tailored to best suit you and your organization's needs.

This repository is inteded to clearly demonstrate one method of deploying `rke2` in a highly available, resilient, scalable, and simple method on Azure. It is by no means the only supported soluiton for running `rke2` on Azure.

We highly recommend you use the modules in this repository as stepping stones in solutions that meet the needs of your workflow and organization.  If you have suggestions or areas of improvements, we would [love to hear them](https://slack.rancher.io/)!


__WARNING:__ The leader election process is busted.  To get this module to work you must select 1 server and rerun `01_rke.sh` in `/var/lib/cloud/instances/$INSTANCE/scripts/01_rke2.sh` on subsequent server nodes to get them to join the cluster.

The `agents` module, however works just fine in joining the cluster once a master is present.

## TODO:

* Figure out missing inputs to get `upgrade_mode = "Automatic"` working.
