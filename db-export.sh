#!/bin/bash

echo "Context information:";
kubectl config get-contexts
echo "";
read -p "Is this the correct cluster and namespace? (y/n) " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "";
    echo "Change the context with 'kubectl config use-context [context]' and start again."
    exit 1
fi
POD=$(kubectl get pods -o name --no-headers=true -o custom-columns=":metadata.name" | grep drupal-dpl | head -n 1)
DRUSH=$(kubectl exec -ti $POD -c drupal -- which drush | sed "s/\r/ /g")
kubectl exec -ti $POD -c drupal -- $DRUSH sql-dump | gzip > $POD.sql.gz
gunzip $POD.sql.gz
# Make sure, the mysqldump error is removed.
ex -s +"g/> mysqldump: Error: 'Access denied; you need (at least one of) the PROCESS privilege(s) for this operation' when trying to dump tablespaces/d" -cwq $POD.sql
echo "";
echo "The '$POD.sql' is now ready for import. Use 'lando ssh' and then:"
echo "drush sql-cli < $POD.sql"
