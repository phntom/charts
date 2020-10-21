helm upgrade --install prometheus -n clusterwide prometheus-community/kube-prometheus-stack -f kube-prometheus-stack/values.d/limnad.yaml -f kube-prometheus-stack/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install oauth2-proxy -n clusterwide stable/oauth2-proxy -f oauth2-proxy/values.d/limnad.yaml -f oauth2-proxy/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install nginx-ingress -n clusterwide ingress-nginx/ingress-nginx -f nginx-ingress/values.d/limnad.yaml -f nginx-ingress/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install certs -n clusterwide certs/certs -f certs/values.d/limnad.yaml -f certs/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install postgresql -n db bitnami/postgresql -f postgresql/values.d/limnad.yaml -f postgresql/values.d/limnad.secret.yaml --atomic --debug
helm upgrade --install chat -n phantom mattermost/mattermost-team-edition -f mattermost/values.d/limnad.yaml --atomic --debug

helm upgrade --install nasdaq -n stocks stocks-nasdaq-crawler -f stocks-nasdaq-crawler/values.d/limnad.secret.yaml
helm upgrade --install kix -n phantom website-kix-co-il
helm upgrade --install binaryvision -n phantom website-binaryvision-static
helm upgrade --install tlo -n phantom website-bv-tlo

helm upgrade --install hass -n phantom k8s-at-home/home-assistant -f home-assistant/values.d/limnad.yaml --atomic --debug