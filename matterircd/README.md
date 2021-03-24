# Mattermost IRCd Bridge

Provide nostalgia to your mattermost users

## TL;DR

* Download values.yaml - rename to values-integ.yaml (or anything you want)
* Edit the values to suit your needs
* Deploy with:

```shell
helm repo add phntom https://phntom.kix.co.il/charts/
helm repo update
helm install matterircd-integ phntom/matterircd -f values-integ.yaml 
```

