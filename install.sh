helm repo add phntom https://phntom.kix.co.il/charts/
helm repo update

kubectl create namespace chat
kubectl create namespace clusterwide
kubectl create namespace db
kubectl create namespace phantom
kubectl create namespace stocks

helm upgrade --install prometheus -n clusterwide prometheus-community/kube-prometheus-stack -f kube-prometheus-stack/values.d/limnad.yaml -f kube-prometheus-stack/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install nginx-ingress -n web ingress-nginx/ingress-nginx -f nginx-ingress/values.d/minthe.yaml -f nginx-ingress/values.d/minthe.secret.yaml --atomic --debug
helm upgrade --install certs -n clusterwide certs/certs -f certs/values.d/limnad.yaml -f certs/values.d/limnad.secret.yaml --atomic --debug

### from chartmuseum
helm upgrade --install chartmuseum -n web phntom/chartmuseum -f chartmuseum/values.d/limnad.yaml -f chartmuseum/values.d/limnad.secret.yaml --atomic --debug
### or directly from the folder
helm upgrade --install chartmuseum -n web chartmuseum -f chartmuseum/values.d/limnad.yaml -f chartmuseum/values.d/limnad.secret.yaml --atomic --debug
###

helm upgrade --install oauth2-proxy -n clusterwide phntom/oauth2-proxy -f oauth2-proxy/values.d/limnad.yaml -f oauth2-proxy/values.d/limnad.secret.yaml --atomic --debug

helm upgrade --install mattermost-prod -n chat mattermost -f mattermost/values.d/minthe.yaml -f mattermost/values.d/minthe.secret.yaml --atomic --debug
helm upgrade --install mattermost-integ -n chat phntom/mattermost -f mattermost/values.d/limnad-integ.yaml -f mattermost/values.d/limnad-integ.secret.yaml --atomic --debug
helm upgrade --install matterircd -n phantom phntom/matterircd --atomic --debug
helm upgrade --install website-web-nix -n chat phntom/website-web-nix --atomic --debug -f website-web-nix/values.d/limnad.secret.yaml
helm upgrade --install website-kix -n chat phntom/website-kix-co-il --atomic --debug

helm upgrade --install minio -n db bitnami/minio -f minio/values.d/limnad.yaml -f minio/values.d/limnad.secret.yaml --debug --atomic
helm upgrade --install docker -n db phntom/docker-registry -f docker-registry/values.d/limnad.yaml -f docker-registry/values.d/limnad.secret.yaml --debug --atomic

helm upgrade --install nasdaq -n stocks phntom/stocks-nasdaq-crawler -f stocks-nasdaq-crawler/values.d/limnad.secret.yaml

helm upgrade --install pwd-mindav -n phantom mindav -f mindav/values.d/limnad.secret.yaml --debug --atomic

###

helm upgrade --install postgresql -n db bitnami/postgresql -f postgresql/values.d/minthe.yaml -f postgresql/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install -n web hackmd stable/hackmd -f hackmd/values.d/minthe.yaml -f hackmd/values.d/minthe.secret.yaml --atomic --debug
helm upgrade --install kix -n phantom website-kix-co-il
helm upgrade --install binaryvision -n web website-binaryvision-static
helm upgrade --install tlo -n phantom website-bv-tlo
helm upgrade --install nix-mattermost -n phantom website-web-nix -f website-web-nix/values.yaml -f website-web-nix/values.d/limnad.secret.yaml
helm upgrade --install pgadmin4 -n db runix/pgadmin4 -f pgadmin4/values.d/limnad.yaml -f pgadmin4/values.d/limnad.secret.yaml
helm upgrade --install hass -n hass k8s-at-home/home-assistant -f home-assistant/values.d/limnad.yaml --atomic --debug

helm upgrade --install firefly-iii -n web phntom/firefly-iii -f firefly-iii/values.d/limnad.yaml -f  firefly-iii/values.d/limnad.secret.yaml --atomic --debug

