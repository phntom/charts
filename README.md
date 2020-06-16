# Helm Charts

This is my personal collection of Helm charts.

Most of which are forked from other sources, I'll try to list the origin in the ORIGIN.md file.

For more information about installing and using Helm, see the
[Helm Docs](https://helm.sh/docs/). For a quick introduction to Charts, see the [Chart Guide](https://helm.sh/docs/topics/charts/).

## Prerequisites

I test these charts with helm 3 on Kubernetes 1.6.

I use EKS, microkube, Linode and GCE, but don't always have the ability to test on all environments.

## How Do I Install These Charts?

Add the repository by running:

`helm repo add phntom https://github.com/phntom/charts/`
`helm repo update`

Install a chart by running:

`helm install <name> phntom/<chart>`

For more information on using Helm, refer to the [Helm documentation](https://github.com/kubernetes/helm#docs).

## Chart Format

Take a look at the [alpine example chart](https://github.com/helm/helm/tree/master/cmd/helm/testdata/testcharts/alpine) for reference when you're writing your first few charts.

Before contributing a Chart, become familiar with the format. Note that the project is still under active development and the format may still evolve a bit.
