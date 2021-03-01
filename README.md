# rke2-azure-tf

__Warning:__ This module is still a work in progress and we are actively collecting feedback, it is __not__ recommended for any production workloads just yet.

`rke2` is lightweight, easy to use, and has minimal dependencies.  As such, there is a tremendous amount of flexibility for deployments that can be tailored to best suit you and your organization's needs.

This repository is inteded to clearly demonstrate one method of deploying `rke2` in a highly available, resilient, scalable, and simple method on Azure. It is by no means the only supported soluiton for running `rke2` on Azure.

We highly recommend you use the modules in this repository as stepping stones in solutions that meet the needs of your workflow and organization.  If you have suggestions or areas of improvements, we would [love to hear them](https://slack.rancher.io/)!

## TODO

This module is functionally complete, meaning it successfully bootstraps a (HA) rke2 cluster on Azure with _n_ optional nodepools, however, it is still __very__ rough around the edges and in general needs some tlc in the following:

* expand, clean up, and review terraform input/outputs
* ensure `depends_on` where appropriate (module does not `destroy` properly all the time)
* bootstrapping architecture review to make sure it meets Azure standards
* validate on azure gov
* pair down permissions to least privileged
